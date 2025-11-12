// FILE: LendingPool.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @title LendingPool
 */
contract LendingPool is Ownable {
    
    mapping(address => uint256) public balances;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    
    function deposit() external payable {
        require(msg.value > 0, "Zero amount");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
        
        balances[msg.sender] -= amount;
        
        emit Withdraw(msg.sender, amount);
    }
    
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }
    
    receive() external payable {
        balances[msg.sender] += msg.value;
    }
}
