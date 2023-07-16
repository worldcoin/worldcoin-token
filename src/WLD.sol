// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";

/// @title WLD token
/// @author Worldcoin
/// @notice Contract for Worldcoin's ERC20 WLD token
contract WLD is ERC20 {

    /// @notice The maximum supply of WLD tokens.
    uint256 constant MAX_SUPPLY = 10**28; // 10 B with 18 decimals

    /// @notice The address of the onceMinter.
    address public onceMinter;

    /// @notice Emitted when constructing the contract
    event TokenUpdated(
        address previousToken,
        address newToken,
        string name,
        string symbol,
        address[] existingHolders,
        uint256[] existingsAmounts
    );

    /// @notice Emitted when minting tokens. Can be emited once.
    event TokensMinted(
        address minter,
        address[] newHolders,
        uint256[] newAmounts
    );

    ///////////////////////////////////////////////////////////////////
    ///                         CONSTRUCTOR                         ///
    ///////////////////////////////////////////////////////////////////

    /// @notice Upgrade a token contract.
    constructor(
        address previousToken,
        address[] memory existingHolders,
        uint256[] memory existingAmounts,
        string memory newName_,
        string memory newSymbol_,
        address onceMinter_
    ) ERC20(newName_, newSymbol_) {
        // Validate input.
        require(existingAmounts.length == existingHolders.length);

        for (uint256 i = 0; i < existingHolders.length; i++) {
            _update(address(0), existingHolders[i], existingAmounts[i]);
        }
        emit TokenUpdated(
            previousToken,
            address(this),
            newName_,
            newSymbol_,
            existingHolders,
            existingAmounts
        );

        // Set onceMinter
        onceMinter = onceMinter_;

        // Insist that the total supply is within the max supply.
        require(totalSupply() <= MAX_SUPPLY);
    }

    /// @notice Mint new tokens.
    function mintOnce(
        address[] memory newHolders,
        uint256[] memory newAmounts
    ) external {
        // onceMinter must be set.
        require(onceMinter != address(0));
        
        // Only the onceMinter can mint.
        require(msg.sender == onceMinter);

        // Validate input.
        require(newHolders.length == newAmounts.length);

        // onceMinter can only mint once.
        onceMinter = address(0);

        // Mint tokens.
        for (uint256 i = 0; i < newHolders.length; i++) {
            _mint(newHolders[i], newAmounts[i]);
        }
        emit TokensMinted(
            msg.sender,
            newHolders,
            newAmounts
        );
        
        // Insist that the total supply is still within the max supply.
        require(totalSupply() <= MAX_SUPPLY);
    }
}
