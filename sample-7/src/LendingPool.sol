// FILE: contracts/LendingPool.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./InterestCalculator.sol";

/**
 * @title LendingPool
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
    
    function withdraw(uint256 amt) external {
        require(balances[msg.sender] >= amt, "Low balance");
        
        uint256 interest = calculator.calculate(
            balances[msg.sender],
            block.timestamp - depositTime[msg.sender]
        );
        
        (bool ok, ) = msg.sender.call{value: amt + interest}("");
        require(ok, "Transfer failed");
        
        balances[msg.sender] -= amt; 
        depositTime[msg.sender] = block.timestamp;
        
        emit Withdraw(msg.sender, amt + interest);
    }
    
    receive() external payable {
        this.deposit();
    }
}