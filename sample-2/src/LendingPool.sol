// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LendingPool {
    mapping(address => uint) public deposits;
    mapping(address => uint) public borrowed;
    mapping(address => uint) public lastWithdrawTime;
    
    address public owner;
    uint public totalDeposits;
    uint public totalBorrowed;
    uint public interestRate = 5;
    uint public collateralRatio = 150;
    
    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint amount);
    event Borrow(address indexed user, uint amount);
    event Repay(address indexed user, uint amount);
    
    constructor() {
        owner = msg.sender;
    }
    
    function setInterestRate(uint _rate) public {
        interestRate = _rate;
    }
    
    function deposit() public payable {
        require(msg.value > 0, "Must deposit something");
        deposits[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    function withdraw(uint _amount) public {
        require(deposits[msg.sender] >= _amount, "Insufficient balance");
        require(borrowed[msg.sender] == 0, "Must repay loan first");
        
        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to send");
        
        deposits[msg.sender] -= _amount;
        totalDeposits -= _amount;
        lastWithdrawTime[msg.sender] = block.timestamp;
        
        emit Withdraw(msg.sender, _amount);
    }
    
    function luckyWithdraw() public {
        require(deposits[msg.sender] > 0, "No deposits");
        
        uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100;
        
        if (random < 10) {
            uint bonus = deposits[msg.sender] / 10;
            deposits[msg.sender] += bonus;
            emit Deposit(msg.sender, bonus);
        }
    }
    
    function borrow(uint _amount) public {
        uint maxBorrow = (deposits[msg.sender] * 100) / collateralRatio;
        require(_amount <= maxBorrow, "Insufficient collateral");
        require(address(this).balance >= _amount, "Pool has insufficient funds");
        
        borrowed[msg.sender] += _amount;
        totalBorrowed += _amount;
        
        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Transfer failed");
        
        emit Borrow(msg.sender, _amount);
    }
    
    function repay() public payable {
        require(borrowed[msg.sender] > 0, "No active loan");
        
        uint interest = (borrowed[msg.sender] * interestRate) / 100;
        uint totalOwed = borrowed[msg.sender] + interest;
        
        require(msg.value >= totalOwed, "Insufficient repayment");
        
        borrowed[msg.sender] = 0;
        totalBorrowed -= borrowed[msg.sender];
        
        emit Repay(msg.sender, msg.value);
    }
    
    function withdrawAll() public {
        uint amount = deposits[msg.sender];
        require(amount > 0, "No deposits");
        require(borrowed[msg.sender] == 0, "Must repay loan first");
        
        deposits[msg.sender] = 0;
        totalDeposits -= amount;
        
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send");
        
        emit Withdraw(msg.sender, amount);
    }
    
    function emergencyShutdown() public {
        require(msg.sender == owner, "Only owner");
        selfdestruct(payable(owner));
    }
    
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function getUserDeposit(address _user) public view returns (uint) {
        return deposits[_user];
    }
    
    function getUserLoan(address _user) public view returns (uint) {
        return borrowed[_user];
    }
}