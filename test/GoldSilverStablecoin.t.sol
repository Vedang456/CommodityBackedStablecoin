// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/GoldSilverStablecoin.sol";
import "../src/mocks/MockV3Aggregator.sol";


contract GoldSilverStablecoinTest is Test {
    GoldSilverStablecoin stablecoin;
    MockV3Aggregator goldPriceFeed;
    MockV3Aggregator silverPriceFeed;

    address user1 = address(0x1);
    address user2 = address(0x2);

    // Example prices (Chainlink price feeds have 8 decimals)
    uint256 constant GOLD_PRICE = 2000 * 1e8;   // e.g., $2000
    uint256 constant SILVER_PRICE = 25 * 1e8;     // e.g., $25

    function setUp() public {
        // Deploy mock price feeds
        goldPriceFeed = new MockV3Aggregator(8, int256(GOLD_PRICE));
        silverPriceFeed = new MockV3Aggregator(8, int256(SILVER_PRICE));

        // Deploy the stablecoin contract with the mock price feed addresses
        stablecoin = new GoldSilverStablecoin(
            address(goldPriceFeed),
            address(silverPriceFeed)
        );
    }

    /// @notice Test depositCollateralAndMint (which deposits collateral and mints tokens)
    function testDepositCollateralAndMint() public {
        uint256 depositAmount = 10e18;
        uint256 mintAmount = 5e18;

        vm.prank(user1);
        stablecoin.depositCollateralAndMint("GOLD", depositAmount, mintAmount);

        // Check that the collateral deposit is recorded.
        uint256 depositedCollateral = stablecoin.getCollateralBalance(user1, "GOLD");
        assertEq(depositedCollateral, depositAmount);

        // Check that tokens were minted.
        uint256 tokenBalance = stablecoin.balanceOf(user1);
        assertEq(tokenBalance, mintAmount);
    }

    /// @notice Test that depositing zero collateral reverts.
    function testDepositCollateralZero() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("NeedsMoreThanZero()"));
        stablecoin.depositCollateral("GOLD", 0);
    }

    /// @notice Test that minting zero tokens reverts.
    function testMintTokenZero() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("NeedsMoreThanZero()"));
        stablecoin.mintToken(0);
    }

    /// @notice Test burning tokens.
    function testBurnToken() public {
        uint256 depositAmount = 10e18;
        uint256 mintAmount = 5e18;

        // user1 deposits collateral and mints tokens.
        vm.prank(user1);
        stablecoin.depositCollateralAndMint("GOLD", depositAmount, mintAmount);

        // user1 burns 1e18 tokens.
        vm.prank(user1);
        stablecoin.burnToken(1e18);

        uint256 tokenBalance = stablecoin.balanceOf(user1);
        assertEq(tokenBalance, 4e18);
    }

    /// @notice Test redeeming collateral.
    function testRedeemCollateral() public {
        uint256 depositAmount = 10e18;
        uint256 mintAmount = 5e18;

        vm.prank(user1);
        stablecoin.depositCollateralAndMint("GOLD", depositAmount, mintAmount);

        // Redeem 2e18 collateral.
        vm.prank(user1);
        stablecoin.redeemCollateral("GOLD", 2e18);

        uint256 remainingCollateral = stablecoin.getCollateralBalance(user1, "GOLD");
        assertEq(remainingCollateral, 8e18);
    }

    /// @notice Test redeemCollateralForToken (which burns tokens and then redeems collateral).
    function testRedeemCollateralForToken() public {
        uint256 depositAmount = 10e18;
        uint256 mintAmount = 5e18;

        vm.prank(user1);
        stablecoin.depositCollateralAndMint("GOLD", depositAmount, mintAmount);

        // Redeem collateral by burning 1e18 tokens and redeeming 2e18 collateral.
        vm.prank(user1);
        stablecoin.redeemCollateralForToken("GOLD", 2e18, 1e18);

        uint256 tokenBalance = stablecoin.balanceOf(user1);
        // Minted 5e18 and burned 1e18.
        assertEq(tokenBalance, 4e18);

        uint256 remainingCollateral = stablecoin.getCollateralBalance(user1, "GOLD");
        assertEq(remainingCollateral, 8e18);
    }

    /// @notice Test getLatestPrice for GOLD.
    function testGetLatestPriceGold() public {
        uint256 price = stablecoin.getLatestPrice("GOLD");
        assertEq(price, GOLD_PRICE);
    }

    /// @notice Test getLatestPrice for SILVER.
    function testGetLatestPriceSilver() public {
        uint256 price = stablecoin.getLatestPrice("SILVER");
        assertEq(price, SILVER_PRICE);
    }

    /// @notice Test getTokenAmountFromUsd.
    function testGetTokenAmountFromUsd() public {
        uint256 usdAmount = 100e18;
        uint256 tokenAmount = stablecoin.getTokenAmountFromUsd("GOLD", usdAmount);
        // Since calculation involves constants and prices, simply assert the amount is nonzero.
        assertGt(tokenAmount, 0);
    }

    /// @notice Test getAccountCollateralValue.
    function testGetAccountCollateralValue() public {
        uint256 depositAmountGold = 10e18;
        uint256 depositAmountSilver = 5e18;

        vm.prank(user1);
        stablecoin.depositCollateral("GOLD", depositAmountGold);

        vm.prank(user1);
        stablecoin.depositCollateral("SILVER", depositAmountSilver);

        uint256 accountValue = stablecoin.getAccountCollateralValue(user1);

        // Expected value: (goldValue * 80 / 100) + (silverValue * 20 / 100)
        uint256 expectedGoldValue = depositAmountGold * GOLD_PRICE;
        uint256 expectedSilverValue = depositAmountSilver * SILVER_PRICE;
        uint256 expectedValue = (expectedGoldValue * 80 / 100) + (expectedSilverValue * 20 / 100);

        assertEq(accountValue, expectedValue);
    }

    /// @notice Test that liquidation reverts when the user's health factor is not below the threshold.
    function testLiquidationRevertsForHealthyPosition() public {
        // Healthy position for user2.
        vm.prank(user2);
        stablecoin.depositCollateral("GOLD", 100e18);
        vm.prank(user2);
        stablecoin.mintToken(1e18);

        // Attempt liquidation from user1 should revert.
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("HealthFactorOk()"));
        stablecoin.liquidate("GOLD", user2, 5e18);
    }

    /// @notice Test that liquidation reverts if computed collateral (with bonus) exceeds deposited collateral.
    function testLiquidationExceedsCollateral() public {
        // Set up an undercollateralized position for user2.
        vm.prank(user2);
        stablecoin.depositCollateral("GOLD", 1e18);
        vm.prank(user2);
        stablecoin.mintToken(0.5e18);

        // Attempt liquidation that would redeem more collateral than deposited.
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("LiquidationExceedsCollateral()"));
        stablecoin.liquidate("GOLD", user2, 0.4e18);
    }

    /// @notice Test getter constants.
    function testConstants() public {
        assertEq(stablecoin.getPrecision(), 1e18);
        assertEq(stablecoin.getLiquidationThreshold(), 50);
        assertEq(stablecoin.getLiquidationBonus(), 10);
        assertEq(stablecoin.getMinHealthFactor(), 1e18);
    }
}
