/**
 * @title YieldStaking
 * @dev Final implementation that combines staking and reward claiming
 * 
 * This contract inherits from StakingBase (which inherits from RewardPool)
 * and provides the complete functionality for a yield staking platform:
 * - Users can stake ETH
 * - Rewards are calculated based on stake amount and duration
 * - Users can claim their rewards
 * - Users can unstake their tokens
 * 
 * The contract is designed to be simple and gas-efficient while providing
 * a complete staking solution.
 */

 import "./StakingBase.sol";
contract YieldStaking is StakingBase {
    
    // ============ State Variables ============
    
    /// @notice Contract owner address
    /// @dev Has administrative privileges
    address public owner;
    
    /// @notice Minimum time required before unstaking
    /// @dev Prevents immediate stake/unstake cycles
    uint256 public constant LOCK_PERIOD = 1 days;
    
    /// @notice Whether the contract is paused
    /// @dev When true, staking and claiming are disabled
    bool public paused;
    
    // ============ Events ============
    
    /// @notice Emitted when contract is paused
    event Paused();
    
    /// @notice Emitted when contract is unpaused
    event Unpaused();
    
    // ============ Constructor ============
    
    /**
     * @dev Initializes the YieldStaking contract
     * Sets the deployer as the owner
     */
    constructor() {
        owner = msg.sender;
        paused = false;
    }
    
    // ============ Modifiers ============
    
    /**
     * @dev Restricts function to contract owner only
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }
    
    /**
     * @dev Prevents execution when contract is paused
     */
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }
    
    // ============ Main Functions ============
    
    /**
     * @notice Allows users to unstake their tokens
     * @dev Users can withdraw their staked amount after lock period
     * Pending rewards are calculated and added before unstaking
     * @param _amount The amount to unstake
     */
    function unstake(uint256 _amount) public whenNotPaused {
        require(stakedBalances[msg.sender] >= _amount, "Insufficient stake");
        require(_amount > 0, "Amount must be positive");
        
        // Check lock period
        require(
            block.timestamp >= stakeTimestamp[msg.sender] + LOCK_PERIOD,
            "Stake is still locked"
        );
        
        // Calculate and add pending rewards before unstaking
        _calculateAndAddRewards(msg.sender);
        
        // Update balances
        stakedBalances[msg.sender] -= _amount;
        totalStaked -= _amount;
        
        // Update timestamp for remaining stake
        stakeTimestamp[msg.sender] = block.timestamp;
        
        // Transfer unstaked amount back to user
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Transfer failed");
        
        emit Unstaked(msg.sender, _amount);
    }
    
    /**
     * @notice Allows users to claim their accumulated rewards
     * @dev This is THE VULNERABLE FUNCTION
     * 
     * Users can claim their earned rewards at any time.
     * The function first calculates any new rewards based on current stake,
     * then transfers the total accumulated rewards to the user.
     * 
     * VULNERABILITY: The external call to transfer rewards happens BEFORE
     * the state is updated (rewards balance set to zero). This creates a
     * reentrancy vulnerability where a malicious contract can recursively
     * call claimRewards() multiple times before the state is updated,
     * draining more rewards than they're entitled to.
     */
    function claimRewards() public whenNotPaused {
        // First, calculate and add any new rewards from current stake
        _calculateAndAddRewards(msg.sender);
        
        // Get total rewards
        uint256 rewardAmount = rewards[msg.sender];
        require(rewardAmount > 0, "No rewards to claim");
        
        // THE VULNERABILITY IS HERE:
        // External call happens BEFORE state update
        // An attacker can create a malicious contract that calls claimRewards()
        // again in its receive() function, before rewards[msg.sender] is set to 0
        (bool success, ) = payable(msg.sender).call{value: rewardAmount}("");
        require(success, "Reward transfer failed");
        
        // State update happens AFTER the external call
        // By this time, an attacker may have already claimed multiple times
        rewards[msg.sender] = 0;
        totalRewardsClaimed += rewardAmount;
        
        emit RewardsClaimed(msg.sender, rewardAmount);
    }
    
    /**
     * @notice Compounds rewards back into staked balance
     * @dev Instead of claiming, user can reinvest rewards to earn more
     * This is secure because no external calls are made
     */
    function compoundRewards() public whenNotPaused {
        // Calculate and add pending rewards
        _calculateAndAddRewards(msg.sender);
        
        uint256 rewardAmount = rewards[msg.sender];
        require(rewardAmount > 0, "No rewards to compound");
        
        // Add rewards to staked balance (no external call, so safe)
        stakedBalances[msg.sender] += rewardAmount;
        totalStaked += rewardAmount;
        
        // Clear rewards and update timestamp
        rewards[msg.sender] = 0;
        stakeTimestamp[msg.sender] = block.timestamp;
        
        emit Staked(msg.sender, rewardAmount);
    }
    
    // ============ Administrative Functions ============
    
    /**
     * @notice Allows owner to fund the reward pool
     * @dev Owner can add ETH to the contract for reward distribution
     */
    function fundRewards() public payable onlyOwner {
        require(msg.value > 0, "Must send ETH");
        _fundPool(msg.value);
    }
    
    /**
     * @notice Pauses the contract
     * @dev Only owner can pause in case of emergency
     */
    function pause() public onlyOwner {
        paused = true;
        emit Paused();
    }
    
    /**
     * @notice Unpauses the contract
     * @dev Only owner can unpause
     */
    function unpause() public onlyOwner {
        paused = false;
        emit Unpaused();
    }
    
    /**
     * @notice Transfers ownership to a new address
     * @dev Only current owner can transfer ownership
     * @param _newOwner Address of the new owner
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
    }
    
    // ============ View Functions ============
    
    /**
     * @notice Gets comprehensive user information
     * @param _user The user's address
     * @return stakedAmount Amount currently staked
     * @return pendingRewards Total pending rewards
     * @return stakingTime Timestamp of last stake
     */
    function getUserInfo(address _user)
        public
        view
        returns (
            uint256 stakedAmount,
            uint256 pendingRewards,
            uint256 stakingTime
        )
    {
        return (
            stakedBalances[_user],
            calculatePendingRewards(_user),
            stakeTimestamp[_user]
        );
    }
    
    /**
     * @notice Gets contract statistics
     * @return totalStakedAmount Total amount staked in the contract
     * @return totalRewards Total rewards in the pool
     * @return totalClaimed Total rewards claimed by all users
     * @return contractBalance Current ETH balance of the contract
     */
    function getContractStats()
        public
        view
        returns (
            uint256 totalStakedAmount,
            uint256 totalRewards,
            uint256 totalClaimed,
            uint256 contractBalance
        )
    {
        return (
            totalStaked,
            totalRewardPool,
            totalRewardsClaimed,
            address(this).balance
        );
    }
    
    /**
     * @notice Checks if a user's stake is still locked
     * @param _user The user's address
     * @return bool True if still locked, false if can unstake
     */
    function isStakeLocked(address _user) public view returns (bool) {
        if (stakedBalances[_user] == 0) return false;
        return block.timestamp < stakeTimestamp[_user] + LOCK_PERIOD;
    }
    
    /**
     * @notice Gets time remaining until unstake is available
     * @param _user The user's address
     * @return uint256 Seconds remaining, or 0 if can unstake now
     */
    function getTimeUntilUnlock(address _user) public view returns (uint256) {
        if (stakedBalances[_user] == 0) return 0;
        
        uint256 unlockTime = stakeTimestamp[_user] + LOCK_PERIOD;
        if (block.timestamp >= unlockTime) return 0;
        
        return unlockTime - block.timestamp;
    }
    
    /**
     * @notice Allows contract to receive ETH
     * @dev Used for adding funds to reward pool
     */
    receive() external payable {
        _fundPool(msg.value);
    }
}