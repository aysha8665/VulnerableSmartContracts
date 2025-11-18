// File: AccessControl.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title AccessControl
 * @notice Manages roles and permissions for the protocol
 * @dev Provides role-based access control with admin and operator roles
 */
abstract contract AccessControl {
    address private _admin;
    mapping(address => bool) private _operators;
    bool private _emergencyShutdown;
    
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
    event OperatorAdded(address indexed operator);
    event OperatorRemoved(address indexed operator);
    event EmergencyShutdown(address indexed trigger);
    
    /**
     * @notice Initializes the access control with the deployer as admin
     */
    constructor() {
        _admin = msg.sender;
        _operators[msg.sender] = true;
        emit AdminTransferred(address(0), msg.sender);
    }
    
    /**
     * @notice Returns the current admin address
     */
    function admin() public view returns (address) {
        return _admin;
    }
    
    /**
     * @notice Checks if an address is an operator
     */
    function isOperator(address account) public view returns (bool) {
        return _operators[account];
    }
    
    /**
     * @notice Returns the emergency shutdown status
     */
    function isShutdown() public view returns (bool) {
        return _emergencyShutdown;
    }
    
    /**
     * @notice Restricts function access to admin only
     */
    modifier onlyAdmin() {
        require(msg.sender == _admin, "AccessControl: caller is not admin");
        _;
    }
    
    /**
     * @notice Restricts function access to operators only
     */
    modifier onlyOperator() {
        require(_operators[msg.sender], "AccessControl: caller is not operator");
        _;
    }
    
    /**
     * @notice Prevents execution during emergency shutdown
     */
    modifier whenNotShutdown() {
        require(!_emergencyShutdown, "AccessControl: emergency shutdown active");
        _;
    }
    
    /**
     * @notice Transfers admin rights to a new address
     * @param newAdmin The address of the new admin
     */
    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "AccessControl: new admin is zero address");
        emit AdminTransferred(_admin, newAdmin);
        _admin = newAdmin;
    }
    
    /**
     * @notice Adds a new operator
     * @param operator The address to grant operator privileges
     */
    function addOperator(address operator) external onlyAdmin {
        require(!_operators[operator], "AccessControl: already operator");
        _operators[operator] = true;
        emit OperatorAdded(operator);
    }
    
    /**
     * @notice Removes an operator
     * @param operator The address to revoke operator privileges
     */
    function removeOperator(address operator) external onlyAdmin {
        require(_operators[operator], "AccessControl: not an operator");
        _operators[operator] = false;
        emit OperatorRemoved(operator);
    }
    
    /**
     * @notice Triggers emergency shutdown of the protocol
     */
    function triggerEmergencyShutdown() external onlyAdmin {
        _emergencyShutdown = true;
        emit EmergencyShutdown(msg.sender);
    }
}