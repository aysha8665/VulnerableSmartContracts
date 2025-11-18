// File: IBank.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IBank Interface
 * @dev Defines the external functions for the bank contract.
 */
interface IBank {
    /**
     * @dev Emitted when a user deposits Ether.
     * @param user The address of the depositor.
     * @param amount The amount deposited.
     */
    event Deposit(address indexed user, uint256 amount);

    /**
     * @dev Emitted when a user withdraws Ether.
     * @param user The address of the withdrawer.
     * @param amount The amount withdrawn.
     */
    event Withdrawal(address indexed user, uint256 amount);

    /**
     * @dev Allows a user to deposit Ether into their account.
     */
    function deposit() external payable;

    /**
     * @dev Allows a user to withdraw their entire balance.
     */
    function withdraw() external;

    /**
     * @dev Returns the balance of a specific user.
     * @param user The address to query.
     * @return The balance in wei.
     */
    function getBalance(address user) external view returns (uint256);
}