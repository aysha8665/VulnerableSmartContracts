// File: RewardCalculator.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title RewardCalculator
 * @notice Helper contract for calculating staking rewards
 * @dev Provides utility functions for reward computation
 */
contract RewardCalculator {
    uint256 public constant REWARD_RATE = 5; // 5% reward rate
    uint256 public constant RATE_DENOMINATOR = 100;
    
    /**
     * @notice Calculates rewards based on staked amount
     * @param stakedAmount The amount of tokens staked
     * @return The calculated reward amount
     */
    function calculateReward(uint256 stakedAmount) public pure returns (uint256) {
        return (stakedAmount * REWARD_RATE) / RATE_DENOMINATOR;
    }
    
    /**
     * @notice Validates that an amount is non-zero
     * @param amount The amount to validate
     * @return True if amount is valid
     */
    function isValidAmount(uint256 amount) public pure returns (bool) {
        return amount > 0;
    }
}