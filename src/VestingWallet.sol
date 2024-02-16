// SPDX-License-Identifier: UNLICENSED
// OpenZeppelin Contracts (last updated v4.9.0) (finance/VestingWallet.sol)
// Modified for Worldcoin
pragma solidity ^0.8.19;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {Ownable2Step} from "openzeppelin/access/Ownable2Step.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";

/**
 * @title VestingWallet
 * @dev This contract handles the vesting of ERC20 tokens for a given beneficiary. Custody of multiple tokens
 * can be given to this contract, which will release the token to the beneficiary following a linear vesting schedule.
 * The vesting schedule is customizable through the {vestedAmount} function.
 *
 * Any token transferred to this contract will follow the vesting schedule as if they were locked from the beginning.
 * Consequently, if the vesting has already started, any amount of tokens sent to this contract will (at least partly)
 * be immediately releasable.
 *
 * By setting the duration to 0, one can configure this contract to behave like an asset timelock that hold tokens for
 * a beneficiary until a specified time.
 *
 * The beneficiary is controlled through the {Ownable} mechanism, so they can assign the unreleased portion of the
 * assets
 * to another party.
 */
contract VestingWallet is Ownable2Step {
    event ERC20Released(address indexed token, uint256 amount);

    /**
     * @dev The `beneficiary` is not a valid account.
     */
    error VestingWalletInvalidBeneficiary(address beneficiary);

    mapping(address => uint256) public released;
    uint64 public immutable start;
    uint64 public immutable duration;
    uint64 public immutable end;

    /**
     * @dev Set the beneficiary, start timestamp and vesting duration of the vesting wallet.
     */
    constructor(
        address beneficiaryAddress,
        uint64 startTimestamp,
        uint64 durationSeconds
    )
        Ownable(beneficiaryAddress)
    {
        if (beneficiaryAddress == address(0)) {
            revert VestingWalletInvalidBeneficiary(address(0));
        }
        start = startTimestamp;
        duration = durationSeconds;
        end = startTimestamp + durationSeconds;
    }

    /**
     * @dev Getter for the amount of releasable `token` tokens. `token` should be the address of an
     * IERC20 contract.
     */
    function releasable(address token) public view returns (uint256) {
        return vestedAmount(token, uint64(block.timestamp)) - released[token];
    }

    /**
     * @dev Release the tokens that have already vested.
     *
     * Emits a {ERC20Released} event.
     */
    function release(address token) external {
        uint256 amount = releasable(token);
        released[token] += amount;
        emit ERC20Released(token, amount);
        SafeERC20.safeTransfer(IERC20(token), owner(), amount);
    }

    /**
     * @dev Calculates the amount of tokens that has already vested using a linear vesting curve.
     */
    function vestedAmount(address token, uint64 timestamp) public view returns (uint256) {
        uint256 totalAllocation = IERC20(token).balanceOf(address(this)) + released[token];
        if (timestamp < start) {
            return 0;
        } else if (timestamp > end) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start)) / duration;
        }
    }
}
