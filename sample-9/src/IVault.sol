// File: IVault.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IVault
 * @notice Interface for the vault contract
 * @dev Defines the core functionality for deposit and withdrawal operations
 */
interface IVault {
    /**
     * @notice Deposits ETH into the vault for the caller
     */
    function deposit() external payable;
    
    /**
     * @notice Withdraws the caller's balance from the vault
     */
    function withdraw() external;
    
    /**
     * @notice Returns the balance of a specific user
     * @param user The address to query
     * @return The balance in wei
     */
    function getBalance(address user) external view returns (uint256);
}