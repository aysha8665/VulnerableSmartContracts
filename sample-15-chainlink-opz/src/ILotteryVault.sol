// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ILotteryVault
 * @notice Interface for the vault that holds lottery funds and manages prize distribution
 * @dev Defines the core vault operations for the lottery system
 */
interface ILotteryVault {
    /**
     * @notice Deposits funds into the vault from lottery ticket sales
     * @dev Called by the lottery contract when tickets are purchased
     */
    function deposit() external payable;
    
    /**
     * @notice Withdraws the prize amount to the winner
     * @param winner Address of the lottery winner
     * @param amount Amount to transfer to the winner
     * @dev Only callable by authorized lottery contract
     */
    function withdrawPrize(address winner, uint256 amount) external;
    
    /**
     * @notice Returns the current balance held in the vault
     * @return The vault balance in wei
     */
    function getBalance() external view returns (uint256);
}