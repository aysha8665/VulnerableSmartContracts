// FILE: contracts/LendingPool.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./InterestCalculator.sol";

/**
 * @title LendingPool
 * @dev Lending pool with REENTRANCY VULNERABILITY in withdraw()
 */
contract LendingPool is Ownable, ReentrancyGuard {
    InterestCalculator public calculator;
    
    mapping(address => uint256) public balances;
    mapping(address => uint256) public depositTime;
    
    event Deposit(address user, uint256 amount);
    event Withdraw(address user, uint256 amount);
    
    constructor(address _calc) {
        calculator = InterestCalculator(_calc);
    }
    
    function deposit() external payable {
        require(msg.value > 0, "Zero amount");
        balances[msg.sender] += msg.value;
        depositTime[msg.sender] = block.timestamp;
        emit Deposit(msg.sender, msg.value);
    }
    
    /**
     * VULNERABLE: Reentrancy - external call before state update
     * Slither will detect: reentrancy-eth vulnerability
     */
    function withdraw(uint256 amt) external {
        require(balances[msg.sender] >= amt, "Low balance");
        
        uint256 interest = calculator.calculate(
            balances[msg.sender],
            block.timestamp - depositTime[msg.sender]
        );
        
        uint256 total = amt + interest;
        
        // VULNERABILITY: External call sends ETH before state changes
        msg.sender.call{value: total}("");
        
        // State changes AFTER external call - reentrancy possible
        balances[msg.sender] -= amt;
        depositTime[msg.sender] = block.timestamp;
        
        emit Withdraw(msg.sender, total);
    }
    
    receive() external payable {
        this.deposit();
    }
}
