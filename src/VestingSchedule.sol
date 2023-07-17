pragma solidity ^0.8.19;

import {VestingWallet} from "openzeppelin/finance/VestingWallet.sol";

contract VestingSchedule {

    event VestingScheduleCreated(address vestingWallet, uint64 startTimestamp, uint64 durationSeconds);

    constructor() {
        address beneficiary = address(0x59a0f98345f54bAB245A043488ECE7FCecD7B596); // WorldAssets
        uint64 startTimestamp = 1690156800; // 2023-07-24T00:00:00Z

        // Make sure start time is in the next two weeks.
        require(startTimestamp > block.timestamp);
        require(startTimestamp < block.timestamp + 2 weeks);

        uint64[] memory endTimestamp = new uint64[](4);
        endTimestamp[0] = 1784851200; // 2026-07-24T00:00:00Z
        endTimestamp[1] = 1879545600; // 2029-07-24T00:00:00Z
        endTimestamp[2] = 1974240000; // 2032-07-24T00:00:00Z
        endTimestamp[3] = 2163542400; // 2038-07-24T00:00:00Z

        for (uint256 i = 0; i < endTimestamp.length; i++) {
            uint64 durationSeconds = endTimestamp[i] - startTimestamp;

            VestingWallet vestingWallet = new VestingWallet(beneficiary, startTimestamp, durationSeconds);

            emit VestingScheduleCreated(address(vestingWallet), startTimestamp, durationSeconds);

            startTimestamp = endTimestamp[i];
        }
    }
}
