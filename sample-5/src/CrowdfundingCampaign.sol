// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title CrowdfundingCampaign
 * @dev A decentralized crowdfunding platform that allows users to:
 * - Create fundraising campaigns
 * - Contribute to campaigns they support
 * - Withdraw funds once campaign goals are met
 * - Refund contributors if campaigns fail
 * 
 * This contract implements a transparent funding mechanism where campaign
 * creators can set goals and deadlines, while contributors can safely
 * fund projects they believe in with the option to get refunds if goals
 * aren't met.
 */
contract CrowdfundingCampaign {
    
    // ============ State Variables ============
    
    /// @notice Structure to hold campaign information
    /// @dev Contains all relevant data for a single campaign
    struct Campaign {
        address creator;           // Address of campaign creator
        string title;              // Campaign title
        string description;        // Detailed campaign description
        uint256 goalAmount;        // Target funding amount in wei
        uint256 deadline;          // Unix timestamp for campaign end
        uint256 fundsRaised;       // Current amount raised
        bool fundsWithdrawn;       // Whether creator has withdrawn funds
        bool active;               // Whether campaign is still active
    }
    
    /// @notice Mapping from campaign ID to Campaign struct
    /// @dev Each campaign gets a unique incrementing ID
    mapping(uint256 => Campaign) public campaigns;
    
    /// @notice Mapping from campaign ID to contributor address to contribution amount
    /// @dev Tracks how much each address contributed to each campaign
    mapping(uint256 => mapping(address => uint256)) public contributions;
    
    /// @notice Counter for total number of campaigns created
    /// @dev Increments with each new campaign, used as campaign ID
    uint256 public campaignCount;
    
    /// @notice Minimum campaign goal amount
    /// @dev Prevents creation of campaigns with trivial goals
    uint256 public constant MIN_GOAL = 0.1 ether;
    
    /// @notice Minimum campaign duration
    /// @dev Ensures campaigns run for at least this many seconds
    uint256 public constant MIN_DURATION = 1 days;
    
    /// @notice Maximum campaign duration
    /// @dev Prevents indefinite campaigns
    uint256 public constant MAX_DURATION = 90 days;
    
    /// @notice Platform fee percentage
    /// @dev Charged on successful campaigns (e.g., 2 means 2%)
    uint256 public platformFee = 2;
    
    /// @notice Address that receives platform fees
    /// @dev Set to contract deployer initially
    address public feeRecipient;
    
    // ============ Events ============
    
    /// @notice Emitted when a new campaign is created
    /// @param campaignId Unique identifier for the campaign
    /// @param creator Address of the campaign creator
    /// @param goalAmount Target funding amount
    /// @param deadline Campaign end timestamp
    event CampaignCreated(
        uint256 indexed campaignId,
        address indexed creator,
        uint256 goalAmount,
        uint256 deadline
    );
    
    /// @notice Emitted when someone contributes to a campaign
    /// @param campaignId ID of the campaign contributed to
    /// @param contributor Address of the contributor
    /// @param amount Amount contributed in wei
    event ContributionMade(
        uint256 indexed campaignId,
        address indexed contributor,
        uint256 amount
    );
    
    /// @notice Emitted when a campaign creator withdraws funds
    /// @param campaignId ID of the successful campaign
    /// @param creator Address of the creator
    /// @param amount Amount withdrawn
    event FundsWithdrawn(
        uint256 indexed campaignId,
        address indexed creator,
        uint256 amount
    );
    
    /// @notice Emitted when a contributor gets a refund
    /// @param campaignId ID of the failed campaign
    /// @param contributor Address of the contributor
    /// @param amount Amount refunded
    event RefundIssued(
        uint256 indexed campaignId,
        address indexed contributor,
        uint256 amount
    );
    
    /// @notice Emitted when a campaign is cancelled
    /// @param campaignId ID of the cancelled campaign
    event CampaignCancelled(uint256 indexed campaignId);
    
    // ============ Constructor ============
    
    /**
     * @dev Initializes the contract
     * Sets the deployer as the fee recipient
     */
    constructor() {
        feeRecipient = msg.sender;
        campaignCount = 0;
    }
    
    // ============ Modifiers ============
    
    /**
     * @dev Ensures campaign exists
     * @param _campaignId The campaign ID to check
     */
    modifier campaignExists(uint256 _campaignId) {
        require(_campaignId < campaignCount, "Campaign does not exist");
        _;
    }
    
    /**
     * @dev Ensures campaign is still active
     * @param _campaignId The campaign ID to check
     */
    modifier campaignActive(uint256 _campaignId) {
        require(campaigns[_campaignId].active, "Campaign is not active");
        _;
    }
    
    /**
     * @dev Ensures caller is the campaign creator
     * @param _campaignId The campaign ID to check
     */
    modifier onlyCreator(uint256 _campaignId) {
        require(
            msg.sender == campaigns[_campaignId].creator,
            "Only campaign creator can call this"
        );
        _;
    }
    
    // ============ Campaign Creation ============
    
    /**
     * @notice Creates a new crowdfunding campaign
     * @dev Anyone can create a campaign by specifying goal and duration
     * @param _title The campaign title
     * @param _description Detailed description of the campaign
     * @param _goalAmount Target amount to raise (in wei)
     * @param _duration Campaign duration in seconds
     * @return campaignId The ID of the newly created campaign
     */
    function createCampaign(
        string memory _title,
        string memory _description,
        uint256 _goalAmount,
        uint256 _duration
    ) public returns (uint256) {
        // Validate campaign parameters
        require(_goalAmount >= MIN_GOAL, "Goal amount too low");
        require(_duration >= MIN_DURATION, "Duration too short");
        require(_duration <= MAX_DURATION, "Duration too long");
        require(bytes(_title).length > 0, "Title cannot be empty");
        
        // Calculate deadline
        uint256 deadline = block.timestamp + _duration;
        
        // Create new campaign
        uint256 campaignId = campaignCount;
        campaigns[campaignId] = Campaign({
            creator: msg.sender,
            title: _title,
            description: _description,
            goalAmount: _goalAmount,
            deadline: deadline,
            fundsRaised: 0,
            fundsWithdrawn: false,
            active: true
        });
        
        // Increment campaign counter
        campaignCount++;
        
        emit CampaignCreated(campaignId, msg.sender, _goalAmount, deadline);
        
        return campaignId;
    }
    
    // ============ Contribution Functions ============
    
    /**
     * @notice Contribute to a campaign
     * @dev Allows anyone to contribute ETH to an active campaign
     * Contributors can contribute multiple times to the same campaign
     * @param _campaignId The ID of the campaign to contribute to
     */
    function contribute(uint256 _campaignId)
        public
        payable
        campaignExists(_campaignId)
        campaignActive(_campaignId)
    {
        Campaign storage campaign = campaigns[_campaignId];
        
        // Ensure campaign hasn't ended
        require(block.timestamp < campaign.deadline, "Campaign has ended");
        
        // Ensure contribution is positive
        require(msg.value > 0, "Contribution must be positive");
        
        // Record the contribution
        contributions[_campaignId][msg.sender] += msg.value;
        campaign.fundsRaised += msg.value;
        
        emit ContributionMade(_campaignId, msg.sender, msg.value);
    }
    
    /**
     * @notice Allows multiple contributions in a single transaction
     * @dev Batch contribution function for gas efficiency
     * @param _campaignIds Array of campaign IDs to contribute to
     * @param _amounts Array of amounts to contribute to each campaign
     */
    function batchContribute(
        uint256[] memory _campaignIds,
        uint256[] memory _amounts
    ) public payable {
        require(_campaignIds.length == _amounts.length, "Array length mismatch");
        
        uint256 totalRequired = 0;
        for (uint256 i = 0; i < _amounts.length; i++) {
            totalRequired += _amounts[i];
        }
        require(msg.value == totalRequired, "Incorrect total amount sent");
        
        // Process each contribution
        for (uint256 i = 0; i < _campaignIds.length; i++) {
            uint256 campaignId = _campaignIds[i];
            uint256 amount = _amounts[i];
            
            // Validate campaign
            require(campaignId < campaignCount, "Campaign does not exist");
            Campaign storage campaign = campaigns[campaignId];
            require(campaign.active, "Campaign is not active");
            require(block.timestamp < campaign.deadline, "Campaign has ended");
            
            // Record contribution
            contributions[campaignId][msg.sender] += amount;
            campaign.fundsRaised += amount;
            
            emit ContributionMade(campaignId, msg.sender, amount);
        }
    }
    
    // ============ Withdrawal Functions ============
    
    /**
     * @notice Allows campaign creator to withdraw funds if goal is met
     * @dev Creator can only withdraw if:
     * - Campaign deadline has passed
     * - Goal amount was reached
     * - Funds haven't been withdrawn yet
     * 
     * Platform fee is automatically deducted from the withdrawal
     * @param _campaignId The ID of the successful campaign
     */
    function withdrawFunds(uint256 _campaignId)
        public
        campaignExists(_campaignId)
        onlyCreator(_campaignId)
    {
        Campaign storage campaign = campaigns[_campaignId];
        
        // Ensure campaign has ended
        require(block.timestamp >= campaign.deadline, "Campaign still active");
        
        // Ensure goal was met
        require(
            campaign.fundsRaised >= campaign.goalAmount,
            "Funding goal not reached"
        );
        
        // Ensure funds haven't been withdrawn yet
        require(!campaign.fundsWithdrawn, "Funds already withdrawn");
        
        // Calculate amounts
        uint256 totalFunds = campaign.fundsRaised;
        uint256 fee = (totalFunds * platformFee) / 100;
        uint256 creatorAmount = totalFunds - fee;
        
        // Mark funds as withdrawn before transferring
        // This is the CORRECT pattern to prevent reentrancy
        campaign.fundsWithdrawn = true;
        campaign.active = false;
        
        // Transfer funds to creator
        (bool successCreator, ) = payable(campaign.creator).call{value: creatorAmount}("");
        require(successCreator, "Transfer to creator failed");
        
        // Transfer fee to platform
        (bool successFee, ) = payable(feeRecipient).call{value: fee}("");
        require(successFee, "Transfer of fee failed");
        
        emit FundsWithdrawn(_campaignId, campaign.creator, creatorAmount);
    }
    
    // ============ Refund Functions ============
    
    /**
     * @notice Allows contributors to get refunds if campaign fails
     * @dev Contributors can claim refunds if:
     * - Campaign deadline has passed
     * - Goal was not reached
     * - They have a positive contribution balance
     * 
     * THE VULNERABILITY IS HERE - This function has a reentrancy bug!
     * The external call happens BEFORE state updates, allowing malicious
     * contracts to recursively call this function and drain funds.
     * 
     * @param _campaignId The ID of the failed campaign
     */
    function claimRefund(uint256 _campaignId)
        public
        campaignExists(_campaignId)
    {
        Campaign storage campaign = campaigns[_campaignId];
        
        // Ensure campaign has ended
        require(block.timestamp >= campaign.deadline, "Campaign still active");
        
        // Ensure goal was NOT reached
        require(
            campaign.fundsRaised < campaign.goalAmount,
            "Campaign was successful, no refunds"
        );
        
        // Get contributor's contribution amount
        uint256 contributionAmount = contributions[_campaignId][msg.sender];
        require(contributionAmount > 0, "No contribution to refund");
        
        // VULNERABILITY: External call before state update
        // An attacker can create a malicious contract that calls claimRefund
        // again in its receive() or fallback() function, draining the contract
        (bool success, ) = payable(msg.sender).call{value: contributionAmount}("");
        require(success, "Refund transfer failed");
        
        // State update happens AFTER the external call
        // By this time, an attacker may have already called this function
        // multiple times recursively
        contributions[_campaignId][msg.sender] = 0;
        
        emit RefundIssued(_campaignId, msg.sender, contributionAmount);
    }
    
    /**
     * @notice Allows batch refund claims for multiple campaigns
     * @dev Contributors can claim refunds from multiple failed campaigns at once
     * @param _campaignIds Array of campaign IDs to claim refunds from
     */
    function batchClaimRefund(uint256[] memory _campaignIds) public {
        for (uint256 i = 0; i < _campaignIds.length; i++) {
            uint256 campaignId = _campaignIds[i];
            
            // Check if refund is possible
            if (campaignId < campaignCount) {
                Campaign storage campaign = campaigns[campaignId];
                
                if (
                    block.timestamp >= campaign.deadline &&
                    campaign.fundsRaised < campaign.goalAmount &&
                    contributions[campaignId][msg.sender] > 0
                ) {
                    // Process refund
                    uint256 amount = contributions[campaignId][msg.sender];
                    contributions[campaignId][msg.sender] = 0;
                    
                    (bool success, ) = payable(msg.sender).call{value: amount}("");
                    require(success, "Refund transfer failed");
                    
                    emit RefundIssued(campaignId, msg.sender, amount);
                }
            }
        }
    }
    
    // ============ Campaign Management ============
    
    /**
     * @notice Allows creator to cancel campaign before deadline
     * @dev Creator can cancel their own campaign, triggering refunds
     * Can only be called before the deadline
     * @param _campaignId The ID of the campaign to cancel
     */
    function cancelCampaign(uint256 _campaignId)
        public
        campaignExists(_campaignId)
        onlyCreator(_campaignId)
        campaignActive(_campaignId)
    {
        Campaign storage campaign = campaigns[_campaignId];
        
        // Can only cancel before deadline
        require(block.timestamp < campaign.deadline, "Campaign already ended");
        
        // Mark campaign as inactive
        campaign.active = false;
        
        emit CampaignCancelled(_campaignId);
    }
    
    // ============ View Functions ============
    
    /**
     * @notice Gets detailed information about a campaign
     * @param _campaignId The campaign ID to query
     * @return creator Address of campaign creator
     * @return title Campaign title
     * @return description Campaign description
     * @return goalAmount Target funding amount
     * @return deadline Campaign end timestamp
     * @return fundsRaised Current amount raised
     * @return fundsWithdrawn Whether funds have been withdrawn
     * @return active Whether campaign is active
     */
    function getCampaignInfo(uint256 _campaignId)
        public
        view
        campaignExists(_campaignId)
        returns (
            address creator,
            string memory title,
            string memory description,
            uint256 goalAmount,
            uint256 deadline,
            uint256 fundsRaised,
            bool fundsWithdrawn,
            bool active
        )
    {
        Campaign storage campaign = campaigns[_campaignId];
        return (
            campaign.creator,
            campaign.title,
            campaign.description,
            campaign.goalAmount,
            campaign.deadline,
            campaign.fundsRaised,
            campaign.fundsWithdrawn,
            campaign.active
        );
    }
    
    /**
     * @notice Checks if a campaign has reached its goal
     * @param _campaignId The campaign ID to check
     * @return bool True if goal is reached, false otherwise
     */
    function isGoalReached(uint256 _campaignId)
        public
        view
        campaignExists(_campaignId)
        returns (bool)
    {
        Campaign storage campaign = campaigns[_campaignId];
        return campaign.fundsRaised >= campaign.goalAmount;
    }
    
    /**
     * @notice Gets the contribution amount for a specific contributor
     * @param _campaignId The campaign ID
     * @param _contributor The contributor's address
     * @return uint256 The amount contributed
     */
    function getContribution(uint256 _campaignId, address _contributor)
        public
        view
        returns (uint256)
    {
        return contributions[_campaignId][_contributor];
    }
    
    /**
     * @notice Calculates time remaining for a campaign
     * @param _campaignId The campaign ID
     * @return uint256 Seconds remaining, or 0 if ended
     */
    function getTimeRemaining(uint256 _campaignId)
        public
        view
        campaignExists(_campaignId)
        returns (uint256)
    {
        Campaign storage campaign = campaigns[_campaignId];
        if (block.timestamp >= campaign.deadline) {
            return 0;
        }
        return campaign.deadline - block.timestamp;
    }
    
    /**
     * @notice Calculates funding progress percentage
     * @param _campaignId The campaign ID
     * @return uint256 Percentage of goal reached (0-100+)
     */
    function getFundingProgress(uint256 _campaignId)
        public
        view
        campaignExists(_campaignId)
        returns (uint256)
    {
        Campaign storage campaign = campaigns[_campaignId];
        if (campaign.goalAmount == 0) return 0;
        return (campaign.fundsRaised * 100) / campaign.goalAmount;
    }
    
    // ============ Administrative Functions ============
    
    /**
     * @notice Updates the platform fee percentage
     * @dev Only fee recipient can update the fee
     * @param _newFee The new fee percentage (0-100)
     */
    function updatePlatformFee(uint256 _newFee) public {
        require(msg.sender == feeRecipient, "Only fee recipient can update");
        require(_newFee <= 10, "Fee cannot exceed 10%");
        platformFee = _newFee;
    }
    
    /**
     * @notice Updates the fee recipient address
     * @dev Only current fee recipient can change it
     * @param _newRecipient The new fee recipient address
     */
    function updateFeeRecipient(address _newRecipient) public {
        require(msg.sender == feeRecipient, "Only fee recipient can update");
        require(_newRecipient != address(0), "Invalid address");
        feeRecipient = _newRecipient;
    }
    
    /**
     * @notice Gets the total contract balance
     * @return uint256 The contract's ETH balance
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}