// File: Interface.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IVault
 * @notice Interface defining the required functions for a basic vault contract.
 */
interface IVault {
    /**
     * @notice Allows a user to deposit Ether into the vault.
     */
    function deposit() external payable;

    /**
     * @notice Allows the contract owner to withdraw all held Ether.
     * @param _amount The amount of Ether to withdraw.
     */
    function withdrawAll(uint256 _amount) external;

    /**
     * @notice Returns the current balance of the contract.
     * @return The contract's Ether balance.
     */
    function getBalance() external view returns (uint256);
}