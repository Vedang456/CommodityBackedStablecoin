// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/GoldSilverStablecoin.sol";

contract Deploy {
    GoldSilverStablecoin public stablecoin;

    /**
     * @notice Deploys the GoldSilverStablecoin contract.
     * @param _goldPriceFeed The address of the Chainlink price feed for GOLD.
     * @param _silverPriceFeed The address of the Chainlink price feed for SILVER.
     */
    constructor(address _goldPriceFeed, address _silverPriceFeed) {
        stablecoin = new GoldSilverStablecoin(_goldPriceFeed, _silverPriceFeed);
    }
}

// As there is no pricefeed availailible for Silver/USD , for testting purpouses purely, we will use AUD/USD pricefeed in the Silver/USD placeholder.
// The pricefeed addresses are given below: 
//  Actual SILVER PRICE FEED= 0x379589227b15F1a12195D3f2d90bBc9F31f95235;   // Ethereum mainnet Silver/USD
//  Actual GOLD PRICE FEED= 0x214eD9Da11D2fbe465a6fc601a91E62EbEc1a0D6;     // Ethereum mainnet Gold/USD
//  Testnet AUD/USD pricefeed = 0xB0C712f98daE15264c8E26132BCC91C40aD4d5F9;
// Testnet Gold/USD pricefeed = 0xC5981F461d74c46eB4b0CF3f4Ec79f025573B0Ea;