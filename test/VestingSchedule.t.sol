// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/VestingSchedule.sol";

contract VestingScheduleTest is Test {

    function testDeploy() public {
        vm.warp(1689565354);
        VestingSchedule vestingSchedule = new VestingSchedule();
    }
}
