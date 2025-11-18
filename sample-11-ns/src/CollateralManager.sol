// File: CollateralManager.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title CollateralManager
 * @notice Manages collateral calculations and validation for the lending protocol
 * @dev Provides utility functions for collateral ratio checks and computations
 */
contract CollateralManager {
    uint256 public constant COLLATERAL_RATIO = 150; // 150% collateralization required
    uint256 public constant RATIO_DENOMINATOR = 100;
    uint256 public constant MIN_COLLATERAL = 0.01 ether;
    
    /**
     * @notice Calculates the maximum borrowable amount based on collateral
     * @param collateralAmount The amount of collateral deposited
     * @return The maximum amount that can be borrowed
     */
    function calculateMaxBorrow(uint256 collateralAmount) public pure returns (uint256) {
        return (collateralAmount * RATIO_DENOMINATOR) / COLLATERAL_RATIO;
    }
    
    /**
     * @notice Calculates the required collateral for a given borrow amount
     * @param borrowAmount The amount to borrow
     * @return The required collateral amount
     */
    function calculateRequiredCollateral(uint256 borrowAmount) public pure returns (uint256) {
        return (borrowAmount * COLLATERAL_RATIO) / RATIO_DENOMINATOR;
    }
    
    /**
     * @notice Validates if a borrow amount is safe given the collateral
     * @param collateralAmount The collateral deposited
     * @param borrowAmount The amount to borrow
     * @return True if the borrow is safe
     */
    function isValidBorrow(uint256 collateralAmount, uint256 borrowAmount) public pure returns (bool) {
        if (collateralAmount < MIN_COLLATERAL) return false;
        uint256 maxBorrow = calculateMaxBorrow(collateralAmount);
        return borrowAmount <= maxBorrow;
    }
    
    /**
     * @notice Calculates excess collateral that can be withdrawn
     * @param totalCollateral The total collateral locked
     * @param outstandingDebt The remaining debt amount
     * @return The amount of excess collateral available for withdrawal
     */
    function calculateExcessCollateral(
        uint256 totalCollateral,
        uint256 outstandingDebt
    ) public pure returns (uint256) {
        uint256 requiredCollateral = calculateRequiredCollateral(outstandingDebt);
        if (totalCollateral <= requiredCollateral) return 0;
        return totalCollateral - requiredCollateral;
    }
}