// File: LendingPool.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ILendingPool.sol";
import "./PriceOracle.sol";
import "./LendingToken.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title LendingPool
 * @dev Main lending pool contract that manages collateral deposits and token borrowing
 * Inherits from PriceOracle for price feed functionality and implements ILendingPool
 * Users can deposit ETH as collateral and borrow tokens based on collateralization ratio
 */
contract LendingPool is ILendingPool, PriceOracle, ReentrancyGuard {
    LendingToken public lendingToken;
    
    // Collateralization ratio: 150% (must have $1.50 in collateral for every $1 borrowed)
    uint256 public constant COLLATERAL_RATIO = 150;
    
    // Mapping to track user collateral balances
    mapping(address => uint256) public collateralBalances;
    
    // Mapping to track user borrowed amounts
    mapping(address => uint256) public borrowedAmounts;
    
    /**
     * @dev Constructor initializes the lending pool with required dependencies
     * @param _priceFeed Address of the Chainlink price feed for ETH/USD
     * @param _lendingToken Address of the lending token contract
     */
    constructor(address _priceFeed, address _lendingToken) PriceOracle(_priceFeed) {
        lendingToken = LendingToken(_lendingToken);
    }
    
    /**
     * @dev Allows users to deposit ETH as collateral into the pool
     * Emits CollateralDeposited event upon success
     */
    function depositCollateral() external payable override {
        require(msg.value > 0, "Must deposit non-zero amount");
        
        collateralBalances[msg.sender] += msg.value;
        
        emit CollateralDeposited(msg.sender, msg.value);
    }
    
    /**
     * @dev Allows users to withdraw their collateral from the pool
     * Ensures the user maintains sufficient collateralization after withdrawal
     * @param amount Amount of collateral (in wei) to withdraw
     */
    function withdrawCollateral(uint256 amount) external override {
        require(amount > 0, "Withdrawal amount must be positive");
        require(collateralBalances[msg.sender] >= amount, "Insufficient collateral balance");
        
        // Calculate remaining collateral after withdrawal
        uint256 remainingCollateral = collateralBalances[msg.sender] - amount;
        
        // If user has borrowed tokens, ensure they maintain collateralization ratio
        if (borrowedAmounts[msg.sender] > 0) {
            uint256 remainingCollateralValue = getEthValueInUSD(remainingCollateral);
            uint256 requiredCollateral = (borrowedAmounts[msg.sender] * COLLATERAL_RATIO) / 100;
            
            require(
                remainingCollateralValue >= requiredCollateral,
                "Withdrawal would under-collateralize position"
            );
        }
        
        collateralBalances[msg.sender] -= amount;
        
        emit CollateralWithdrawn(msg.sender, amount);
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "ETH transfer failed");
    }
    
    /**
     * @dev Allows users to borrow tokens against their deposited collateral
     * Mints lending tokens based on the collateralization ratio
     * @param amount Amount of tokens (in USD value with 18 decimals) to borrow
     */
    function borrow(uint256 amount) external override nonReentrant {
        require(amount > 0, "Borrow amount must be positive");
        require(collateralBalances[msg.sender] > 0, "No collateral deposited");
        
        // Calculate the USD value of user's collateral
        uint256 collateralValue = getEthValueInUSD(collateralBalances[msg.sender]);
        
        // Calculate total borrowed amount after this borrow
        uint256 totalBorrowed = borrowedAmounts[msg.sender] + amount;
        
        // Calculate required collateral (150% of borrowed amount)
        uint256 requiredCollateral = (totalBorrowed * COLLATERAL_RATIO) / 100;
        
        require(
            collateralValue >= requiredCollateral,
            "Insufficient collateral for borrow amount"
        );
        
        borrowedAmounts[msg.sender] += amount;
        
        emit TokensBorrowed(msg.sender, amount);
        
        // Mint tokens to the borrower
        lendingToken.mint(msg.sender, amount);
    }
    
    /**
     * @dev Returns the collateral balance of a specific user
     * @param user Address of the user to query
     * @return The collateral balance in wei
     */
    function getCollateralBalance(address user) external view override returns (uint256) {
        return collateralBalances[user];
    }
    
    /**
     * @dev Returns the borrowed token amount for a specific user
     * @param user Address of the user to query
     * @return The borrowed amount
     */
    function getBorrowedAmount(address user) external view returns (uint256) {
        return borrowedAmounts[user];
    }
}