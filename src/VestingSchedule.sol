pragma solidity ^0.8.19;

import {VestingWallet} from "openzeppelin/finance/VestingWallet.sol";

contract VestingSchedule {

    event VestingScheduleCreated(
        address vestingWallet,
        address beneficiary,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 durationSeconds
    );

    constructor() {
        address beneficiary = address(0x59a0f98345f54bAB245A043488ECE7FCecD7B596); // worldassets
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

            // Verify duration is correct.
            if (i == 0 || i == 1 || i == 2) {
                // 3 years
                require(durationSeconds == 94694400);
            } else if (i == 3) {
                // 6 years
                require(durationSeconds == 189302400);
            } else {
                revert();
            }

            VestingWallet vestingWallet = new VestingWallet(beneficiary, startTimestamp, durationSeconds);

            emit VestingScheduleCreated(
                address(vestingWallet),
                vestingWallet.beneficiary(),
                vestingWallet.start(),
                vestingWallet.end(),
                vestingWallet.duration()
            );

            require(vestingWallet.beneficiary() == beneficiary);
            require(vestingWallet.start() == startTimestamp);
            require(vestingWallet.end() == endTimestamp[i]);
            require(vestingWallet.duration() == durationSeconds);

            startTimestamp = endTimestamp[i];
        }
    }
}
