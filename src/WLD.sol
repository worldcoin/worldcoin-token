// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {Ownable2Step} from "openzeppelin/access/Ownable2Step.sol";
import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";

/// @title WLD token
/// @author Worldcoin
/// @notice Contract for Worldcoin's ERC20 WLD token
contract WLD is ERC20, Ownable2Step {
    ///////////////////////////////////////////////////////////////////
    ///                           STORAGE                           ///
    ///////////////////////////////////////////////////////////////////

    /// @notice Information about the supply of the WLD token at a given point in time
    struct SupplyInfo {
        uint256 timestamp;
        uint256 amount;
    }

    /// @notice The address of the minter
    address public minter;

    /// @notice Inflation variables, formula in _mint @dev description
    uint256 private _inflationCapPeriod;
    uint256 private _inflationCapNumerator;
    uint256 private _inflationCapDenominator;
    uint256 private _inflationPeriodCursor;

    /// @notice How many seconds until the mint lock-in period is over
    uint256 private _mintLockInPeriod;

    /// @notice The symbol of the token
    string private _symbol;

    /// @notice The name of the token
    string private _name;

    /// @notice The number of decimals for the WLD token
    uint8 private _decimals;

    /// @notice The history of the WLD token's supply
    SupplyInfo[] public supplyHistory;

    /// @notice Emitted in revert if the mint lock-in period is not over.
    error MintLockInPeriodNotOver();

    /// @notice Emmitted in revert if the caller is not the minter.
    error NotMinter();

    /// @notice Emmitted in revert if the inflation cap has been reached.
    error InflationCapReached();

    /// @notice Emmitted in revert if the owner attempts to resign ownership.
    error CannotRenounceOwnership();

    ///////////////////////////////////////////////////////////////////
    ///                          MODIFIERS                          ///
    ///////////////////////////////////////////////////////////////////

    /// @notice Requires that the current time is after the mint lock-in period.
    /// @custom:revert MintLockInPeriodNotOver The mint lock-in period is not over.
    modifier onlyPostMintLockInPeriod() {
        if (block.timestamp < _getConstructionTime() + _mintLockInPeriod) {
            revert MintLockInPeriodNotOver();
        }

        _;
    }

    /// @notice Requires that the caller is the minter.
    /// @custom:revert NotMinter The caller is not the minter.
    modifier onlyMinter() {
        if (_msgSender() != minter) revert NotMinter();
        _;
    }

    ///////////////////////////////////////////////////////////////////
    ///                         CONSTRUCTOR                         ///
    ///////////////////////////////////////////////////////////////////

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
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
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
            _update(address(0), initialHolders[i], initialAmounts[i]);
        }
        supplyHistory.push(SupplyInfo(block.timestamp, totalSupply()));
    }

    ///////////////////////////////////////////////////////////////////
    ///                           METADATA                          ///
    ///////////////////////////////////////////////////////////////////

    /// @notice Returns the name of the token
    function name() public view override returns (string memory) {
        return _name;
    }

    /// @notice Returns that symbol of the token
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /// @notice Returns the number of decimals for the token
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    ///////////////////////////////////////////////////////////////////
    ///                        ADMIN ACTIONS                        ///
    ///////////////////////////////////////////////////////////////////

    /// @notice Sets the name of the token
    /// @param name_ new name
    function setName(string memory name_) public onlyOwner {
        _name = name_;
    }

    /// @notice Sets the token symbol
    /// @param symbol_ new symbol
    function setSymbol(string memory symbol_) public onlyOwner {
        _symbol = symbol_;
    }

    /// @notice Sets the token decimals
    /// @param decimals_ new decimals
    function setDecimals(uint8 decimals_) public onlyOwner {
        _decimals = decimals_;
    }

    /// @notice Updates minter
    /// @dev onlyOwner
    /// @param minter_ new Minter address
    function setMinter(address minter_) public onlyOwner {
        minter = minter_;
    }

    /// @notice Prevents the owner from renouncing ownership
    /// @dev onlyOwner
    function renounceOwnership() public view override onlyOwner {
        revert CannotRenounceOwnership();
    }

    ///////////////////////////////////////////////////////////////////
    ///                        MINTER ACTIONS                       ///
    ///////////////////////////////////////////////////////////////////

    /// @notice Mints new tokens and assigns them to the target address.
    /// @dev This function performs inflation checks. Their semantics is as follows:
    ///     * It is impossible to mint any tokens during the first `_mintLockInPeriod` seconds
    ///     * After the initial supply cap is reached, the inflation cap is in effect,
    ///       making sure that the total supply of tokens does not increase by more than
    ///       `1 + (inflationCapNumerator / inflationCapDenominator)` times during any
    ///       `_inflationCapPeriod` seconds period.
    function mint(address to, uint256 amount) public onlyMinter onlyPostMintLockInPeriod {
        _advanceInflationPeriodCursor();
        uint256 oldTotal = _getTotalSupplyInflationPeriodAgo();
        uint256 newTotal = totalSupply() + amount;
        _requireInflationCap(oldTotal, newTotal);
        supplyHistory.push(SupplyInfo(block.timestamp, newTotal));
        _mint(to, amount);
    }

    /// @notice Prevents the minter from minting tokens above the inflation cap.
    /// @param oldTotal The total supply before the requested mint
    /// @param newTotal The total supply after the requested mint
    function _requireInflationCap(uint256 oldTotal, uint256 newTotal) internal view {
        if (newTotal * _inflationCapDenominator > oldTotal * (_inflationCapNumerator + _inflationCapDenominator)) {
            revert InflationCapReached();
        }
    }

    /// @notice Advances the inflation period cursor to the _inflationPeriodCursor by 1.
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
            currentPosition + 1 < supplyHistory.length
                && supplyHistory[currentPosition + 1].timestamp + _inflationCapPeriod < currentTimestamp
        ) {
            currentPosition += 1;
        }
        _inflationPeriodCursor = currentPosition;
    }

    /// @notice Returns the total supply .
    function _getTotalSupplyInflationPeriodAgo() internal view returns (uint256) {
        return supplyHistory[_inflationPeriodCursor].amount;
    }

    /// @notice Returns the supply at the time of construction.
    function _getConstructionTime() internal view returns (uint256) {
        return supplyHistory[0].timestamp;
    }
}
