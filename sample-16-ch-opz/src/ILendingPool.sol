// File: ILendingPool.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ILendingPool
 * @dev Interface defining the core lending pool functionality
 * This interface establishes the contract for deposit, withdrawal, and borrowing operations
 */
interface ILendingPool {
    /**
     * @dev Emitted when a user deposits collateral into the pool
     * @param user Address of the depositor
     * @param amount Amount of ETH deposited
     */
    event CollateralDeposited(address indexed user, uint256 amount);
    
    /**
     * @dev Emitted when a user withdraws their collateral
     * @param user Address of the withdrawer
     * @param amount Amount of ETH withdrawn
     */
    event CollateralWithdrawn(address indexed user, uint256 amount);
    
    /**
     * @dev Emitted when a user borrows tokens against their collateral
     * @param user Address of the borrower
     * @param amount Amount of tokens borrowed
     */
    event TokensBorrowed(address indexed user, uint256 amount);
    
    /**
     * @dev Allows users to deposit ETH as collateral
     */
    function depositCollateral() external payable;
    
    /**
     * @dev Allows users to withdraw their deposited collateral
     * @param amount Amount of collateral to withdraw
     */
    function withdrawCollateral(uint256 amount) external;
    
    /**
     * @dev Allows users to borrow tokens against their collateral
     * @param amount Amount of tokens to borrow
     */
    function borrow(uint256 amount) external;
    
    /**
     * @dev Returns the collateral balance of a user
     * @param user Address to query
     * @return Current collateral balance
     */
    function getCollateralBalance(address user) external view returns (uint256);
}