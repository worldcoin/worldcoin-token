// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {Ownable2Step} from "openzeppelin/access/Ownable2Step.sol";
import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";

/// @title WLD token
/// @author Worldcoin
/// @notice Contract for Worldcoin's ERC20 WLD token
contract WLD is ERC20, Ownable2Step {
    ///////////////////////////////////////////////////////////////////
    ///                           STORAGE                           ///
    ///////////////////////////////////////////////////////////////////

    /// @notice The symbol of the token
    string private _symbol;

    /// @notice The name of the token
    string private _name;

    /// @notice Emmitted in revert if the owner attempts to resign ownership.
    error CannotRenounceOwnership();

    /// @notice Emitted when constructing the contract
    event TokenDeployed(
        string name,
        string symbol,
        address[] initialHolders,
        uint256[] initialAmounts
    );

    ///////////////////////////////////////////////////////////////////
    ///                         CONSTRUCTOR                         ///
    ///////////////////////////////////////////////////////////////////

    constructor(
        string memory name_,
        string memory symbol_,
        address[] memory initialHolders,
        uint256[] memory initialAmounts
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        _name = name_;
        _symbol = symbol_;
        require(initialAmounts.length == initialHolders.length);
        for (uint256 i = 0; i < initialHolders.length; i++) {
            _update(address(0), initialHolders[i], initialAmounts[i]);
        }
        emit TokenDeployed(
            name_,
            symbol_,
            initialHolders,
            initialAmounts
        );
    }

    ///////////////////////////////////////////////////////////////////
    ///                           METADATA                          ///
    ///////////////////////////////////////////////////////////////////

    /// @notice Returns the name of the token
    function name() public view override returns (string memory) {
        return _name;
    }

    /// @notice Returns that symbol of the token
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    ///////////////////////////////////////////////////////////////////
    ///                        ADMIN ACTIONS                        ///
    ///////////////////////////////////////////////////////////////////

    /// @notice Sets the name of the token
    /// @param name_ new name
    function setName(string memory name_) external onlyOwner {
        _name = name_;
    }

    /// @notice Sets the token symbol
    /// @param symbol_ new symbol
    function setSymbol(string memory symbol_) external onlyOwner {
        _symbol = symbol_;
    }

    /// @notice Prevents the owner from renouncing ownership
    /// @dev onlyOwner
    function renounceOwnership() public view override onlyOwner {
        revert CannotRenounceOwnership();
    }
}
