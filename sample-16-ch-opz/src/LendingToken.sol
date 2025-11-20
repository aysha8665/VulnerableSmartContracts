// File: LendingToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title LendingToken
 * @dev ERC20 token that represents the lending platform's native token
 * This token is minted when users borrow against their collateral
 * Inherits from OpenZeppelin's ERC20 and Ownable contracts
 */
contract LendingToken is ERC20, Ownable {
    /**
     * @dev Constructor initializes the token with name and symbol
     * Sets the deployer as the initial owner
     */
    constructor() ERC20("Lending Token", "LEND") Ownable(msg.sender) {}
    
    /**
     * @dev Mints new tokens to a specified address
     * Can only be called by the contract owner (lending pool)
     * @param to Address to receive the minted tokens
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
    
    /**
     * @dev Burns tokens from a specified address
     * Can only be called by the contract owner (lending pool)
     * @param from Address from which tokens will be burned
     * @param amount Amount of tokens to burn
     */
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}