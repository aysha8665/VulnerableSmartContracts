// File: Vault.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IVault.sol";
import "./Ownable.sol";

/**
 * @title Vault
 * @notice A simple vault contract for depositing and withdrawing ETH
 * @dev Inherits from Ownable for access control, implements IVault interface
 */
contract Vault is IVault, Ownable {
    mapping(address => uint256) private balances;
    
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    
    /**
     * @notice Allows users to deposit ETH into their vault balance
     * @dev Updates the user's balance with the sent value
     */
    function deposit() external payable override {
        require(msg.value > 0, "Vault: deposit amount must be greater than 0");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }
    
    /**
     * @notice Allows users to withdraw their entire balance from the vault
     * @dev Sends the user's balance back to them via a call
     */
    function withdraw() external override {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "Vault: insufficient balance");
        
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Vault: transfer failed");
        
        balances[msg.sender] = 0;
    }
    
    /**
     * @notice Returns the balance of a specific user
     * @param user The address to query
     * @return The user's balance in wei
     */
    function getBalance(address user) external view override returns (uint256) {
        return balances[user];
    }
    
    /**
     * @notice Allows the owner to withdraw contract funds in case of emergency
     * @dev Only callable by the contract owner
     */
    function emergencyWithdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Vault: emergency withdrawal failed");
    }
}