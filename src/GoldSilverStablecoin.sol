// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "../lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";


error NotAuthorized();
error InvalidPrice();
error InsufficientBalance();
error TokenNotAllowed(address token);
error TransferFailed();
error BreaksHealthFactor(uint256 healthFactorValue);
error MintFailed();
error HealthFactorOk();
error HealthFactorNotImproved();
error NeedsMoreThanZero();

contract GoldSilverStablecoin is ERC20, Ownable, ReentrancyGuard {
    AggregatorV3Interface public immutable goldPriceFeed;
    AggregatorV3Interface public immutable silverPriceFeed;
    
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // 200% overcollateralization required
    uint256 private constant LIQUIDATION_BONUS = 10; // 10% bonus for liquidators
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant FEED_PRECISION = 1e8;

    mapping(address user => mapping(string collateralType => uint256 amount)) private s_collateralDeposited;
    mapping(address user => uint256 amount) private s_tokenMinted;

    event CollateralDeposited(address indexed user, string collateralType, uint256 indexed amount);
    event CollateralRedeemed(
        address indexed redeemFrom, 
        address indexed redeemTo, 
        string collateralType, 
        uint256 amount
    );
    event TokenMinted(address indexed to, uint256 amount);
    event TokenBurned(address indexed from, uint256 amount);

    constructor(address _goldPriceFeed, address _silverPriceFeed)
        ERC20("Lydia Token", "LYD")
        Ownable(msg.sender)
    {
        require(_goldPriceFeed != address(0), "Invalid gold price feed address");
        require(_silverPriceFeed != address(0), "Invalid silver price feed address");

        goldPriceFeed = AggregatorV3Interface(_goldPriceFeed);
        silverPriceFeed = AggregatorV3Interface(_silverPriceFeed);
    }

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) revert NeedsMoreThanZero();
        _;
    }

    function depositCollateralAndMint(
        string memory collateralType,
        uint256 collateralAmount,
        uint256 amountToMint
    ) external nonReentrant moreThanZero(collateralAmount) {
        depositCollateral(collateralType, collateralAmount);
        mintToken(amountToMint);
    }

    function depositCollateral(
        string memory collateralType,
        uint256 amount
    ) public moreThanZero(amount) nonReentrant {
        s_collateralDeposited[msg.sender][collateralType] += amount;
        emit CollateralDeposited(msg.sender, collateralType, amount);
    }

    function mintToken(uint256 amountToMint) public moreThanZero(amountToMint) nonReentrant {
        s_tokenMinted[msg.sender] += amountToMint;
        revertIfHealthFactorIsBroken(msg.sender);
        _mint(msg.sender, amountToMint);
        emit TokenMinted(msg.sender, amountToMint);
    }

    function redeemCollateralForToken(
        string memory collateralType,
        uint256 collateralAmount,
        uint256 tokenToBurn
    ) external moreThanZero(collateralAmount) nonReentrant {
        burnToken(tokenToBurn);
        redeemCollateral(collateralType, collateralAmount);
        revertIfHealthFactorIsBroken(msg.sender);
    }

    function redeemCollateral(
        string memory collateralType,
        uint256 collateralAmount
    ) public moreThanZero(collateralAmount) nonReentrant {
        _redeemCollateral(collateralType, collateralAmount, msg.sender, msg.sender);
        revertIfHealthFactorIsBroken(msg.sender);
    }

    function burnToken(uint256 amount) public moreThanZero(amount) {
        _burnToken(amount, msg.sender, msg.sender);
        revertIfHealthFactorIsBroken(msg.sender);
    }

    function liquidate(
        string memory collateralType,
        address user,
        uint256 debtToCover
    ) external moreThanZero(debtToCover) nonReentrant {
        uint256 startingUserHealthFactor = _healthFactor(user);
        if (startingUserHealthFactor >= MIN_HEALTH_FACTOR) {
            revert HealthFactorOk();
        }

        uint256 tokenAmountFromDebtCovered = getTokenAmountFromUsd(collateralType, debtToCover);
        uint256 bonusCollateral = (tokenAmountFromDebtCovered * LIQUIDATION_BONUS) / LIQUIDATION_PRECISION;
        
        _redeemCollateral(
            collateralType, 
            tokenAmountFromDebtCovered + bonusCollateral, 
            user, 
            msg.sender
        );
        _burnToken(debtToCover, user, msg.sender);

        uint256 endingUserHealthFactor = _healthFactor(user);
        if (endingUserHealthFactor <= startingUserHealthFactor) {
            revert HealthFactorNotImproved();
        }
        revertIfHealthFactorIsBroken(msg.sender);
    }

    function _redeemCollateral(
        string memory collateralType,
        uint256 collateralAmount,
        address from,
        address to
    ) private {
        s_collateralDeposited[from][collateralType] -= collateralAmount;
        emit CollateralRedeemed(from, to, collateralType, collateralAmount);
    }

    function _burnToken(uint256 amountToBurn, address onBehalfOf, address tokenFrom) private {
        s_tokenMinted[onBehalfOf] -= amountToBurn;
        _burn(tokenFrom, amountToBurn);
        emit TokenBurned(tokenFrom, amountToBurn);
    }

    function _getAccountInformation(address user) 
        private 
        view 
        returns (uint256 totalTokenMinted, uint256 collateralValueInUsd) 
    {
        totalTokenMinted = s_tokenMinted[user];
        collateralValueInUsd = getAccountCollateralValue(user);
    }

    function _healthFactor(address user) private view returns (uint256) {
        (uint256 totalTokenMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);
        return _calculateHealthFactor(totalTokenMinted, collateralValueInUsd);
    }

    function _calculateHealthFactor(
        uint256 totalTokenMinted,
        uint256 collateralValueInUsd
    ) internal pure returns (uint256) {
        if (totalTokenMinted == 0) return type(uint256).max;
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return (collateralAdjustedForThreshold * PRECISION) / totalTokenMinted;
    }

    function revertIfHealthFactorIsBroken(address user) internal view {
        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert BreaksHealthFactor(userHealthFactor);
        }
    }

    function getLatestPrice(string memory collateralType) public view returns (uint256) {
        AggregatorV3Interface priceFeed = (keccak256(abi.encodePacked(collateralType)) == keccak256(abi.encodePacked("GOLD")))
    ? goldPriceFeed
    : (keccak256(abi.encodePacked(collateralType)) == keccak256(abi.encodePacked("SILVER"))
        ? silverPriceFeed
        : AggregatorV3Interface(address(0)));
        (, int256 price,,,) = priceFeed.latestRoundData();
        if (price <= 0) revert InvalidPrice();
        return uint256(price);
    }

    function getTokenAmountFromUsd(string memory collateralType, uint256 usdAmountInWei) public view returns (uint256) {
        uint256 price = getLatestPrice(collateralType);
        return ((usdAmountInWei * PRECISION) / (price * ADDITIONAL_FEED_PRECISION));
    }

    function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUsd) {
        uint256 goldValue = s_collateralDeposited[user]["GOLD"] * getLatestPrice("GOLD");
        uint256 silverValue = s_collateralDeposited[user]["SILVER"] * getLatestPrice("SILVER");
        
        // Apply 80:20 ratio
        totalCollateralValueInUsd = (goldValue * 80 / 100) + (silverValue * 20 / 100);
        return totalCollateralValueInUsd;
    }

    // Getter Functions
    function getCollateralBalance(address user, string memory collateralType) external view returns (uint256) {
        return s_collateralDeposited[user][collateralType];
    }

    function getHealthFactor(address user) external view returns (uint256) {
        return _healthFactor(user);
    }

    function getPrecision() external pure returns (uint256) {
        return PRECISION;
    }

    function getLiquidationThreshold() external pure returns (uint256) {
        return LIQUIDATION_THRESHOLD;
    }

    function getLiquidationBonus() external pure returns (uint256) {
        return LIQUIDATION_BONUS;
    }

    function getMinHealthFactor() external pure returns (uint256) {
        return MIN_HEALTH_FACTOR;
    }
}

// 100 billion coins mint