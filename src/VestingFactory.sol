// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { Ownable2Step } from "openzeppelin/access/Ownable2Step.sol";
import { Ownable } from "openzeppelin/access/Ownable.sol";
import { VestingWallet } from "src/VestingWallet.sol";

/// @title Vesting Factory
/// @dev This is a factory contract which will have a erc20.approve from the grants Safe contract. It creates individual
/// vesting wallets with the right parameters and it implements a
/// release function which will transfer the tokens to each individual vesting wallet for each beneficiary.
contract VestingFactory is Ownable2Step {
    /// @notice Address of the safe contract that will approve the tokens to be transferred to the vesting wallets.
    address public immutable safeProxy;

    /// @notice Struct to keep track of the vesting wallets and the amount of tokens they should receive.
    struct VestingWalletInfo {
        uint256 amount;
        address beneficiary;
        uint64 startTimestamp;
        uint64 durationSeconds;
    }

    /// @notice Struct to keep track of the vesting wallets and the amount of tokens they should receive.
    struct VestingWalletLog {
        address wallet;
        VestingWalletInfo info;
    }

    /// @notice List of vesting wallets and the amount of tokens they should receive.
    VestingWalletLog[] public vestingWallets;

    /// @notice Emitted when tokens are released to a vesting wallet.
    event VestingWalletFunded(address indexed token, address wallet, uint256 amount);

    /// @notice Emitted when a new vesting wallet is created.
    event VestingWalletCreated(address wallet, VestingWalletInfo info);

    /// @notice Emitted when the beneficiary is not a valid account.
    error VestingWalletInvalidBeneficiary(address beneficiary);

    /// @notice Emitted when the amount to be released does not match the amount approved by the safe
    /// to this contract.
    error VestingWalletInvalidAmount();

    /// @notice Sets the `safeProxy` address and the list of `vestingWallets` that will receive tokens.
    /// @param _safeProxy Address of the safe contract that will approve the tokens to be transferred to the vesting
    /// wallets.
    /// @param owner Address of the owner of the contract.
    constructor(address _safeProxy, address owner) Ownable(owner) {
        safeProxy = _safeProxy;
    }

    /// @notice creates and funds the vesting wallets with the right parameters.
    /// @param token Address of the token to be transferred to the vesting wallets.
    /// @param _vestingWallets List of vesting wallet parameters and the amount of tokens they should receive.
    function createVestingWallets(address token, VestingWalletInfo[] calldata _vestingWallets) public onlyOwner {
        uint256 totalSum = 0;

        for (uint256 i = 0; i < _vestingWallets.length; i++) {
            address beneficiary = _vestingWallets[i].beneficiary;
            uint256 amount = _vestingWallets[i].amount;
            uint64 start = _vestingWallets[i].startTimestamp;
            uint64 duration = _vestingWallets[i].durationSeconds;

            totalSum += amount;

            if (beneficiary == address(0)) revert VestingWalletInvalidBeneficiary(beneficiary);

            VestingWallet wallet = new VestingWallet(beneficiary, start, duration);

            vestingWallets.push(VestingWalletLog(address(wallet), _vestingWallets[i]));

            emit VestingWalletCreated(address(wallet), _vestingWallets[i]);

            if (totalSum > IERC20(token).allowance(safeProxy, address(this))) revert VestingWalletInvalidAmount();

            SafeERC20.safeTransferFrom(IERC20(token), safeProxy, address(wallet), amount);

            emit VestingWalletFunded(token, address(wallet), amount);
        }
    }
}
