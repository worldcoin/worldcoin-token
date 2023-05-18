// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC1967Proxy} from "openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";

/// @title Worldcoin Token
/// @author Worldcoin
/// @notice An implementation of the WLD token.
/// @dev This contract is a proxy contract that delegates actual logic to
///      the implementation.
contract WLD is ERC1967Proxy {
    constructor(
        address _logic,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {}
}
