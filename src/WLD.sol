// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Ownable } from "openzeppelin/access/Ownable.sol";
import { Ownable2Step } from "openzeppelin/access/Ownable2Step.sol";
import { ERC20 } from "openzeppelin/token/ERC20/ERC20.sol";

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
/// percentage per period. From this it follows a maximum inflation rate per
/// year. Whether or not to allow inflation can be goverened by the owner through
/// the minter address.
///
/// @author Worldcoin
contract WLD is ERC20, Ownable2Step {
    /////////////////////////////////////////////////////////////////////////
    ///                           PARAMETERS                              ///
    /////////////////////////////////////////////////////////////////////////

    uint256 public constant INITIAL_SUPPLY_CAP = 10_000_000_000 * (10 ** 18);
    uint256 public constant WAD_ONE = 10 ** 18;

    /// @notice Has the initial mint been done?
    bool public initialMintDone;

    /// @notice The address of the inflation minter
    address public minter;

    /// @notice Inflation parameters, formula in _mint @dev description
    uint256 public immutable inflationUnlockTime;
    uint256 public immutable inflationCapPeriod;
    uint256 public immutable inflationCapWad;

    /// @notice Inflation cap state variables
    uint256 public currentPeriodEnd;
    uint256 public currentPeriodSupplyCap;

    /////////////////////////////////////////////////////////////////////////
    ///                             EVENTS                                ///
    /////////////////////////////////////////////////////////////////////////

    /// @notice Emitted when constructing the contract
    event TokenUpdated(
        address newToken,
        string name,
        string symbol,
        address[] existingHolders,
        uint256[] existingsAmounts,
        uint256 inflationCapPeriod,
        uint256 inflationCapWad,
        uint256 inflationLockPeriod
    );

    /// @notice Emitted when minting tokens. Can be emited only once.
    event TokensMinted(address minter, address[] newHolders, uint256[] newAmounts);

    /// @notice Emitted when inflation tokens are minted, after the initial mint.
    event InflationTokensMinted(address minter, address to, uint256 amount);

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
        uint256 inflationCapWad_,
        uint256 inflationLockPeriod_
    )
        ERC20(name_, symbol_)
        Ownable(msg.sender)
    {
        // Validate input.
        require(existingAmounts.length == existingHolders.length);
        require(inflationCapPeriod_ != 0);

        // Allow one initial mint
        initialMintDone = false;

        // Set the inflation cap parameters
        minter = address(0);
        inflationCapPeriod = inflationCapPeriod_;
        inflationCapWad = inflationCapWad_;
        inflationUnlockTime = inflationLockPeriod_ + block.timestamp;

        // Make sure a new inflation period starts on first call to mint.
        currentPeriodEnd = 0;
        currentPeriodSupplyCap = 0;

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
            inflationCapWad_,
            inflationLockPeriod_
        );
    }

    /////////////////////////////////////////////////////////////////////////
    ///                           OWNER ACTIONS                           ///
    /////////////////////////////////////////////////////////////////////////

    /// @notice Mint new tokens.
    function mintOnce(address[] memory newHolders, uint256[] memory newAmounts) external onlyOwner {
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

        emit TokensMinted(msg.sender, newHolders, newAmounts);
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
        revert();
    }

    ///////////////////////////////////////////////////////////////////
    ///                        MINTER ACTIONS                       ///
    ///////////////////////////////////////////////////////////////////

    /// @notice Mints new tokens and assigns them to the target address.
    /// @dev This function performs inflation checks. Their semantics is as follows:
    ///     * It is impossible to mint any tokens during the first `inflationLockPeriod_` seconds.
    //        The end of the lock period is stored in `inflationUnlockTime`.
    ///     * T inflation cap is in effect.
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
    function mintInflation(address to, uint256 amount) external {
        // Validate input
        require(to != address(0));
        require(amount != 0);

        // Must be minter
        require(msg.sender == minter);

        // Requires that the current time is after the mint lock-in period
        require(block.timestamp >= inflationUnlockTime);

        // Stars a new inflation period if the previous one ended
        if (block.timestamp > currentPeriodEnd) {
            // Update inflation period end
            currentPeriodEnd = block.timestamp + inflationCapPeriod;

            // Compute maximum supply for this period
            uint256 initialSupply = totalSupply();
            uint256 mintable = (initialSupply * inflationCapWad) / WAD_ONE;
            currentPeriodSupplyCap = initialSupply + mintable;
        }

        // Mint inflation tokens
        _mint(to, amount);

        // Check amount against inflation cap for this period
        require(totalSupply() <= currentPeriodSupplyCap);

        // Emit event
        emit InflationTokensMinted(msg.sender, to, amount);
    }
}
