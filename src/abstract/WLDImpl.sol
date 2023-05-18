// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable2StepUpgradeable} from "openzeppelin-upgradeable/access/Ownable2StepUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";

abstract contract WLDImpl is Ownable2StepUpgradeable, UUPSUpgradeable {
    function __WLDImpl_init() internal virtual onlyInitializing {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    error CannotRenounceOwnership();

    function renounceOwnership() public view virtual override onlyOwner {
        revert CannotRenounceOwnership();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyProxy onlyOwner {
        // No body needed as `onlyOwner` handles it.
    }
}
