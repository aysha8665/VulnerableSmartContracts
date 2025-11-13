// File: StakingPool.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IRewardPool.sol";
import "./RewardCalculator.sol";
import "./Pausable.sol";

/**
 * @title StakingPool
 * @notice A staking pool where users can stake ETH and claim rewards
 * @dev Inherits from Pausable and uses RewardCalculator for reward computation
 */
contract StakingPool is IRewardPool, Pausable {
    RewardCalculator public calculator;
    
    mapping(address => uint256) private stakedBalances;
    mapping(address => uint256) private pendingRewards;
    
    event Staked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    
    /**
     * @notice Deploys the staking pool and initializes the reward calculator
     */
    constructor() {
        calculator = new RewardCalculator();
    }
    
    /**
     * @notice Allows users to stake ETH in the pool
     * @dev Updates staked balance and calculates initial rewards
     */
    function stake(uint256) external payable override whenNotPaused {
        require(msg.value > 0, "StakingPool: stake amount must be greater than 0");
        require(calculator.isValidAmount(msg.value), "StakingPool: invalid amount");
        
        stakedBalances[msg.sender] += msg.value;
        uint256 reward = calculator.calculateReward(msg.value);
        pendingRewards[msg.sender] += reward;
        
        emit Staked(msg.sender, msg.value);
    }
    
    /**
     * @notice Allows users to claim their accumulated rewards
     * @dev Sends the pending rewards to the caller
     */
    function claimRewards() external override whenNotPaused {
        uint256 rewards = pendingRewards[msg.sender];
        require(rewards > 0, "StakingPool: no rewards to claim");
        require(address(this).balance >= rewards, "StakingPool: insufficient contract balance");
        
        (bool success, ) = msg.sender.call{value: rewards}("");
        require(success, "StakingPool: reward transfer failed");
        
        pendingRewards[msg.sender] = 0;
        
        emit RewardsClaimed(msg.sender, rewards);
    }
    
    /**
     * @notice Returns the staked balance of a user
     * @param user The address to query
     * @return The amount of ETH staked by the user
     */
    function getStakedBalance(address user) external view override returns (uint256) {
        return stakedBalances[user];
    }
    
    /**
     * @notice Returns the pending rewards for a user
     * @param user The address to query
     * @return The amount of rewards pending for the user
     */
    function getPendingRewards(address user) external view override returns (uint256) {
        return pendingRewards[user];
    }
    
    /**
     * @notice Allows the contract to receive ETH directly
     */
    receive() external payable {}
}