// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title RewardPool
 * @dev Base contract that manages a reward pool system
 * 
 * This contract provides the foundational reward distribution logic
 * that can be inherited by more specific implementations. It handles:
 * - Tracking user reward balances
 * - Adding rewards to the pool
 * - Internal reward calculation logic
 * 
 * This is designed as a base contract to be extended with specific
 * reward distribution strategies in child contracts.
 */
contract RewardPool {
    
    // ============ State Variables ============
    
    /// @notice Mapping of user addresses to their accumulated rewards
    /// @dev Tracks unclaimed rewards for each user
    mapping(address => uint256) public rewards;
    
    /// @notice Total rewards available in the pool
    /// @dev Sum of all rewards that have been added to the pool
    uint256 public totalRewardPool;
    
    /// @notice Total rewards that have been claimed by users
    /// @dev Used for accounting and statistics
    uint256 public totalRewardsClaimed;
    
    // ============ Events ============
    
    /// @notice Emitted when rewards are added to a user's balance
    /// @param user Address of the user
    /// @param amount Amount of rewards added
    event RewardsAdded(address indexed user, uint256 amount);
    
    /// @notice Emitted when rewards are added to the pool
    /// @param amount Amount added to the pool
    event PoolFunded(uint256 amount);
    
    /// @notice Emitted when a user claims rewards
    /// @param user Address of the user
    /// @param amount Amount of rewards claimed
    event RewardsClaimed(address indexed user, uint256 amount);
    
    // ============ Constructor ============
    
    /**
     * @dev Initializes the reward pool
     * Sets initial values to zero
     */
    constructor() {
        totalRewardPool = 0;
        totalRewardsClaimed = 0;
    }
    
    // ============ Internal Functions ============
    
    /**
     * @notice Internal function to add rewards to a user's balance
     * @dev This function should only be called by child contracts
     * It updates the user's reward balance and emits an event
     * @param _user The address to receive rewards
     * @param _amount The amount of rewards to add
     */
    function _addRewards(address _user, uint256 _amount) internal {
        require(_user != address(0), "Invalid user address");
        require(_amount > 0, "Amount must be positive");
        
        // Add to user's reward balance
        rewards[_user] += _amount;
        
        emit RewardsAdded(_user, _amount);
    }
    
    /**
     * @notice Internal function to update total reward pool
     * @dev Called when new rewards are deposited into the contract
     * @param _amount Amount to add to the pool
     */
    function _fundPool(uint256 _amount) internal {
        totalRewardPool += _amount;
        emit PoolFunded(_amount);
    }
    
    // ============ View Functions ============
    
    /**
     * @notice Gets the pending rewards for a user
     * @param _user The user's address
     * @return The amount of unclaimed rewards
     */
    function getPendingRewards(address _user) public view returns (uint256) {
        return rewards[_user];
    }
    
    /**
     * @notice Gets total rewards available in the pool
     * @return Total amount in the reward pool
     */
    function getTotalRewardPool() public view returns (uint256) {
        return totalRewardPool;
    }
    
    /**
     * @notice Gets total rewards claimed by all users
     * @return Total amount of rewards claimed
     */
    function getTotalRewardsClaimed() public view returns (uint256) {
        return totalRewardsClaimed;
    }
}