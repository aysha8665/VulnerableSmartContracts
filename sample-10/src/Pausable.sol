// File: Pausable.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Pausable
 * @notice Emergency pause mechanism for contract operations
 * @dev Provides modifiers to pause and unpause contract functionality
 */
abstract contract Pausable {
    bool private _paused;
    address private _admin;
    
    event Paused(address account);
    event Unpaused(address account);
    
    /**
     * @notice Initializes the contract in unpaused state
     * @dev Sets the deployer as the admin
     */
    constructor() {
        _paused = false;
        _admin = msg.sender;
    }
    
    /**
     * @notice Returns the current pause status
     */
    function paused() public view returns (bool) {
        return _paused;
    }
    
    /**
     * @notice Modifier to restrict functions when not paused
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }
    
    /**
     * @notice Modifier to restrict functions to admin only
     */
    modifier onlyAdmin() {
        require(msg.sender == _admin, "Pausable: caller is not admin");
        _;
    }
    
    /**
     * @notice Pauses the contract
     */
    function pause() external onlyAdmin {
        _paused = true;
        emit Paused(msg.sender);
    }
    
    /**
     * @notice Unpauses the contract
     */
    function unpause() external onlyAdmin {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}