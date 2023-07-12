// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";

/// @title WLD token
/// @author Worldcoin
/// @notice Contract for Worldcoin's ERC20 WLD token
contract WLD is ERC20 {
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
    ) ERC20(name_, symbol_) {
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
}
