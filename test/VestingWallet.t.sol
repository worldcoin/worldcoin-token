// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/VestingWallet.sol";
import "openzeppelin/utils/math/Math.sol";
import "../src/WLD.sol";

contract VestingWalletTest is Test {
    uint64 private _duration = 4 * 365 days;
    uint64 private _start = uint64(block.timestamp) + 1 hours;
    VestingWallet _wallet;
    address _beneficiary = address(uint160(uint256(keccak256("beneficiary"))));

    function setUp() public {
        _wallet = new VestingWallet(_beneficiary, _start, _duration);
    }

    function testZeroBeneficiary() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                VestingWallet.VestingWalletInvalidBeneficiary.selector,
                address(0)
            )
        );
        new VestingWallet(address(0), _start, _duration);
    }

    function testParameterGetters() public {
        assertEq(_wallet.owner(), _beneficiary);
        assertEq(_wallet.start(), _start);
        assertEq(_wallet.duration(), _duration);
        assertEq(_wallet.end(), _start + _duration);
    }

    struct ScheduleItem {
        uint64 timestamp;
        uint256 expectedAmount;
    }

    /**
     * @dev Builds a schedule of `length` points, spaced uniformly between `start` and
     * `start + duration`.
     */
    function buildSchedule(
        uint256 fullAmount, uint256 length
    ) public view returns (ScheduleItem[] memory) {
        ScheduleItem[] memory schedule = new ScheduleItem[](length);
        for (uint256 i = 0; i < schedule.length; i++) {
            uint64 timestamp = uint64(_start + (i * _duration) / (length - 1));
            schedule[i].timestamp = timestamp;
            schedule[i].expectedAmount = Math.min(
                fullAmount,
                (fullAmount * (timestamp - _start)) / _duration
            );
        }
        return schedule;
    }


    function testERC20VestingGetters() public {
        uint256 amount = 10000;
        address[] memory recv = new address[](1);
        recv[0] = address(_wallet);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        address token = address(new WLD("Test", "TST", 1, 0, 1, 0, recv, amounts));
        ScheduleItem[] memory schedule = buildSchedule(amount, 64);
        for (uint256 i = 0; i < schedule.length; i++) {
            vm.warp(schedule[i].timestamp);
            assert(
                _wallet.vestedAmount(token, schedule[i].timestamp) ==
                    schedule[i].expectedAmount
            );
        }
    }

    function testERC20VestingExecution() public {
        uint256 amount = 10000;
        address[] memory recv = new address[](1);
        recv[0] = address(_wallet);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        WLD token = new WLD("Test", "TST", 1, 0, 1, 0, recv, amounts);
        ScheduleItem[] memory schedule = buildSchedule(amount, 64);
        _wallet.release(address(token));
        assertEq(token.balanceOf(_beneficiary), 0);
        for (uint256 i = 0; i < schedule.length; i++) {
            vm.warp(schedule[i].timestamp);
            _wallet.release(address(token));
            assertEq(token.balanceOf(_beneficiary), schedule[i].expectedAmount);
        }
    }

    function testERC20OwnershipTransfer() public {
        uint256 amount = 10000;
        address[] memory recv = new address[](1);
        recv[0] = address(_wallet);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        WLD token = new WLD("Test", "TST", 1, 0, 1, 0, recv, amounts);
        ScheduleItem[] memory schedule = buildSchedule(amount, 3);
        address newOwner = address(uint160(uint256(keccak256("new beneficiary"))));
        vm.warp(schedule[1].timestamp);
        _wallet.release(address(token));
        assertEq(token.balanceOf(_beneficiary), 5000);
        assertEq(token.balanceOf(newOwner), 0);
        vm.prank(_beneficiary);
        _wallet.transferOwnership(newOwner);
        assertEq(_wallet.owner(), _beneficiary);
        vm.prank(newOwner);
        _wallet.acceptOwnership();
        assertEq(_wallet.owner(), newOwner);
        vm.warp(schedule[2].timestamp);
        _wallet.release(address(token));
        assertEq(token.balanceOf(_beneficiary), 5000);
        assertEq(token.balanceOf(newOwner), 5000);
    }
}