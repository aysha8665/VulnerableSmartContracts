// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Vulnerable Contract - Reentrancy Attack
contract Vault {
    mapping(address => uint) public balances;
    
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }
    
    function withdraw() public {
        uint bal = balances[msg.sender];
        require(bal > 0);
        (bool sent, ) = msg.sender.call{value: bal}("");
        require(sent);
        balances[msg.sender] = 0; // State updated AFTER external call
    }
}