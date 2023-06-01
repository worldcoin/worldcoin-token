// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable2Step} from "openzeppelin/access/Ownable2Step.sol";
import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";
import "forge-std/console.sol";


contract WLD is ERC20, Ownable2Step {
    struct SupplyInfo {
        uint256 timestamp;
        uint256 amount;
    }

    uint256 private _inflationCapPeriod;
    uint256 private _inflationCapNumerator;
    uint256 private _inflationCapDenominator;
    uint256 private _mintLockInPeriod;
    uint256 private _inflationPeriodCursor;
    string private _symbol;
    string private _name;
    uint8 private _decimals;
    address private _minter;
    SupplyInfo[] private _supplyHistory;

    // ********************
    // *** Construction ***
    // ********************

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 inflationCapPeriod_,
        uint256 inflationCapNumerator_,
        uint256 inflationCapDenominator_,
        uint256 mintLockInPeriod_,
        address[] memory initialHolders,
        uint256[] memory initialAmounts
    ) ERC20(name_, symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _inflationCapPeriod = inflationCapPeriod_;
        _inflationCapNumerator = inflationCapNumerator_;
        _inflationCapDenominator = inflationCapDenominator_;
        _mintLockInPeriod = mintLockInPeriod_;
        _inflationPeriodCursor = 0;
        require(initialAmounts.length == initialHolders.length);
        for (uint256 i = 0; i < initialHolders.length; i++) {
            _mint(initialHolders[i], initialAmounts[i]);
        }
        _supplyHistory.push(SupplyInfo(block.timestamp, totalSupply()));
    }

    // ****************
    // *** Metadata ***
    // ****************

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    // *********************
    // *** Admin actions ***
    // *********************

    function setName(string memory name_) public onlyOwner {
        _name = name_;
    }

    function setSymbol(string memory symbol_) public onlyOwner {
        _symbol = symbol_;
    }

    function setDecimals(uint8 decimals_) public onlyOwner {
        _decimals = decimals_;
    }

    function renounceOwnership() public view override onlyOwner {
        revert("Cannot renounce ownership");
    }

    function setMinter(address minter_) public onlyOwner {
        _minter = minter_;
    }

    // **********************
    // *** Minter Actions ***
    // **********************

    /// @notice Mints new tokens and assigns them to the target address.
    /// @dev This function performs inflation checks. Their semantics is as follows:
    ///     * It is impossible to mint any tokens during the first `_mintLockInPeriod` seconds
    ///     * After the initial supply cap is reached, the inflation cap is in effect,
    ///       making sure that the total supply of tokens does not increase by more than
    ///       `1 + (inflationCapNumerator / inflationCapDenominator)` times during any
    ///       `_inflationCapPeriod` seconds period.
    function mint(address to, uint256 amount) public {
        _requireMinter();
        _requirePostMintLockInPeriod();
        _advanceInflationPeriodCursor();
        uint256 oldTotal = _getTotalSupplyYearAgo();
        uint256 newTotal = totalSupply() + amount;
        _requireInflationCap(oldTotal, newTotal);
        _supplyHistory.push(SupplyInfo(block.timestamp, newTotal));
        _mint(to, amount);
    }

    function _requireInflationCap(
        uint256 oldTotal,
        uint256 newTotal
    ) internal view {
        require(
            newTotal * _inflationCapDenominator <=
                oldTotal * (_inflationCapNumerator + _inflationCapDenominator),
            "Inflation cap reached"
        );
    }

    function _advanceInflationPeriodCursor() internal {
        uint256 currentTimestamp = block.timestamp;
        uint256 currentPosition = _inflationPeriodCursor;
        // Advancing the cursor until the first of:
        // * we reach the end of the array, or
        // * we reach the first timestamp such that the next timestamp is
        //   younger than _inflationCapPeriod.
        // That means that the cursor will point to the youngest timestamp that
        // is older than said period, i.e. the supply at _inflationCapPeriod ago.
        while (
            currentPosition + 1 < _supplyHistory.length &&
            _supplyHistory[currentPosition + 1].timestamp +
                _inflationCapPeriod <
            currentTimestamp
        ) {
            currentPosition += 1;
        }
        _inflationPeriodCursor = currentPosition;
    }

    function _getTotalSupplyYearAgo() internal view returns (uint256) {
        return _supplyHistory[_inflationPeriodCursor].amount;
    }

    function _requireMinter() internal view {
        require(_msgSender() == _minter, "Caller is not the minter");
    }

    function _getConstructionTime() internal view returns (uint256) {
        return _supplyHistory[0].timestamp;
    }

    function _requirePostMintLockInPeriod() internal view {
        require(
            block.timestamp >= _getConstructionTime() + _mintLockInPeriod,
            "Mint lock-in period not over"
        );
    }
}
