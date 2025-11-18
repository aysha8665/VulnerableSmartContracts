// File: UnsafeBank.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IBank.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using OpenZeppelin

/**
 * @title UnsafeBank
 * @dev A simple Ether bank that allows deposits and withdrawals.
 * Inherits from Ownable to manage ownership.
 */
contract UnsafeBank is IBank, Ownable {
    // Mapping from user address to their balance
    mapping(address => uint256) public balances;

    /**
     * @dev Sets the deployer as the initial owner.
     * This constructor now correctly calls the Ownable constructor.
     */
    constructor() Ownable(msg.sender) {
        // The deployer of UnsafeBank is set as the owner
    }

    /**
     * @dev Allows a user to deposit Ether.
     */
    function deposit() external payable override {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Allows a user to withdraw their entire balance.
     * This function contains the reentrancy vulnerability.
     */
    function withdraw() external override {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance to withdraw");

        // Vulnerability: External call is made *before* updating the user's balance.
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        // State update happens *after* the external call
        balances[msg.sender] = 0;

        emit Withdrawal(msg.sender, amount);
    }

    /**
     * @dev Returns the balance of a specific user.
     * @param user The address to query.
     * @return The balance in wei.
     */
    function getBalance(address user) external view override returns (uint256) {
        return balances[user];
    }

    /**
     * @dev Fallback function to receive Ether.
     */
    receive() external payable {}
}