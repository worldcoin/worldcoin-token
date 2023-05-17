// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract WLD is ERC1967Proxy {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}
