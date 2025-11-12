// FILE: Treasury.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./LendingPool.sol";

/**
 * @title Treasury
 * @dev Uses the vulnerable LendingPool
 */
contract Treasury is Ownable {
    LendingPool public pool;
    
    constructor(address _pool) {
        pool = LendingPool(payable(_pool));
    }
    
    function depositToPool() external payable onlyOwner {
        pool.deposit{value: msg.value}();
    }
    
    function withdrawFromPool(uint256 amt) external onlyOwner {
        pool.withdraw(amt);
    }
    
    receive() external payable {}
}