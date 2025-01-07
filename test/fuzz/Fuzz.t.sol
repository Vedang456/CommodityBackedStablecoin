// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/GoldSilverStablecoin.sol";
import "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/tests/MockV3Aggregator.sol";

uint8 constant DECIMALS = 18;
int256 constant GOLD_PRICE = int256(2000 * 10 ** DECIMALS);
int256 constant SILVER_PRICE = int256(25 * 10 ** DECIMALS);

contract GoldSilverStablecoinFuzzTest is Test {
    GoldSilverStablecoin public stablecoin;
    MockV3Aggregator public goldPriceFeed;
    MockV3Aggregator public silverPriceFeed;

    address public owner;

    function setUp() public {
        goldPriceFeed = new MockV3Aggregator(DECIMALS, GOLD_PRICE);
        silverPriceFeed = new MockV3Aggregator(DECIMALS, SILVER_PRICE);
        owner = address(this);

        stablecoin = new GoldSilverStablecoin(
            address(goldPriceFeed),
            address(silverPriceFeed)
        );
    }

    function testFuzzMint(uint256 goldAmount, uint256 silverAmount) public {
        goldAmount = bound(goldAmount, 1, 1e18);
        silverAmount = bound(silverAmount, 1, 1e18);

        uint256 expectedValue = stablecoin.calculateStablecoinValue(goldAmount, silverAmount);
        stablecoin.mint(goldAmount, silverAmount);

        assertEq(stablecoin.balanceOf(owner), expectedValue, "Fuzz mint value mismatch!");
    }

    function testFuzzBurn(uint256 mintAmount, uint256 burnAmount) public {
        mintAmount = bound(mintAmount, 1, 1e18);
        burnAmount = bound(burnAmount, 1, mintAmount);

        stablecoin.mint(mintAmount, 0);
        uint256 initialBalance = stablecoin.balanceOf(owner);

        stablecoin.burn(burnAmount);

        assertEq(stablecoin.balanceOf(owner), initialBalance - burnAmount, "Fuzz burn value mismatch!");
    }
}
