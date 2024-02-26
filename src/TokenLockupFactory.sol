// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { Ownable2Step } from "openzeppelin/access/Ownable2Step.sol";
import { Ownable } from "openzeppelin/access/Ownable.sol";
import { VestingWallet } from "src/VestingWallet.sol";

/// @title TokenLockupFactory
/// @notice Factory for VestingWallets with predefined lockup duration.
/// This factory contract takes a list of receivers with amounts, deploys
/// a VestingWallet contract for each, and transfers the given amount of tokens.
///
/// @author Worldcoin
contract TokenLockupFactory is Ownable2Step {
    uint64 public constant LOCKUP_DURATION = 40 days;

    /// @notice Struct to keep track of the beneficiaries and the amount of tokens
    struct TransferInfo {
        uint256 amount;
        address beneficiary;
    }

    /// @notice Emitted when a new VestingWallet is created and tokens are transfered.
    event LockedUpTokenTransfer(address token, address vestingWallet, uint256 amount, address beneficiary);

    /// @notice Emitted when the beneficiary is not a valid account.
    error InvalidBeneficiary(address beneficiary);

    /// @notice Sets the owner of the contract.
    /// @param owner Address of the owner of the TokenLockupFactory.
    constructor(address owner) Ownable(owner) { }

    /// @notice Creates and funds the VestingWallets.
    /// @param token Address of the token to be transferred.
    /// @param _transferInfo List of beneficiaries and amounts.
    function transfer(address token, TransferInfo[] calldata _transferInfo) public onlyOwner {
        uint64 currentTimestamp = uint64(block.timestamp);

        for (uint256 i = 0; i < _transferInfo.length; i++) {
            address beneficiary = _transferInfo[i].beneficiary;
            uint256 amount = _transferInfo[i].amount;

            if (beneficiary == address(0)) {
                revert InvalidBeneficiary(beneficiary);
            }

            VestingWallet wallet = new VestingWallet(beneficiary, currentTimestamp + LOCKUP_DURATION, 0);

            SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(wallet), amount);

            emit LockedUpTokenTransfer(token, address(wallet), amount, beneficiary);
        }
    }
}
