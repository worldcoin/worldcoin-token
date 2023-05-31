// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/WLD2.sol";

contract WLD2Test is Test {
    WLD2 token;
    address[] initialBeneficiaries;
    uint256[] initialAmounts;

    function setUp() public {
        initialBeneficiaries = new address[](200);
        initialAmounts = new uint256[](200);

        for (uint256 i = 0; i < 200; i++) {
            initialBeneficiaries[i] = address(uint160(i + 1));
            console.logAddress(initialBeneficiaries[i]);
            initialAmounts[i] = 5 * i * 10e5;
            console.logUint(initialAmounts[i]);
        }
    }

    function testMintToken() public {
        token = new WLD2(10e9, 1, 1, initialBeneficiaries, initialAmounts);
    }
}
