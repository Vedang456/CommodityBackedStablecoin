// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/GoldSilverStablecoin.sol";
import "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/tests/MockV3Aggregator.sol";

// Decimals and initial price for mock price feeds
uint8 constant DECIMALS = 18;
int256 constant GOLD_PRICE = int256(2000 * 10 ** DECIMALS);
int256 constant SILVER_PRICE = int256(25 * 10 ** DECIMALS);

contract GoldSilverStablecoinTest is Test {
    GoldSilverStablecoin public stablecoin; // Ensure this matches your deploy contract
    MockV3Aggregator public goldPriceFeed;
    MockV3Aggregator public silverPriceFeed;

    address public owner;
    address public user;

    function setUp() public {
        // Create mock price feeds
        goldPriceFeed = new MockV3Aggregator(DECIMALS, GOLD_PRICE);
        silverPriceFeed = new MockV3Aggregator(DECIMALS, SILVER_PRICE);

        // Set up addresses
        owner = address(this);
        user = address(0x123);

        // Deploy the stablecoin contract
        stablecoin = new GoldSilverStablecoin(
            address(goldPriceFeed),
            address(silverPriceFeed)
        );
    }

    // Test if the contract deploys successfully
    function testDeployment() public view{
        assertTrue(address(stablecoin) != address(0), "Stablecoin contract not deployed!");
    }

    // Test if the owner is set correctly
    function testOwner() public view {
        assertEq(owner, address(this), "Owner should be the deployer!");
    }

}
