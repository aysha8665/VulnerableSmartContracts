// File: Logger.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Logger
 * @dev A simple utility contract to log actions from other contracts.
 * This contract is owned by the contract that deploys it.
 */
contract Logger {
    address public owner;

    /**
     * @dev Sets the deploying address as the owner.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Modifier to ensure only the owner can call a function.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Logger: Caller is not the owner");
        _;
    }

    /**
     * @dev Logs a generic message. Only callable by the owner.
     * @param message The message to log.
     */
    function logAction(string memory message) external onlyOwner {
        // In a real implementation, this would emit an event
        // or write to storage. For this example, it does nothing
        // to save gas and complexity.
    }
}