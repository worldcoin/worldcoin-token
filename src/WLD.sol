// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ERC20 } from "openzeppelin/token/ERC20/ERC20.sol";
import { ERC20Capped } from "openzeppelin/token/ERC20/extensions/ERC20Capped.sol";

/// @title WLD token
/// @author Worldcoin
/// @notice Contract for Worldcoin's ERC20 WLD token
contract WLD is ERC20Capped {

    /// @notice The maximum supply of WLD tokens.
    uint256 constant ONE_WLD = 10**18; // 18 decimals
    uint256 constant MAX_SUPPLY = 10**10 * ONE_WLD; // 10 Billion WLD

    /// @notice The address of the onceMinter.
    address public onceMinter;

    /// @notice Emitted when constructing the contract
    event TokenUpdated(
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

    /// @notice Deploy a new token contract that replaces an existing one.
    constructor(
        address[] memory existingHolders,
        uint256[] memory existingAmounts,
        string memory name_,
        string memory symbol_,
        address onceMinter_
    ) ERC20(name_, symbol_) ERC20Capped(MAX_SUPPLY) {
        // Validate input.
        require(existingAmounts.length == existingHolders.length);

        // Reinstate balances
        for (uint256 i = 0; i < existingHolders.length; i++) {
            _update(address(0), existingHolders[i], existingAmounts[i]);
        }
        
        // Set onceMinter
        onceMinter = onceMinter_;

        // Emit event.
        emit TokenUpdated(
            address(this),
            name_,
            symbol_,
            existingHolders,
            existingAmounts
        );
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
    }
}
