// File: Ownable.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Ownable
 * @notice Basic access control mechanism with ownership
 * @dev Provides a modifier to restrict functions to the contract owner
 */
abstract contract Ownable {
    address private _owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
     * @notice Sets the deployer as the initial owner
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    
    /**
     * @notice Returns the current owner address
     */
    function owner() public view returns (address) {
        return _owner;
    }
    
    /**
     * @notice Restricts function access to the owner only
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }
    
    /**
     * @notice Transfers ownership to a new address
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}