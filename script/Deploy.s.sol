// SPDX-License-Identifier: MIT
//          export SILVER PRICE FEED= 0x379589227b15F1a12195D3f2d90bBc9F31f95235; // Ethereum mainnet Silver/USD
//          Export GOLD Test PRICE FEED = 0xC5981F461d74c46eB4b0CF3f4Ec79f025573B0Ea
//          export GOLD PRICE FEED= 0x214eD9Da11D2fbe465a6fc601a91E62EbEc1a0D6; // Ethereum mainnet Gold/USD
//          export PRIVATE KEY= 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/GoldSilverStablecoin.sol";

contract Deploy is Script {
    function run() external {
        // Fetch private key and deployer address from environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        console.log("Deploying contract with address:", deployerAddress);

        // Fetch Chainlink price feed addresses from environment variables
        address goldPriceFeed = vm.envAddress("GOLD_PRICE_FEED");
        address silverPriceFeed = vm.envAddress("SILVER_PRICE_FEED");

        // Validate price feed addresses
        require(goldPriceFeed != address(0), "Invalid gold price feed address");
        require(silverPriceFeed != address(0), "Invalid silver price feed address");

        // Start broadcasting using the deployer's private key
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the GoldSilverStablecoin contract
        GoldSilverStablecoin stablecoin = new GoldSilverStablecoin(goldPriceFeed, silverPriceFeed);

        // Stop broadcasting
        vm.stopBroadcast();

        // Log the deployed contract address
        console.log("GoldSilverStablecoin deployed at:", address(stablecoin));
    }
}
