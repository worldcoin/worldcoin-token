// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {Ownable2Step} from "openzeppelin/access/Ownable2Step.sol";
import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";

/// @title WLD token
/// @notice Contract for Worldcoin's ERC20 WLD token.
/// 
/// It updates from the previous token contract, which is now deprecated. At
/// deployment all existing balances are reinstated.
/// 
/// After deployment, the owner can do a one-time mint of new tokens up to the
/// `INITIAL_SUPPLY_CAP` of 10 billion.
/// 
/// After `inflationUnlockTime` the owner can set the minter address, which can
/// mint new tokens up to the inflation cap. The inflation cap is fixed
/// percentage per period. From this follows a maximum inflation rate per
/// year. Wheter or not to allow inflation can be goverened by the owner through
/// the minter address.
///
/// @author Worldcoin
contract WLD is ERC20, Ownable2Step {
    /////////////////////////////////////////////////////////////////////////
    ///                           PARAMETERS                              ///
    /////////////////////////////////////////////////////////////////////////

    uint256 constant public INITIAL_SUPPLY_CAP = 10 * (10**9) * (10**18);

    /// @notice Has the initial mint been done?
    bool public initialMintDone;

    /// @notice The address of the inflation minter
    address public minter;

    /// @notice Inflation variables, formula in _mint @dev description
    uint256 immutable public inflationUnlockTime;
    uint256 immutable public inflationCapPeriod;
    uint256 immutable public inflationCapNumerator;
    uint256 immutable public inflationCapDenominator;
    uint256 public currentPeriodEnd;
    uint256 public currentPeriodInitialSupply;

    /// @notice How many seconds until the mint lock-in period is over

    /////////////////////////////////////////////////////////////////////////
    ///                             EVENTS                                ///
    /////////////////////////////////////////////////////////////////////////

    /// @notice Emitted in revert if the mint lock-in period is not over.
    error MintLockInPeriodNotOver();

    /// @notice Emmitted in revert if the caller is not the minter.
    error NotMinter();

    /// @notice Emmitted in revert if the inflation cap has been reached.
    error InflationCapReached();

    /// @notice Emmitted in revert if the owner attempts to resign ownership.
    error CannotRenounceOwnership();

    /// @notice Emitted when constructing the contract
    event TokenUpdated(
        address newToken,
        string name,
        string symbol,
        address[] existingHolders,
        uint256[] existingsAmounts,
        uint256 inflationCapPeriod,
        uint256 inflationCapNumerator,
        uint256 inflationCapDenominator,
        uint256 mintLockPeriod
    );

    /// @notice Emitted when minting tokens. Can be emited once.
    event TokensMinted(
        address minter,
        address[] newHolders,
        uint256[] newAmounts
    );

    /////////////////////////////////////////////////////////////////////////
    ///                           CONSTRUCTOR                             ///
    /////////////////////////////////////////////////////////////////////////

    /// @notice Deploy a new token contract that replaces an existing one.
    constructor(
        address[] memory existingHolders,
        uint256[] memory existingAmounts,
        string memory name_,
        string memory symbol_,
        uint256 inflationCapPeriod_,
        uint256 inflationCapNumerator_,
        uint256 inflationCapDenominator_,
        uint256 mintLockPeriod_
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        // Validate input.
        require(existingAmounts.length == existingHolders.length);
        require(inflationCapDenominator_ != 0);
        require(inflationCapPeriod_ != 0);

        initialMintDone = false;
        minter = address(0);
        inflationCapPeriod = inflationCapPeriod_;
        inflationCapNumerator = inflationCapNumerator_;
        inflationCapDenominator = inflationCapDenominator_;
        inflationUnlockTime = mintLockPeriod_ + block.timestamp;

        // Reinstate balances
        for (uint256 i = 0; i < existingHolders.length; i++) {
            _update(address(0), existingHolders[i], existingAmounts[i]);
        }

        // Make sure the initial supply cap is maintained.
        require(totalSupply() <= INITIAL_SUPPLY_CAP);

        // Emit event.
        emit TokenUpdated(
            address(this),
            name_,
            symbol_,
            existingHolders,
            existingAmounts,
            inflationCapPeriod_,
            inflationCapNumerator_,
            inflationCapDenominator_,
            mintLockPeriod_
        );
    }

    /////////////////////////////////////////////////////////////////////////
    ///                           OWNER ACTIONS                           ///
    /////////////////////////////////////////////////////////////////////////

    /// @notice Mint new tokens.
    function mintOnce(
        address[] memory newHolders,
        uint256[] memory newAmounts
    ) external onlyOwner {
        // This must be the only time we allow this.
        require(initialMintDone == false);

        // Validate input.
        require(newHolders.length == newAmounts.length);

        // Mark initial mint as done.
        initialMintDone = true;

        // Mint tokens.
        for (uint256 i = 0; i < newHolders.length; i++) {
            _mint(newHolders[i], newAmounts[i]);
        }

        // Make sure the initial supply cap is maintained.
        require(totalSupply() <= INITIAL_SUPPLY_CAP);

        emit TokensMinted(
            msg.sender,
            newHolders,
            newAmounts
        );
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
        if (block.timestamp > currentPeriodEnd) {
            currentPeriodEnd = block.timestamp + inflationCapPeriod;
            currentPeriodInitialSupply = totalSupply();
        }
    }

    /// @notice Prevents the minter from minting tokens above the inflation cap.
    /// @param mintAmount The amount of newly minted tokens.
    function _requireInflationCap(
        uint256 mintAmount
    ) internal view {
        uint256 newTotal = totalSupply() + mintAmount;
        if (
            newTotal * inflationCapDenominator >
            currentPeriodInitialSupply * (inflationCapNumerator + inflationCapDenominator)
        ) {
            revert InflationCapReached();
        }
    }

    /// @notice Requires that the current time is after the mint lock-in period.
    /// @custom:revert MintLockInPeriodNotOver The mint lock-in period is not over.
    function _requirePostMintLockPeriod() internal view {
        if (block.timestamp < inflationUnlockTime) {
            revert MintLockInPeriodNotOver();
        }
    }

    /// @notice Requires that the caller is the minter.
    /// @custom:revert NotMinter The caller is not the minter.
    function _requireMinter() internal view {
        if (_msgSender() != minter) {
            revert NotMinter();
        }
    }
}
