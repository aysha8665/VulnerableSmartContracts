// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title OracleManager
 * @dev Manages the reference to an external Chainlink Oracle. 
 * Uses OpenZeppelin's Ownable for access control on configuration functions.
 */
contract OracleManager is Ownable {
    AggregatorV3Interface internal priceFeed;

    /**
     * @dev Initializes the contract with the initial owner and oracle address.
     * @param _initialOwner The address that will govern the contract.
     * @param _priceFeed The address of the Chainlink ETH/USD price feed.
     */
    constructor(address _initialOwner, address _priceFeed) Ownable(_initialOwner) {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    /**
     * @dev Updates the Chainlink price feed address.
     * @param _newPriceFeed The new oracle address.
     */
    function setPriceFeed(address _newPriceFeed) external onlyOwner {
        priceFeed = AggregatorV3Interface(_newPriceFeed);
    }

    /**
     * @dev Internal view to get the latest price from the oracle.
     * Used to log the USD value of transactions for historical data.
     * @return The latest answer from the Aggregator.
     */
    function _getLatestPrice() internal view returns (int256) {
        (
            /* uint80 roundID */,
            int256 price,
            /* uint startedAt */,
            /* uint timeStamp */,
            /* uint80 answeredInRound */
        ) = priceFeed.latestRoundData();
        return price;
    }
}