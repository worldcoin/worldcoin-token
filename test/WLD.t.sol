// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/WLD.sol";
import "../src/interfaces/IWLD.sol";
import "../src/WLDImplV1.sol";

contract CounterTest is Test {
    IWLD token;
    uint initialTime = 1234 seconds;
    uint oneYear = 31556926 seconds + 1 seconds;
    uint moreThanAYear = 31556926 seconds + 1 seconds;

    function setUp() public {
        address impl = address(new WLDImplV1());
        // 10% inflatioy YOY above 1000 initial supply
        bytes memory initCall = abi.encodeCall(
            WLDImplV1.initialize,
            (1000, 1, 10)
        );
        token = IWLD(address(new WLD(impl, initCall)));
        vm.warp(initialTime);
    }

    function testMintsReachingInitialCap() public {
        // possible, below initial cap
        token.mint(address(this), 100);
        // possible, reaching initial cap
        token.mint(address(this), 900);
        // not possible, exceeding inflation cap
        vm.expectRevert(bytes("WLD: inflation cap reached"));
        token.mint(address(this), 101);
        // 100 is still below inflation, should work
        token.mint(address(this), 100);
        // any further mint fails
        vm.expectRevert(bytes("WLD: inflation cap reached"));
        token.mint(address(this), 1);
        // wait a year
        vm.warp(initialTime + moreThanAYear);
        // can't mint more than 10% of 1100, which is 110.
        vm.expectRevert(bytes("WLD: inflation cap reached"));
        token.mint(address(this), 111);
        // 110 is still below inflation, should work
        token.mint(address(this), 110);
        // verify all mints went through
        assert(token.balanceOf(address(this)) == 1210);
    }

    function testMintsCrossingInitialCap() public {
        // fails – more than initial cap + inflation cap
        vm.expectRevert(bytes("WLD: inflation cap reached"));
        token.mint(address(this), 1101);
        // works – more than initial cap, but below cap + inflation
        token.mint(address(this), 1050); // supply == 1050
        vm.warp(initialTime + 1000 seconds);
        // works - minting up to yearly cap
        token.mint(address(this), 50); // supply == 1100
        // fails - exceeding yearly cap
        vm.expectRevert(bytes("WLD: inflation cap reached"));
        token.mint(address(this), 1);
        vm.warp(initialTime + 1000 seconds + moreThanAYear);
        // works - next cap is 110
        token.mint(address(this), 60); // supply == 1160
        // fails - exceeding yearly cap
        vm.expectRevert(bytes("WLD: inflation cap reached"));
        token.mint(address(this), 51);
        // succeeds - 50 is still below cap
        token.mint(address(this), 50); // supply == 1210

        assert(token.balanceOf(address(this)) == 1210);
    }
}
