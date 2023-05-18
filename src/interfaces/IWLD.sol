// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20Upgradeable} from "openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IWLD is IERC20Upgradeable {
    function mint(address to, uint256 amount) external;
}