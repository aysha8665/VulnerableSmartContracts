// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./RandomnessConsumer.sol";
import "./ILotteryVault.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DecentralizedLottery
 * @notice A decentralized lottery system with VRF-based random winner selection
 * @dev Inherits from RandomnessConsumer for verifiable randomness and uses vault for fund management
 */
contract DecentralizedLottery is RandomnessConsumer, Pausable, Ownable {
    // Lottery configuration
    uint256 public ticketPrice;
    uint256 public lotteryDuration;
    uint256 public currentRound;
    
    // Vault contract for holding funds
    ILotteryVault public vault;
    
    // Round structure
    struct Round {
        uint256 startTime;
        uint256 endTime;
        address[] participants;
        address winner;
        uint256 prizePool;
        bool finalized;
    }
    
    // Mapping of round number to round data
    mapping(uint256 => Round) public rounds;
    
    // Mapping of request ID to round number
    mapping(bytes32 => uint256) private requestIdToRound;
    
    // Events
    event TicketPurchased(address indexed player, uint256 indexed round, uint256 timestamp);
    event LotteryStarted(uint256 indexed round, uint256 startTime, uint256 endTime);
    event WinnerSelected(uint256 indexed round, address indexed winner, uint256 prize);
    event RoundFinalized(uint256 indexed round, uint256 timestamp);
    
    /**
     * @notice Initializes the lottery with VRF configuration and parameters
     * @param _vrfCoordinator Chainlink VRF coordinator address
     * @param _link LINK token address
     * @param _keyHash VRF key hash
     * @param _fee VRF fee in LINK
     * @param _ticketPrice Price per lottery ticket in wei
     * @param _lotteryDuration Duration of each lottery round in seconds
     * @param _vaultAddress Address of the lottery vault contract
     */
    constructor(
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee,
        uint256 _ticketPrice,
        uint256 _lotteryDuration,
        address _vaultAddress
    ) RandomnessConsumer(_vrfCoordinator, _link, _keyHash, _fee) Ownable(msg.sender) {
        require(_ticketPrice > 0, "Ticket price must be positive");
        require(_lotteryDuration > 0, "Duration must be positive");
        require(_vaultAddress != address(0), "Invalid vault address");
        
        ticketPrice = _ticketPrice;
        lotteryDuration = _lotteryDuration;
        vault = ILotteryVault(_vaultAddress);
        currentRound = 0;
    }
    
    /**
     * @notice Starts a new lottery round
     * @dev Can only be called when no active round exists
     */
    function startLottery() external onlyOwner whenNotPaused {
        require(currentRound == 0 || rounds[currentRound].finalized, "Round already active");
        
        currentRound++;
        Round storage newRound = rounds[currentRound];
        newRound.startTime = block.timestamp;
        newRound.endTime = block.timestamp + lotteryDuration;
        newRound.prizePool = 0;
        newRound.finalized = false;
        
        emit LotteryStarted(currentRound, newRound.startTime, newRound.endTime);
    }
    
    /**
     * @notice Allows players to purchase lottery tickets
     * @dev Accepts exact ticket price and adds player to current round
     */
    function buyTicket() external payable whenNotPaused {
        require(currentRound > 0, "No active lottery");
        Round storage round = rounds[currentRound];
        require(block.timestamp >= round.startTime && block.timestamp <= round.endTime, "Lottery not active");
        require(msg.value == ticketPrice, "Incorrect ticket price");
        
        round.participants.push(msg.sender);
        round.prizePool += msg.value;
        
        vault.deposit{value: msg.value}();
        
        emit TicketPurchased(msg.sender, currentRound, block.timestamp);
    }
    
    /**
     * @notice Draws the lottery winner using VRF randomness
     * @dev Can only be called after lottery end time and before finalization
     */
    function drawWinner() external onlyOwner whenNotPaused {
        Round storage round = rounds[currentRound];
        require(block.timestamp > round.endTime, "Lottery still active");
        require(!round.finalized, "Round already finalized");
        require(round.participants.length > 0, "No participants");
        
        bytes32 requestId = requestRandomness();
        requestIdToRound[requestId] = currentRound;
    }
    
    /**
     * @notice Manually finalizes a round with a given winner index (emergency function)
     * @param roundNumber The round to finalize
     * @param winnerIndex The index of the winner in the participants array
     * @dev Allows owner to finalize round without VRF in case of VRF failure
     */
    function emergencyFinalizeRound(uint256 roundNumber, uint256 winnerIndex) external onlyOwner {
        Round storage round = rounds[roundNumber];
        require(block.timestamp > round.endTime, "Lottery still active");
        require(!round.finalized, "Round already finalized");
        require(round.participants.length > 0, "No participants");
        require(winnerIndex < round.participants.length, "Invalid winner index");
        
        address winner = round.participants[winnerIndex];
        round.winner = winner;
        
        // VULNERABILITY: External call before state change
        vault.withdrawPrize(winner, round.prizePool);
        
        round.finalized = true;
        
        emit WinnerSelected(roundNumber, winner, round.prizePool);
        emit RoundFinalized(roundNumber, block.timestamp);
    }
    
    /**
     * @notice Processes VRF randomness to select winner and distribute prize
     * @param requestId The VRF request ID
     * @param randomness The random number from VRF
     * @dev Internal function called by VRF callback
     */
    function processRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 roundNumber = requestIdToRound[requestId];
        Round storage round = rounds[roundNumber];
        
        require(!round.finalized, "Round already finalized");
        
        uint256 winnerIndex = randomness % round.participants.length;
        address winner = round.participants[winnerIndex];
        round.winner = winner;
        
        vault.withdrawPrize(winner, round.prizePool);
        
        round.finalized = true;
        
        emit WinnerSelected(roundNumber, winner, round.prizePool);
        emit RoundFinalized(roundNumber, block.timestamp);
    }
    
    /**
     * @notice Returns the list of participants in a specific round
     * @param roundNumber The round number to query
     * @return Array of participant addresses
     */
    function getRoundParticipants(uint256 roundNumber) external view returns (address[] memory) {
        return rounds[roundNumber].participants;
    }
    
    /**
     * @notice Pauses the lottery (emergency function)
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @notice Unpauses the lottery
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @notice Updates the ticket price
     * @param newPrice New ticket price in wei
     */
    function setTicketPrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Price must be positive");
        ticketPrice = newPrice;
    }
}