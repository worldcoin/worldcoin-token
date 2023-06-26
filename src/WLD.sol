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

    /// @notice The address of the minter
    address public minter;

    /// @notice Inflation variables, formula in _mint @dev description
    uint256 immutable private _inflationCapPeriod;
    uint256 immutable private _inflationCapNumerator;
    uint256 immutable private _inflationCapDenominator;
    uint256 private _currentPeriodEnd;
    uint256 private _currentPeriodInitialSupply;

    /// @notice How many seconds until the mint lock-in period is over
    uint256 immutable private _mintUnlockTime;

    /// @notice The symbol of the token
    string private _symbol;

    /// @notice The name of the token
    string private _name;

    /// @notice Emitted in revert if the mint lock-in period is not over.
    error MintLockInPeriodNotOver();

    /// @notice Emmitted in revert if the caller is not the minter.
    error NotMinter();

    /// @notice Emmitted in revert if the inflation cap has been reached.
    error InflationCapReached();

    /// @notice Emmitted in revert if the owner attempts to resign ownership.
    error CannotRenounceOwnership();

    /// @notice Emitted when constructing the contract
    event TokenDeployed(
        string name,
        string symbol,
        uint256 inflationCapPeriod,
        uint256 inflationCapNumerator,
        uint256 inflationCapDenominator,
        uint256 mintLockPeriod,
        address[] initialHolders,
        uint256[] initialAmounts
    );

    ///////////////////////////////////////////////////////////////////
    ///                         CONSTRUCTOR                         ///
    ///////////////////////////////////////////////////////////////////

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 inflationCapPeriod_,
        uint256 inflationCapNumerator_,
        uint256 inflationCapDenominator_,
        uint256 mintLockPeriod_,
        address[] memory initialHolders,
        uint256[] memory initialAmounts
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        require(inflationCapDenominator_ != 0);
        require(inflationCapPeriod_ != 0);
        _name = name_;
        _symbol = symbol_;
        _inflationCapPeriod = inflationCapPeriod_;
        _inflationCapNumerator = inflationCapNumerator_;
        _inflationCapDenominator = inflationCapDenominator_;
        _mintUnlockTime = mintLockPeriod_ + block.timestamp;
        require(initialAmounts.length == initialHolders.length);
        for (uint256 i = 0; i < initialHolders.length; i++) {
            _update(address(0), initialHolders[i], initialAmounts[i]);
        }
        emit TokenDeployed(
            name_,
            symbol_,
            inflationCapPeriod_,
            inflationCapNumerator_,
            inflationCapDenominator_,
            mintLockPeriod_,
            initialHolders,
            initialAmounts
        );
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

    ///////////////////////////////////////////////////////////////////
    ///                        ADMIN ACTIONS                        ///
    ///////////////////////////////////////////////////////////////////

    /// @notice Sets the name of the token
    /// @param name_ new name
    function setName(string memory name_) external onlyOwner {
        _name = name_;
    }

    /// @notice Sets the token symbol
    /// @param symbol_ new symbol
    function setSymbol(string memory symbol_) external onlyOwner {
        _symbol = symbol_;
    }

    /// @notice Updates minter
    /// @dev onlyOwner
    /// @param minter_ new Minter address
    function setMinter(address minter_) external onlyOwner {
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
    ///     * After the initial supply cap is reached, the inflation cap is in effect.
    ///       The inflation cap is enforced as follows:
    ///       1. If the current time is after the end of the current inflation period,
    ///          it is possible to raise the supply up to (current total supply) * (1 + inflation cap)
    ///          between now and (now + inflation period length), without any additional constraints;
    ///       2. If the current time is before the end of the current inflation period,
    ///          that period's supply is still controlled.
    /// NB: The logic outlined here means that it is possible for period over period inflation
    ///     to reach up to (1 + inflation cap)^2 - 1, for some choices of period boundaries.
    ///     The actual guarantees of this system are:
    ///     1. For any timestamp t0 and a natural number k, inflation measured between t0 and
    ///        t0 + k * inflation period does not exceed (1 + inflation cap)^(k + 1) - 1. In other words,
    ///        there is at most "one too many" inflation periods over any period of time.
    ///     2. For any timestamp t there exists a period tc < inflation period,
    ///        such that inflation measured between (t + tc) and (t + tc + inflation period)
    ///        does not exceed the inflation cap. In other words, period over period inflation is
    ///        bounded by the inflation cap at least for some amount of time during each period.
    function mint(address to, uint256 amount) external {
        require(amount != 0);
        _requireMinter();
        _requirePostMintLockPeriod();
        _adjustCurrentPeriod();
        _requireInflationCap(amount);
        _mint(to, amount);
    }

    /// @notice Checks the inflation period against block timestamp and moves
    /// it forward if it is due.
    function _adjustCurrentPeriod() internal {
        if (block.timestamp > _currentPeriodEnd) {
            _currentPeriodEnd = block.timestamp + _inflationCapPeriod;
            _currentPeriodInitialSupply = totalSupply();
        }
    }

    /// @notice Prevents the minter from minting tokens above the inflation cap.
    /// @param mintAmount The amount of newly minted tokens.
    function _requireInflationCap(
        uint256 mintAmount
    ) internal view {
        uint256 newTotal = totalSupply() + mintAmount;
        if (
            newTotal * _inflationCapDenominator >
            _currentPeriodInitialSupply * (_inflationCapNumerator + _inflationCapDenominator)
        ) {
            revert InflationCapReached();
        }
    }

    /// @notice Requires that the current time is after the mint lock-in period.
    /// @custom:revert MintLockInPeriodNotOver The mint lock-in period is not over.
    function _requirePostMintLockPeriod() internal view {
        if (block.timestamp < _mintUnlockTime) {
            revert MintLockInPeriodNotOver();
        }
    }

    /// @notice Requires that the caller is the minter.
    /// @custom:revert NotMinter The caller is not the minter.
    function _requireMinter() internal view {
        if (_msgSender() != minter) revert NotMinter();
    }
}
