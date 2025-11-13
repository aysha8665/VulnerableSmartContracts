// File: IRewardPool.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IRewardPool
 * @notice Interface for the reward pool contract
 * @dev Defines the core functionality for staking and reward claiming
 */
interface IRewardPool {
    /**
     * @notice Stakes tokens in the pool
     * @param amount The amount of tokens to stake
     */
    function stake(uint256 amount) external payable;
    
    /**
     * @notice Claims all accumulated rewards for the caller
     */
    function claimRewards() external;
    
    /**
     * @notice Returns the staked balance of a user
     * @param user The address to query
     * @return The staked balance
     */
    function getStakedBalance(address user) external view returns (uint256);
    
    /**
     * @notice Returns the pending rewards for a user
     * @param user The address to query
     * @return The pending reward amount
     */
    function getPendingRewards(address user) external view returns (uint256);
}