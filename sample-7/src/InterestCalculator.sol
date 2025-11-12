// FILE: contracts/InterestCalculator.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title InterestCalculator
 * @dev Simple interest calculation contract
 */
contract InterestCalculator {
    uint256 public constant RATE = 5; // 5%
    uint256 public constant YEAR = 31536000; // seconds
    
    function calculate(uint256 amount, uint256 time) 
        external 
        pure 
        returns (uint256) 
    {
        return (amount * RATE * time) / (100 * YEAR);
    }
}