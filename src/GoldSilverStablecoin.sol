// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "../lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

error NotAuthorized();
error InvalidPrice();
error InsufficientBalance();

contract GoldSilverStablecoin is ERC20, Ownable {
    AggregatorV3Interface public immutable goldPriceFeed;
    AggregatorV3Interface public immutable silverPriceFeed;

    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);

    constructor(address _goldPriceFeed, address _silverPriceFeed)
        ERC20("Lydia Token", "LYD") // Token name and symbol
        Ownable(msg.sender) // Pass the deployer as the initial owner
    {
        require(_goldPriceFeed != address(0), "Invalid gold price feed address");
        require(_silverPriceFeed != address(0), "Invalid silver price feed address");

        goldPriceFeed = AggregatorV3Interface(_goldPriceFeed);
        silverPriceFeed = AggregatorV3Interface(_silverPriceFeed);
    }

    /**
     * @dev Mints stablecoins based on the provided gold and silver amounts.
     * Only the owner can call this function.
     * @param goldAmount Amount of gold.
     * @param silverAmount Amount of silver.
     */
    function mint(uint256 goldAmount, uint256 silverAmount) external onlyOwner {
        uint256 stablecoinValue = _calculateStablecoinValue(goldAmount, silverAmount);
        _mint(msg.sender, stablecoinValue);
        emit Mint(msg.sender, stablecoinValue);
    }

    /**
     * @dev Burns the specified amount of stablecoins from the caller's account.
     * Reverts if the caller does not have enough balance.
     * @param amount Amount of stablecoins to burn.
     */
    function burn(uint256 amount) external {
        if (balanceOf(msg.sender) < amount) revert InsufficientBalance();
        _burn(msg.sender, amount);
        emit Burn(msg.sender, amount);
    }

    /**
     * @dev Calculates the stablecoin value based on gold and silver amounts.
     * Public function for external viewing.
     * @param goldAmount Amount of gold.
     * @param silverAmount Amount of silver.
     * @return The calculated stablecoin value.
     */
    function calculateStablecoinValue(uint256 goldAmount, uint256 silverAmount) public view returns (uint256) {
        uint256 goldPrice = _getLatestPrice(goldPriceFeed);
        uint256 silverPrice = _getLatestPrice(silverPriceFeed);

        // Calculate total value based on the 80:20 gold-to-silver ratio
        uint256 totalValue = (goldAmount * goldPrice * 80) / 100 + (silverAmount * silverPrice * 20) / 100;
        return totalValue;
    }

    /**
     * @dev Internal function to fetch the latest price from a Chainlink price feed.
     * Reverts if the price is invalid or negative.
     * @param priceFeed The Chainlink AggregatorV3Interface.
     * @return The latest price as a uint256.
     */
    function _getLatestPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (, int256 price,,,) = priceFeed.latestRoundData();
        if (price <= 0) revert InvalidPrice();
        return uint256(price);
    }

    /**
     * @dev Internal function to calculate stablecoin value.
     * Calls the public calculateStablecoinValue function.
     * @param goldAmount Amount of gold.
     * @param silverAmount Amount of silver.
     * @return The calculated stablecoin value.
     */
    function _calculateStablecoinValue(uint256 goldAmount, uint256 silverAmount) internal view returns (uint256) {
        return calculateStablecoinValue(goldAmount, silverAmount);
    }
}

// 100 billion coins mint
