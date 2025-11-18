// File: UnsafeBank.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IBank.sol";
// import "./Logger.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title UnsafeBank
 * @dev A simple Ether bank that allows deposits and withdrawals.
 * This contract uses a Logger contract to log its actions.
 */
contract UnsafeBank is IBank, Ownable {
    // Mapping from user address to their balance
    mapping(address => uint256) public balances;

    // Address of the logging contract
    // Logger public logger;

    /**
     * @dev Deploys a new Logger contract and sets it.
     */
    constructor() {
        // logger = new Logger();
        // The Ownable constructor is called implicitly
    }

    /**
     * @dev Allows a user to deposit Ether.
     * Logs the action using the Logger contract.
     */
    function deposit() external payable override {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        balances[msg.sender] += msg.value;
        // logger.logAction("Deposit");
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Allows a user to withdraw their entire balance.
     * Logs the action using the Logger contract.
     */
    function withdraw() external override {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance to withdraw");

        // Send the Ether to the user
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        // Update the user's balance after sending
        balances[msg.sender] = 0;

        // logger.logAction("Withdrawal");
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
     * @dev Fallback function to receive Ether (e.g., from an attack).
     */
    receive() external payable {}
}