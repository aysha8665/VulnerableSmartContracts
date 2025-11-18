// File: LendingProtocol.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ILendingProtocol.sol";
import "./CollateralManager.sol";
import "./AccessControl.sol";

/**
 * @title LendingProtocol
 * @notice A decentralized lending protocol with collateralized loans
 * @dev Implements the ILendingProtocol interface, inherits AccessControl,
 *      and uses CollateralManager for collateral calculations
 */
contract LendingProtocol is ILendingProtocol, AccessControl {
    CollateralManager public collateralManager;
    
    struct Loan {
        address borrower;
        uint256 principal;
        uint256 collateral;
        uint256 interestAccrued;
        uint256 lastInterestUpdate;
        bool isActive;
    }
    
    mapping(address => uint256) private collateralBalances;
    mapping(uint256 => Loan) private loans;
    mapping(address => uint256[]) private userLoanIds;
    
    uint256 private loanCounter;
    uint256 public constant INTEREST_RATE = 10; // 10% annual interest
    uint256 public constant YEAR_IN_SECONDS = 365 days;
    uint256 public totalPoolBalance;
    
    event CollateralDeposited(address indexed user, uint256 amount);
    event LoanCreated(uint256 indexed loanId, address indexed borrower, uint256 amount, uint256 collateral);
    event LoanRepaid(uint256 indexed loanId, address indexed borrower, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 loanId, uint256 amount);
    
    /**
     * @notice Deploys the lending protocol and initializes the collateral manager
     */
    constructor() payable {
        collateralManager = new CollateralManager();
        totalPoolBalance = msg.value;
    }
    
    /**
     * @notice Allows users to deposit ETH as collateral
     * @dev Updates the user's collateral balance
     */
    function depositCollateral() external payable override whenNotShutdown {
        require(msg.value > 0, "LendingProtocol: deposit must be greater than 0");
        
        collateralBalances[msg.sender] += msg.value;
        
        emit CollateralDeposited(msg.sender, msg.value);
    }
    
    /**
     * @notice Allows users to borrow funds against their collateral
     * @param amount The amount to borrow
     * @dev Creates a new loan and transfers funds to the borrower
     */
    function borrow(uint256 amount) external override whenNotShutdown {
        require(amount > 0, "LendingProtocol: borrow amount must be greater than 0");
        require(collateralBalances[msg.sender] > 0, "LendingProtocol: no collateral deposited");
        require(totalPoolBalance >= amount, "LendingProtocol: insufficient pool liquidity");
        
        uint256 availableCollateral = collateralBalances[msg.sender];
        require(
            collateralManager.isValidBorrow(availableCollateral, amount),
            "LendingProtocol: insufficient collateral for borrow amount"
        );
        
        uint256 requiredCollateral = collateralManager.calculateRequiredCollateral(amount);
        
        loanCounter++;
        loans[loanCounter] = Loan({
            borrower: msg.sender,
            principal: amount,
            collateral: requiredCollateral,
            interestAccrued: 0,
            lastInterestUpdate: block.timestamp,
            isActive: true
        });
        
        collateralBalances[msg.sender] -= requiredCollateral;
        userLoanIds[msg.sender].push(loanCounter);
        totalPoolBalance -= amount;
        
        emit LoanCreated(loanCounter, msg.sender, amount, requiredCollateral);
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "LendingProtocol: borrow transfer failed");
    }
    
    /**
     * @notice Allows borrowers to repay their loan and retrieve collateral
     * @param loanId The ID of the loan to repay
     * @dev Updates loan status and returns collateral to the borrower
     */
    function repayLoan(uint256 loanId) external payable override whenNotShutdown {
        Loan storage loan = loans[loanId];
        require(loan.isActive, "LendingProtocol: loan is not active");
        require(loan.borrower == msg.sender, "LendingProtocol: not the loan borrower");
        
        uint256 interest = _calculateInterest(loanId);
        uint256 totalRepayment = loan.principal + interest;
        
        require(msg.value >= totalRepayment, "LendingProtocol: insufficient repayment amount");
        
        uint256 collateralToReturn = loan.collateral;
        
        loan.isActive = false;
        loan.interestAccrued = 0;
        totalPoolBalance += totalRepayment;
        
        emit LoanRepaid(loanId, msg.sender, totalRepayment);
        
        (bool success, ) = msg.sender.call{value: collateralToReturn}("");
        require(success, "LendingProtocol: collateral return failed");
        
        if (msg.value > totalRepayment) {
            (bool refundSuccess, ) = msg.sender.call{value: msg.value - totalRepayment}("");
            require(refundSuccess, "LendingProtocol: refund failed");
        }
    }
    
    /**
     * @notice Allows borrowers to withdraw excess collateral
     * @param loanId The ID of the loan
     * @param amount The amount of collateral to withdraw
     * @dev Withdraws collateral if sufficient excess exists after debt coverage
     */
    function withdrawCollateral(uint256 loanId, uint256 amount) external override whenNotShutdown {
        Loan storage loan = loans[loanId];
        require(loan.isActive, "LendingProtocol: loan is not active");
        require(loan.borrower == msg.sender, "LendingProtocol: not the loan borrower");
        require(amount > 0, "LendingProtocol: withdrawal amount must be greater than 0");
        
        uint256 interest = _calculateInterest(loanId);
        uint256 outstandingDebt = loan.principal + interest;
        
        uint256 excessCollateral = collateralManager.calculateExcessCollateral(
            loan.collateral,
            outstandingDebt
        );
        
        require(amount <= excessCollateral, "LendingProtocol: insufficient excess collateral");
        
        loan.collateral -= amount;
        
        emit CollateralWithdrawn(msg.sender, loanId, amount);
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "LendingProtocol: collateral withdrawal failed");
    }
    
    /**
     * @notice Returns the collateral balance of a user
     * @param user The address to query
     * @return The available collateral balance
     */
    function getCollateralBalance(address user) external view override returns (uint256) {
        return collateralBalances[user];
    }
    
    /**
     * @notice Returns detailed information about a loan
     * @param loanId The loan ID to query
     * @return borrower The borrower's address
     * @return principal The principal amount
     * @return collateral The collateral amount
     * @return isActive The loan status
     */
    function getLoanDetails(uint256 loanId) external view override returns (
        address borrower,
        uint256 principal,
        uint256 collateral,
        bool isActive
    ) {
        Loan memory loan = loans[loanId];
        return (loan.borrower, loan.principal, loan.collateral, loan.isActive);
    }
    
    /**
     * @notice Returns all loan IDs for a specific user
     * @param user The address to query
     * @return An array of loan IDs
     */
    function getUserLoanIds(address user) external view returns (uint256[] memory) {
        return userLoanIds[user];
    }
    
    /**
     * @notice Calculates accrued interest for a loan
     * @param loanId The loan ID
     * @return The accrued interest amount
     */
    function _calculateInterest(uint256 loanId) private view returns (uint256) {
        Loan memory loan = loans[loanId];
        if (!loan.isActive) return 0;
        
        uint256 timeElapsed = block.timestamp - loan.lastInterestUpdate;
        uint256 interest = (loan.principal * INTEREST_RATE * timeElapsed) / (100 * YEAR_IN_SECONDS);
        
        return loan.interestAccrued + interest;
    }
    
    /**
     * @notice Allows the protocol to receive ETH directly
     */
    receive() external payable {
        totalPoolBalance += msg.value;
    }
}