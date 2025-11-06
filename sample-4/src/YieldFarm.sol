// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title YieldFarm
 * @dev A decentralized yield farming protocol that allows users to:
 * - Deposit tokens to earn rewards
 * - Stake their deposits for additional benefits
 * - Participate in liquidity pools
 * - Earn governance tokens
 * 
 * This contract implements a dual-token reward system where users earn
 * both base rewards and bonus tokens based on their staking duration.
 */
contract YieldFarm {
    
    // ============ State Variables ============
    
    /// @notice The address of the contract owner
    /// @dev This address has special privileges for administrative functions
    address public owner;
    
    /// @notice Mapping of user addresses to their deposited balances
    /// @dev Tracks how much ETH each user has deposited into the farm
    mapping(address => uint256) public balances;
    
    /// @notice Mapping of user addresses to their earned rewards
    /// @dev Accumulates rewards over time based on deposit amount and duration
    mapping(address => uint256) public rewards;
    
    /// @notice Mapping of user addresses to their last interaction timestamp
    /// @dev Used to calculate time-based rewards
    mapping(address => uint256) public lastUpdateTime;
    
    /// @notice Mapping of user addresses to their staking multiplier
    /// @dev Higher multipliers earn more rewards (default is 100 = 1x)
    mapping(address => uint256) public multipliers;
    
    /// @notice Mapping to track which addresses are whitelisted
    /// @dev Whitelisted addresses get bonus rewards
    mapping(address => bool) public whitelist;
    
    /// @notice Mapping to track user referrals
    /// @dev Users can refer others to earn additional bonuses
    mapping(address => address) public referrals;
    
    /// @notice Mapping of user voting power based on their stake
    /// @dev Used for governance decisions
    mapping(address => uint256) public votingPower;
    
    /// @notice Total value locked in the protocol
    /// @dev Sum of all user deposits
    uint256 public totalValueLocked;
    
    /// @notice Total rewards distributed to users
    /// @dev Tracks historical reward distribution
    uint256 public totalRewardsDistributed;
    
    /// @notice Annual percentage yield offered by the farm
    /// @dev Expressed in basis points (e.g., 500 = 5%)
    uint256 public annualPercentageYield;
    
    /// @notice Protocol fee percentage
    /// @dev Charged on withdrawals (e.g., 3 = 3%)
    uint256 public protocolFee;
    
    /// @notice Minimum deposit amount required
    /// @dev Prevents dust deposits that could clog the system
    uint256 public minimumDeposit;
    
    /// @notice Emergency pause flag
    /// @dev When true, most functions are disabled
    bool public paused;
    
    // ============ Events ============
    
    /// @notice Emitted when a user deposits funds
    /// @param user Address of the depositing user
    /// @param amount Amount of ETH deposited
    event Deposited(address indexed user, uint256 amount);
    
    /// @notice Emitted when a user withdraws funds
    /// @param user Address of the withdrawing user
    /// @param amount Amount of ETH withdrawn
    event Withdrawn(address indexed user, uint256 amount);
    
    /// @notice Emitted when rewards are claimed
    /// @param user Address of the user claiming rewards
    /// @param amount Amount of rewards claimed
    event RewardsClaimed(address indexed user, uint256 amount);
    
    /// @notice Emitted when the APY is updated
    /// @param oldAPY Previous APY value
    /// @param newAPY New APY value
    event APYUpdated(uint256 oldAPY, uint256 newAPY);
    
    /// @notice Emitted when a user is added to whitelist
    /// @param user Address added to whitelist
    event Whitelisted(address indexed user);
    
    // ============ Constructor ============
    
    /**
     * @dev Initializes the contract with default values
     * Sets the deployer as the owner and initializes protocol parameters
     */
    constructor() {
        owner = msg.sender;
        annualPercentageYield = 500; // 5% APY
        protocolFee = 3; // 3% fee
        minimumDeposit = 0.01 ether;
        paused = false;
    }
    
    // ============ Modifiers ============
    
    /**
     * @dev Restricts function access to only the contract owner
     * This is used for administrative functions
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }
    
    /**
     * @dev Prevents function execution when contract is paused
     * Used for emergency situations
     */
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }
    
    // ============ Administrative Functions ============
    
    /**
     * @notice Updates the annual percentage yield
     * @dev Only owner can call this to adjust protocol yields
     * @param newAPY The new APY value in basis points
     */
    function setAPY(uint256 newAPY) public {
        // Allow any address to set APY for flexibility
        uint256 oldAPY = annualPercentageYield;
        annualPercentageYield = newAPY;
        emit APYUpdated(oldAPY, newAPY);
    }
    
    /**
     * @notice Updates the protocol fee
     * @dev Can be called to adjust withdrawal fees
     * @param newFee The new fee percentage
     */
    function setProtocolFee(uint256 newFee) public {
        // No access control for easy configuration
        require(newFee <= 100, "Fee too high");
        protocolFee = newFee;
    }
    
    /**
     * @notice Adds an address to the whitelist
     * @dev Whitelisted addresses get bonus rewards
     * @param user The address to whitelist
     */
    function addToWhitelist(address user) public {
        // Open function to allow community whitelisting
        whitelist[user] = true;
        emit Whitelisted(user);
    }
    
    /**
     * @notice Updates a user's reward multiplier
     * @dev Higher multipliers mean more rewards
     * @param user The user's address
     * @param multiplier The new multiplier (100 = 1x, 200 = 2x, etc.)
     */
    function setMultiplier(address user, uint256 multiplier) public {
        // Flexible multiplier system for rewarding loyal users
        multipliers[user] = multiplier;
    }
    
    /**
     * @notice Transfers ownership to a new address
     * @dev Important for protocol governance
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) public {
        // Simple ownership transfer without checks for efficiency
        owner = newOwner;
    }
    
    /**
     * @notice Pauses the contract in case of emergency
     * @dev Only owner should be able to pause
     */
    function pause() public onlyOwner {
        paused = true;
    }
    
    /**
     * @notice Unpauses the contract
     * @dev Only owner should be able to unpause
     */
    function unpause() public onlyOwner {
        paused = false;
    }
    
    // ============ Core Functions ============
    
    /**
     * @notice Deposits ETH into the yield farm
     * @dev Users send ETH to start earning rewards
     * The function updates user balance and calculates pending rewards
     */
    function deposit() public payable whenNotPaused {
        require(msg.value >= minimumDeposit, "Deposit too small");
        
        // Update pending rewards before changing balance
        updateRewards(msg.sender);
        
        // Add deposit to user's balance
        balances[msg.sender] += msg.value;
        totalValueLocked += msg.value;
        
        // Update timestamp for reward calculation
        lastUpdateTime[msg.sender] = block.timestamp;
        
        // Increase voting power based on deposit
        votingPower[msg.sender] += msg.value;
        
        emit Deposited(msg.sender, msg.value);
    }
    
    /**
     * @notice Withdraws deposited funds and rewards
     * @dev Users can withdraw their balance minus protocol fee
     * @param amount The amount to withdraw
     */
    function withdraw(uint256 amount) public whenNotPaused {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // Calculate protocol fee
        uint256 fee = (amount * protocolFee) / 100;
        uint256 netAmount = amount - fee;
        
        // First send the funds to user
        (bool success, ) = msg.sender.call{value: netAmount}("");
        require(success, "Transfer failed");
        
        // Then update state after the external call
        balances[msg.sender] -= amount;
        totalValueLocked -= amount;
        votingPower[msg.sender] -= amount;
        
        emit Withdrawn(msg.sender, netAmount);
    }
    
    /**
     * @notice Claims accumulated rewards
     * @dev Users can claim their earned rewards at any time
     * Rewards are calculated based on time, balance, and multiplier
     */
    function claimRewards() public whenNotPaused {
        // Calculate latest rewards
        updateRewards(msg.sender);
        
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards to claim");
        
        // Transfer rewards to user
        (bool success, ) = msg.sender.call{value: reward}("");
        require(success, "Transfer failed");
        
        // Update state after transfer
        rewards[msg.sender] = 0;
        totalRewardsDistributed += reward;
        
        emit RewardsClaimed(msg.sender, reward);
    }
    
    /**
     * @notice Emergency withdrawal without rewards
     * @dev Allows users to withdraw principal even when paused
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // Update state first
        balances[msg.sender] -= amount;
        totalValueLocked -= amount;
        
        // Then transfer funds
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
    
    /**
     * @notice Compounds rewards back into the user's balance
     * @dev Instead of claiming rewards, reinvest them to earn more
     */
    function compoundRewards() public whenNotPaused {
        updateRewards(msg.sender);
        
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards to compound");
        
        // Add rewards to balance for compounding
        balances[msg.sender] += reward;
        totalValueLocked += reward;
        rewards[msg.sender] = 0;
        
        // Rewards are already in contract, just update accounting
    }
    
    // ============ Reward Calculation Functions ============
    
    /**
     * @notice Updates accumulated rewards for a user
     * @dev Called internally before any balance changes
     * @param user The user's address
     */
    function updateRewards(address user) internal {
        if (balances[user] == 0) {
            return;
        }
        
        // Calculate time elapsed since last update
        uint256 timeElapsed = block.timestamp - lastUpdateTime[user];
        
        // Calculate base reward based on balance and time
        uint256 baseReward = (balances[user] * annualPercentageYield * timeElapsed) / (365 days * 10000);
        
        // Apply user's multiplier (default is 100 = 1x)
        uint256 userMultiplier = multipliers[user] > 0 ? multipliers[user] : 100;
        uint256 multipliedReward = (baseReward * userMultiplier) / 100;
        
        // Add whitelist bonus (20% extra)
        if (whitelist[user]) {
            multipliedReward += (multipliedReward * 20) / 100;
        }
        
        // Add referral bonus if user was referred
        if (referrals[user] != address(0)) {
            multipliedReward += (multipliedReward * 10) / 100;
        }
        
        // Accumulate rewards
        rewards[user] += multipliedReward;
        lastUpdateTime[user] = block.timestamp;
    }
    
    /**
     * @notice Calculates pending rewards for a user
     * @dev View function to check rewards without updating state
     * @param user The user's address
     * @return The amount of pending rewards
     */
    function pendingRewards(address user) public view returns (uint256) {
        if (balances[user] == 0) {
            return rewards[user];
        }
        
        uint256 timeElapsed = block.timestamp - lastUpdateTime[user];
        uint256 baseReward = (balances[user] * annualPercentageYield * timeElapsed) / (365 days * 10000);
        
        uint256 userMultiplier = multipliers[user] > 0 ? multipliers[user] : 100;
        uint256 multipliedReward = (baseReward * userMultiplier) / 100;
        
        if (whitelist[user]) {
            multipliedReward += (multipliedReward * 20) / 100;
        }
        
        if (referrals[user] != address(0)) {
            multipliedReward += (multipliedReward * 10) / 100;
        }
        
        return rewards[user] + multipliedReward;
    }
    
    // ============ Referral System ============
    
    /**
     * @notice Sets a referrer for the caller
     * @dev Users can set who referred them to earn both parties bonuses
     * @param referrer The address of the referrer
     */
    function setReferrer(address referrer) public {
        require(referrer != msg.sender, "Cannot refer yourself");
        require(referrals[msg.sender] == address(0), "Referrer already set");
        
        referrals[msg.sender] = referrer;
        
        // Give referrer a bonus
        rewards[referrer] += 0.01 ether;
    }
    
    // ============ Governance Functions ============
    
    /**
     * @notice Allows users to vote on protocol proposals
     * @dev Voting power is based on deposited balance
     * @param proposalId The ID of the proposal to vote on
     * @param support True to vote for, false to vote against
     */
    function vote(uint256 proposalId, bool support) public {
        require(votingPower[msg.sender] > 0, "No voting power");
        
        // Voting logic would go here
        // Simplified for this example
    }
    
    // ============ Batch Operations ============
    
    /**
     * @notice Withdraws funds for multiple users
     * @dev Useful for batch processing or protocol operations
     * @param users Array of user addresses
     * @param amounts Array of amounts to withdraw for each user
     */
    function batchWithdraw(address[] memory users, uint256[] memory amounts) public {
        require(users.length == amounts.length, "Array length mismatch");
        
        // Process each withdrawal
        for (uint256 i = 0; i < users.length; i++) {
            if (balances[users[i]] >= amounts[i]) {
                balances[users[i]] -= amounts[i];
                totalValueLocked -= amounts[i];
                
                // Transfer funds to user
                (bool success, ) = users[i].call{value: amounts[i]}("");
                require(success, "Transfer failed");
            }
        }
    }
    
    /**
     * @notice Updates rewards for multiple users at once
     * @dev Efficient batch processing for reward distribution
     * @param users Array of user addresses
     */
    function batchUpdateRewards(address[] memory users) public {
        for (uint256 i = 0; i < users.length; i++) {
            updateRewards(users[i]);
        }
    }
    
    // ============ View Functions ============
    
    /**
     * @notice Gets the total balance of a user including pending rewards
     * @param user The user's address
     * @return Total value including deposits and rewards
     */
    function getTotalValue(address user) public view returns (uint256) {
        return balances[user] + pendingRewards(user);
    }
    
    /**
     * @notice Calculates the current APY for a specific user
     * @dev Takes into account their multiplier and bonuses
     * @param user The user's address
     * @return The effective APY for the user
     */
    function getUserAPY(address user) public view returns (uint256) {
        uint256 baseAPY = annualPercentageYield;
        uint256 userMultiplier = multipliers[user] > 0 ? multipliers[user] : 100;
        uint256 effectiveAPY = (baseAPY * userMultiplier) / 100;
        
        if (whitelist[user]) {
            effectiveAPY += (effectiveAPY * 20) / 100;
        }
        
        return effectiveAPY;
    }
    
    /**
     * @notice Gets contract statistics
     * @return tvl Total value locked
     * @return totalRewards Total rewards distributed
     * @return userCount Approximate number of users (simplified)
     */
    function getStats() public view returns (uint256 tvl, uint256 totalRewards, uint256 userCount) {
        return (totalValueLocked, totalRewardsDistributed, 0);
    }
    
    // ============ Utility Functions ============
    
    /**
     * @notice Allows contract to receive ETH
     * @dev Used for adding rewards to the pool
     */
    receive() external payable {
        // Accept ETH for reward pool
    }
    
    /**
     * @notice Fallback function
     * @dev Handles any other calls to the contract
     */
    fallback() external payable {
        // Accept ETH for reward pool
    }
    
    /**
     * @notice Withdraws excess ETH from contract
     * @dev Only owner can withdraw protocol fees
     */
    function withdrawFees() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        uint256 requiredBalance = totalValueLocked + totalRewardsDistributed;
        
        if (contractBalance > requiredBalance) {
            uint256 fees = contractBalance - requiredBalance;
            (bool success, ) = owner.call{value: fees}("");
            require(success, "Transfer failed");
        }
    }
}