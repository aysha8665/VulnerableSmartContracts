// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ILotteryVault.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title LotteryVault
 * @notice Secure vault for holding lottery funds and distributing prizes
 * @dev Implements ILotteryVault with access control and reentrancy protection
 */
contract LotteryVault is ILotteryVault, Ownable, ReentrancyGuard {
    // Address of the authorized lottery contract
    address public lotteryContract;
    
    // Total amount deposited into the vault
    uint256 public totalDeposited;
    
    // Events for tracking vault operations
    event Deposited(uint256 amount, uint256 timestamp);
    event PrizeWithdrawn(address indexed winner, uint256 amount, uint256 timestamp);
    event LotteryContractUpdated(address indexed oldContract, address indexed newContract);
    
    /**
     * @notice Restricts function access to only the lottery contract
     */
    modifier onlyLottery() {
        require(msg.sender == lotteryContract, "Only lottery contract can call");
        _;
    }
    
    /**
     * @notice Initializes the vault with the deployer as owner
     */
    constructor() Ownable(msg.sender) {
        // Vault is ready to receive deposits
    }
    
    /**
     * @notice Sets the authorized lottery contract address
     * @param _lotteryContract Address of the lottery contract
     * @dev Only owner can set the lottery contract
     */
    function setLotteryContract(address _lotteryContract) external onlyOwner {
        require(_lotteryContract != address(0), "Invalid lottery contract");
        address oldContract = lotteryContract;
        lotteryContract = _lotteryContract;
        emit LotteryContractUpdated(oldContract, _lotteryContract);
    }
    
    /**
     * @notice Deposits funds into the vault from lottery ticket sales
     * @dev Accepts ETH and updates total deposited amount
     */
    function deposit() external payable override onlyLottery {
        require(msg.value > 0, "Must deposit positive amount");
        totalDeposited += msg.value;
        emit Deposited(msg.value, block.timestamp);
    }
    
    /**
     * @notice Withdraws the prize amount to the winner
     * @param winner Address of the lottery winner
     * @param amount Amount to transfer to the winner
     * @dev Protected against reentrancy attacks
     */
    function withdrawPrize(address winner, uint256 amount) external override onlyLottery nonReentrant {
        require(winner != address(0), "Invalid winner address");
        require(amount <= address(this).balance, "Insufficient vault balance");
        
        (bool success, ) = payable(winner).call{value: amount}("");
        require(success, "Prize transfer failed");
        
        emit PrizeWithdrawn(winner, amount, block.timestamp);
    }
    
    /**
     * @notice Returns the current balance held in the vault
     * @return The vault balance in wei
     */
    function getBalance() external view override returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @notice Allows the contract to receive ETH directly
     */
    receive() external payable {
        totalDeposited += msg.value;
        emit Deposited(msg.value, block.timestamp);
    }
}