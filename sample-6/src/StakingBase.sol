/**
 * @title StakingBase
 * @dev Intermediate contract that adds staking functionality
 * 
 * This contract extends RewardPool and adds the ability for users to:
 * - Stake tokens/ETH
 * - Track staking balances
 * - Calculate staking duration
 * 
 * It provides the staking infrastructure that the final implementation
 * will use to determine reward distribution.
 */
 import "./RewardPool.sol";
contract StakingBase is RewardPool {
    
    // ============ State Variables ============
    
    /// @notice Mapping of user addresses to their staked amounts
    /// @dev Tracks how much each user has staked
    mapping(address => uint256) public stakedBalances;
    
    /// @notice Mapping of user addresses to their stake timestamp
    /// @dev Records when each user last staked or updated their stake
    mapping(address => uint256) public stakeTimestamp;
    
    /// @notice Total amount staked across all users
    /// @dev Sum of all user stakes
    uint256 public totalStaked;
    
    /// @notice Minimum stake amount required
    /// @dev Prevents dust stakes
    uint256 public constant MIN_STAKE = 0.01 ether;
    
    // ============ Events ============
    
    /// @notice Emitted when a user stakes tokens
    /// @param user Address of the staker
    /// @param amount Amount staked
    event Staked(address indexed user, uint256 amount);
    
    /// @notice Emitted when a user unstakes tokens
    /// @param user Address of the staker
    /// @param amount Amount unstaked
    event Unstaked(address indexed user, uint256 amount);
    
    // ============ Staking Functions ============
    
    /**
     * @notice Allows users to stake ETH
     * @dev Users send ETH to this function to stake
     * Staking starts earning rewards immediately
     */
    function stake() public payable {
        require(msg.value >= MIN_STAKE, "Stake amount too low");
        
        // If user has existing stake, calculate and add pending rewards
        if (stakedBalances[msg.sender] > 0) {
            _calculateAndAddRewards(msg.sender);
        }
        
        // Update stake balance
        stakedBalances[msg.sender] += msg.value;
        totalStaked += msg.value;
        
        // Update timestamp
        stakeTimestamp[msg.sender] = block.timestamp;
        
        emit Staked(msg.sender, msg.value);
    }
    
    /**
     * @notice Internal function to calculate and add rewards based on stake
     * @dev Called when updating stakes to ensure rewards are calculated
     * Uses a simple time-based calculation
     * @param _user The user to calculate rewards for
     */
    function _calculateAndAddRewards(address _user) internal {
        uint256 stakedAmount = stakedBalances[_user];
        if (stakedAmount == 0) return;
        
        // Calculate time staked
        uint256 timeStaked = block.timestamp - stakeTimestamp[_user];
        
        // Simple reward calculation: 10% APY
        // Formula: (staked * time * rate) / (365 days * 100)
        uint256 reward = (stakedAmount * timeStaked * 10) / (365 days * 100);
        
        if (reward > 0) {
            _addRewards(_user, reward);
        }
    }
    
    // ============ View Functions ============
    
    /**
     * @notice Gets the staked balance of a user
     * @param _user The user's address
     * @return The amount staked by the user
     */
    function getStakedBalance(address _user) public view returns (uint256) {
        return stakedBalances[_user];
    }
    
    /**
     * @notice Calculates current pending rewards for a user
     * @dev View function that doesn't modify state
     * @param _user The user's address
     * @return Total pending rewards including accumulated and current
     */
    function calculatePendingRewards(address _user) public view returns (uint256) {
        uint256 stakedAmount = stakedBalances[_user];
        if (stakedAmount == 0) return rewards[_user];
        
        uint256 timeStaked = block.timestamp - stakeTimestamp[_user];
        uint256 newReward = (stakedAmount * timeStaked * 10) / (365 days * 100);
        
        return rewards[_user] + newReward;
    }
}