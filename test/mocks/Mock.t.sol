// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/GoldSilverStablecoin.sol";
import "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/tests/MockV3Aggregator.sol";

// Decimals and initial price for mock price feeds
uint8 constant DECIMALS = 18;
int256 constant GOLD_PRICE = int256(2000 * 10 ** DECIMALS);
int256 constant SILVER_PRICE = int256(25 * 10 ** DECIMALS);

// Define custom errors for testing
// error InvalidPrice();
// error InsufficientBalance();

contract GoldSilverStablecoinMockTest is Test {
    GoldSilverStablecoin public stablecoin;
    MockV3Aggregator public goldPriceFeed;
    MockV3Aggregator public silverPriceFeed;

    address public owner;

    function setUp() public {
        goldPriceFeed = new MockV3Aggregator(DECIMALS, GOLD_PRICE);
        silverPriceFeed = new MockV3Aggregator(DECIMALS, SILVER_PRICE);

        owner = address(this);

        stablecoin = new GoldSilverStablecoin(address(goldPriceFeed), address(silverPriceFeed));
    }

    function testInvalidGoldPrice() public {
        // Set an invalid price in the mock price feed
        goldPriceFeed.updateAnswer(0);

        // Expect the custom error to be reverted
        vm.expectRevert(abi.encodeWithSelector(InvalidPrice.selector));
        stablecoin.calculateStablecoinValue(10, 10);
    }

    function testInvalidSilverPrice() public {
        // Set an invalid price in the mock price feed
        silverPriceFeed.updateAnswer(-1);

        // Expect the custom error to be reverted
        vm.expectRevert(abi.encodeWithSelector(InvalidPrice.selector));
        stablecoin.calculateStablecoinValue(10, 10);
    }

    function testInsufficientBalance() public {
        // Expect the custom error to be reverted
        vm.expectRevert(abi.encodeWithSelector(InsufficientBalance.selector));
        stablecoin.burn(100);
    }

    function testPriceFeedUpdate() public {
        int256 newGoldPrice = int256(3000 * 10 ** DECIMALS);
        int256 newSilverPrice = int256(30 * 10 ** DECIMALS);

        goldPriceFeed.updateAnswer(newGoldPrice);
        silverPriceFeed.updateAnswer(newSilverPrice);

        uint256 goldAmount = 10;
        uint256 silverAmount = 10;

        uint256 expectedValue =
            (goldAmount * uint256(newGoldPrice) * 80) / 100 + (silverAmount * uint256(newSilverPrice) * 20) / 100;

        uint256 calculatedValue = stablecoin.calculateStablecoinValue(goldAmount, silverAmount);
        assertEq(calculatedValue, expectedValue, "Price feed update mismatch!");
    }
}
