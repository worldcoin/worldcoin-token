// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IWLD} from "./interfaces/IWLD.sol";
import {WLDImpl} from "./abstract/WLDImpl.sol";
import {ERC20Upgradeable} from "openzeppelin-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract WLDImplV1 is IWLD, WLDImpl, ERC20Upgradeable {
    struct SupplyInfo {
        uint256 timestamp;
        uint256 amount;
    }

    uint256 constant YEAR_IN_SECONDS = 31556926;
    uint256 initialSupplyCap;
    uint256 inflationCapNumerator;
    uint256 inflationCapDenominator;
    uint256 yearAgoCursor;
    SupplyInfo[] supplyHistory;

    function initialize(
        uint256 _initialSupplyCap,
        uint256 _inflationCapNumerator,
        uint256 _inflationCapDenominator
    ) public reinitializer(1) {
        __WLDImpl_init();
        __ERC20_init("Worldcoin", "WLD");

        initialSupplyCap = _initialSupplyCap;
        inflationCapNumerator = _inflationCapNumerator;
        inflationCapDenominator = _inflationCapDenominator;
        yearAgoCursor = 0;
    }

    /// @notice Mints new tokens and assigns them to the target address.
    /// @dev This function performs inflation checks. Their semantics is as follows:
    ///     * The initial supply cap is the maximum amount of tokens that can
    ///       be minted at any time, at operator's discretion.
    ///     * After the initial supply cap is reached, the inflation cap is in effect,
    ///       making sure that the total supply of tokens does not increase by more than
    ///       `1 + (inflationCapNumerator / inflationCapDenominator)` times during any
    ///       31556926 seconds (approx. 1 year) period. 
    function mint(
        address to,
        uint256 amount
    ) public virtual onlyProxy onlyOwner {
        uint256 currentTotal = totalSupply();
        uint256 newTotal = currentTotal + amount;
        if (currentTotal < initialSupplyCap) {
            // We're still in the initial phase.
            if (newTotal >= initialSupplyCap) {
                // Reaching or crossing the initial supply cap for the first
                // time. Record this with the current timestamp – for the next
                // year, this will be the amount to compare against.
                supplyHistory.push(
                    SupplyInfo(block.timestamp, initialSupplyCap)
                );
            }
            if (newTotal > initialSupplyCap) {
                // Crossing the initial supply cap. Need to check for inflation and record final amount.
                _requireInflationCap(initialSupplyCap, newTotal);
                supplyHistory.push(SupplyInfo(block.timestamp, newTotal));
            }
            // New total is still below the initial supply cap. No need to do anything else.
        } else {
            // We're already in the inflation-controls phase.
            _advanceYearAgoCursor();
            uint256 totalSupplyYearAgo = _getTotalSupplyYearAgo();
            _requireInflationCap(totalSupplyYearAgo, newTotal);
            supplyHistory.push(SupplyInfo(block.timestamp, newTotal));
        }
        _mint(to, amount);
    }

    function _requireInflationCap(
        uint256 oldTotal,
        uint256 newTotal
    ) internal view virtual onlyProxy {
        require(
            newTotal * inflationCapDenominator <=
                oldTotal * (inflationCapNumerator + inflationCapDenominator),
            "WLD: inflation cap reached"
        );
    }

    function _advanceYearAgoCursor() internal virtual onlyProxy {
        uint256 currentTimestamp = block.timestamp;
        uint256 currentPosition = yearAgoCursor;
        // Advancing the cursor until the first of:
        // * we reach the end of the array, or
        // * we reach the first timestamp such that the next timestamp is younger than a year.
        // That means that the cursor will point to the youngest timestamp that is older than a year, i.e. the supply at one year ago.
        while (
            currentPosition + 1 < supplyHistory.length &&
            supplyHistory[currentPosition + 1].timestamp + YEAR_IN_SECONDS <
            currentTimestamp
        ) {
            currentPosition += 1;
        }
        yearAgoCursor = currentPosition;
    }

    function _getTotalSupplyYearAgo()
        internal
        view
        virtual
        onlyProxy
        returns (uint256)
    {
        return supplyHistory[yearAgoCursor].amount;
    }
}
