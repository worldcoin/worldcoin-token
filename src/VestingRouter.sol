// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { Ownable2Step } from "openzeppelin/access/Ownable2Step.sol";
import { Ownable } from "openzeppelin/access/Ownable.sol";
import { VestingWallet } from "src/VestingWallet.sol";

/// @title Vesting Router
/// @dev This is a router contract which will have a erc20.approve from the grants Safe contract, and then call the
/// release function which will transfer the tokens to each individual vesting wallet for each beneficiary.
contract VestingRouter is Ownable2Step {
    /// @notice Struct to keep track of the vesting wallets and the amount of tokens they should receive.
    struct VestingWalletInfo {
        address vestingWallet;
        uint256 amount;
    }

    /// @notice List of vesting wallets and the amount of tokens they should receive.
    VestingWalletInfo[] public vestingWallets;

    /// @notice Address of the safe contract that will approve the tokens to be transferred to the vesting wallets.
    address public immutable safeProxy;

    /// @notice Emitted when tokens are released to a vesting wallet.
    event ERC20Released(address indexed token, address beneficiary, uint256 amount);

    /// @notice Emitted when the beneficiary is not a valid account.
    error VestingWalletInvalidBeneficiary(address beneficiary);

    /// @notice Emitted when the amount to be released does not match the amount approved by the safe
    /// to this contract.
    error VestingWalletsInvalidAmount();

    /// @notice Sets the `safeProxy` address and the list of `vestingWallets` that will receive tokens.
    /// TODO: add Ownable(address)
    constructor(address _safeProxy, address token, VestingWalletInfo[] memory _vestingWallets) Ownable(msg.sender) {
        uint256 totalSum = 0;
        for (uint256 i = 0; i < _vestingWallets.length; i++) {
            if (_vestingWallets[i].vestingWallet == address(0)) {
                revert VestingWalletInvalidBeneficiary(address(0));
            }

            totalSum += _vestingWallets[i].amount;
        }
        uint256 allowance = IERC20(token).allowance(_safeProxy, address(this));
        if (totalSum != allowance) revert VestingWalletsInvalidAmount();

        vestingWallets = _vestingWallets;
        safeProxy = _safeProxy;
    }

    /// @notice Releases the tokens to the vesting wallets using an ERC20 allowance.
    function release(address token) external {
        for (uint256 i = 0; i < vestingWallets.length; i++) {
            uint256 toRelease = vestingWallets[i].amount;
            address beneficiary = vestingWallets[i].vestingWallet;

            SafeERC20.safeTransferFrom(IERC20(token), safeProxy, beneficiary, toRelease);

            emit ERC20Released(token, beneficiary, toRelease);
        }
    }
}
