// File: Owned.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Owned
 * @notice Contract to manage ownership. Provides an 'owner' state variable
 * and a modifier for owner-only functions.
 */
contract Owned {
    address public owner;

    /**
     * @notice Sets the initial owner of the contract to the deployer.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Modifier that restricts access to only the contract owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Owned: Not the owner");
        _;
    }
}