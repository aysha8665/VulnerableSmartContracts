// File: ILendingProtocol.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ILendingProtocol
 * @notice Interface for the lending protocol contract
 * @dev Defines core functionality for lending, borrowing, and collateral management
 */
interface ILendingProtocol {
    /**
     * @notice Deposits collateral into the protocol
     */
    function depositCollateral() external payable;
    
    /**
     * @notice Borrows funds against deposited collateral
     * @param amount The amount to borrow in wei
     */
    function borrow(uint256 amount) external;
    
    /**
     * @notice Repays a loan and retrieves collateral
     * @param loanId The ID of the loan to repay
     */
    function repayLoan(uint256 loanId) external payable;
    
    /**
     * @notice Withdraws excess collateral after partial loan repayment
     * @param loanId The ID of the loan
     * @param amount The amount of collateral to withdraw
     */
    function withdrawCollateral(uint256 loanId, uint256 amount) external;
    
    /**
     * @notice Returns the collateral balance of a user
     * @param user The address to query
     * @return The collateral balance in wei
     */
    function getCollateralBalance(address user) external view returns (uint256);
    
    /**
     * @notice Returns loan details for a specific loan ID
     * @param loanId The loan ID to query
     * @return borrower The address of the borrower
     * @return principal The principal amount borrowed
     * @return collateral The collateral amount locked
     * @return isActive Whether the loan is still active
     */
    function getLoanDetails(uint256 loanId) external view returns (
        address borrower,
        uint256 principal,
        uint256 collateral,
        bool isActive
    );
}