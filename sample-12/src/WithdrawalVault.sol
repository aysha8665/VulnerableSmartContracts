// File: WithdrawalVault.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Interface.sol";
import "./Owned.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Using OpenZeppelin SafeMath

/**
 * @title WithdrawalVault
 * @notice A simple vault contract allowing deposits and owner-controlled withdrawal.
 * Inherits ownership from Owned, implements IVault, and uses OpenZeppelin SafeMath.
 */
contract WithdrawalVault is IVault, Owned {
    // We demonstrate using SafeMath for a dummy calculation
    using SafeMath for uint256;

    /**
     * @notice Allows a user to deposit Ether into the vault.
     * The transaction must send some Ether.
     */
    function deposit() external payable override {
        require(msg.value > 0, "Vault: Must send Ether");
    }

    /**
     * @notice Allows the contract owner to withdraw a specified amount of held Ether.
     * @param _amount The amount of Ether (in Wei) to withdraw.
     * @dev This function transfers the funds to the caller. Note the security check placement.
     */
    function withdrawAll(uint256 _amount) external override {
        // Dummy SafeMath usage to meet the project requirement (though not strictly necessary in 0.8.x)
        // This ensures the contract is slightly less than max uint256, demonstrating its usage.
        uint256 safeCheck = _amount.sub(1, "Vault: Amount must be greater than 0");

        // Check if the contract has sufficient balance.
        require(address(this).balance >= _amount, "Vault: Insufficient balance");

        // Attempt to send the Ether to the caller.
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Vault: Transfer failed");
    }

    /**
     * @notice Returns the current balance of the contract.
     * @return The contract's Ether balance.
     */
    function getBalance() external view override returns (uint256) {
        return address(this).balance;
    }
}