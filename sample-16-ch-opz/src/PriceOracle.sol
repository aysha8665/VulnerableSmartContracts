// File: PriceOracle.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title PriceOracle
 * @dev Provides price feed functionality using Chainlink oracles
 * This contract wraps Chainlink price feeds to supply real-time ETH/USD pricing
 */
contract PriceOracle {
    AggregatorV3Interface internal priceFeed;
    
    /**
     * @dev Constructor initializes the Chainlink price feed
     * @param _priceFeed Address of the Chainlink ETH/USD price feed aggregator
     */
    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }
    
    /**
     * @dev Retrieves the latest ETH/USD price from Chainlink
     * @return The current ETH price in USD with 8 decimals
     */
    function getLatestPrice() public view returns (int256) {
        (
            /* uint80 roundID */,
            int256 price,
            /* uint256 startedAt */,
            /* uint256 timeStamp */,
            /* uint80 answeredInRound */
        ) = priceFeed.latestRoundData();
        return price;
    }
    
    /**
     * @dev Converts ETH amount to USD value
     * @param ethAmount Amount of ETH in wei
     * @return USD value with 18 decimals
     */
    function getEthValueInUSD(uint256 ethAmount) public view returns (uint256) {
        int256 price = getLatestPrice();
        require(price > 0, "Invalid price from oracle");
        
        // Price has 8 decimals, ethAmount is in wei (18 decimals)
        // Result will have 18 decimals
        return (ethAmount * uint256(price)) / 1e8;
    }
}