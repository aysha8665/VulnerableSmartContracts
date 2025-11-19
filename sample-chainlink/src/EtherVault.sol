// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IVault.sol";
import "./OracleManager.sol";

/**
 * @title EtherVault
 * @dev Main vault logic allowing deposits and withdrawals of Ether.
 * Inherits from OracleManager to fetch price data for event logging.
 */
contract EtherVault is IVault, OracleManager {
    // Tracks the ETH balance of each user
    mapping(address => uint256) private _balances;

    // Tracks total liquidity in the protocol
    uint256 public totalLiquidity;

    /**
     * @dev Sets up the vault with an owner and a Chainlink Oracle address.
     * @param _oracleAddress Address of the Chainlink Aggregator (ETH/USD).
     */
    constructor(address _oracleAddress) OracleManager(msg.sender, _oracleAddress) {}

    /**
     * @dev Implementation of the deposit function.
     * Updates user balance and total liquidity state.
     */
    function depositETH() external payable override {
        require(msg.value > 0, "Deposit must be greater than 0");
        
        _balances[msg.sender] += msg.value;
        totalLiquidity += msg.value;

        emit UserDeposit(msg.sender, msg.value);
    }

    /**
     * @dev Implementation of the withdrawal function.
     * Fetches the current ETH price for logging purposes, sends funds,
     * and updates internal accounting.
     * @param _amount The amount of Wei to withdraw.
     */
    function withdrawETH(uint256 _amount) external override {
        require(_balances[msg.sender] >= _amount, "Insufficient balance");

        // 1. Fetch external data for the event log
        int256 currentPrice = _getLatestPrice();

        // 2. Perform the ETH transfer to the user
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "ETH Transfer failed");

        // 3. Update internal state after transfer
        _balances[msg.sender] -= _amount;
        totalLiquidity -= _amount;

        emit UserWithdrawal(msg.sender, _amount, currentPrice);
    }

    /**
     * @dev View function to check caller's balance.
     */
    function getMyBalance() external view override returns (uint256) {
        return _balances[msg.sender];
    }

    /**
     * @dev Fallback to accept ETH sent directly to the contract.
     */
    receive() external payable {
        _balances[msg.sender] += msg.value;
        totalLiquidity += msg.value;
    }
}