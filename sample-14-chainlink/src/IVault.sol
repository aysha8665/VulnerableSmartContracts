// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IVault
 * @dev Interface for the EtherVault contract defining core interaction points.
 */
interface IVault {
    /**
     * @dev Emitted when a user deposits ETH into the vault.
     * @param user The address of the depositor.
     * @param amount The amount of ETH deposited.
     */
    event UserDeposit(address indexed user, uint256 amount);

    /**
     * @dev Emitted when a user withdraws ETH from the vault.
     * @param user The address of the withdrawer.
     * @param amount The amount of ETH withdrawn.
     * @param usdValueAtTime The approximate USD value of the withdrawal based on oracle data.
     */
    event UserWithdrawal(address indexed user, uint256 amount, int256 usdValueAtTime);

    /**
     * @dev Allows a user to deposit ETH.
     */
    function depositETH() external payable;

    /**
     * @dev Allows a user to withdraw a specific amount of ETH.
     * @param amount The amount of Wei to withdraw.
     */
    function withdrawETH(uint256 amount) external;

    /**
     * @dev Returns the current ETH balance of the caller.
     */
    function getMyBalance() external view returns (uint256);
}