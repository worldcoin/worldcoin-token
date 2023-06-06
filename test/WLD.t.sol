// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/WLD.sol";

contract WLDTest is Test {
    ///////////////////////////////////////////////////////////////////
    ///                           STORAGE                           ///
    ///////////////////////////////////////////////////////////////////
    uint256 _initialTime = 1234 seconds;
    string _symbol = "WLD";
    string _name = "Worldcoin";
    uint8 _decimals = 18;
    // setting inflation to 10% YOY
    uint256 _inflationCapPeriod = 31556926 seconds;
    uint256 _inflationCapNumerator = 1;
    uint256 _inflationCapDenominator = 10;
    // one year before minting possible
    uint256 _mintLockInPeriod = 31556926 seconds;
    address[] _initialHolders = [address(0x123), address(0x456)];
    uint256[] _initialAmounts = [500, 500];
    WLD _token;
    address _minter = address(uint160(uint256(keccak256("wld minter"))));

    address _owner = address(0x123);

    /// @notice Emitted in revert if the mint lock-in period is not over.
    error MintLockInPeriodNotOver();

    /// @notice Emmitted in revert if the caller is not the minter.
    error NotMinter();

    /// @notice Emmitted in revert if the inflation cap has been reached.
    error InflationCapReached();

    /// @notice Emmitted in revert if the owner attempts to resign ownership.
    error CannotRenounceOwnership();

    function setUp() public {
        vm.warp(_initialTime);
        vm.startPrank(_owner);
        _token = new WLD(
            _symbol,
            _name,
            _decimals,
            _inflationCapPeriod,
            _inflationCapNumerator,
            _inflationCapDenominator,
            _mintLockInPeriod,
            _initialHolders,
            _initialAmounts
        );
        _token.setMinter(_minter);
    }

    ///////////////////////////////////////////////////////////////////
    ///                          MODIFIERS                          ///
    ///////////////////////////////////////////////////////////////////

    modifier asOwner() {
        vm.startPrank(_owner);
        _;
        vm.stopPrank();
    }

    modifier asMinter() {
        vm.startPrank(_minter);
        _;
        vm.stopPrank();
    }

    ///////////////////////////////////////////////////////////////////
    ///                        ADMIN ACTIONS                        ///
    ///////////////////////////////////////////////////////////////////

    /// @notice Tests that the owner can set a new minter
    function testSetMinterSucceeds(address minter) public asOwner {
        _token.setMinter(minter);

        assert(_token.minter() == minter);
    }

    /// @notice Tests that the owner can set a new name
    function testSetNameSucceeds(string memory name) public asOwner {
        _token.setName(name);

        assert(keccak256(bytes(_token.name())) == keccak256(bytes(name)));
    }

    /// @notice Tests that the owner can set a new symbol
    function testSetSymbol(string memory symbol) public asOwner {
        _token.setSymbol(symbol);

        assert(keccak256(bytes(_token.symbol())) == keccak256(bytes(symbol)));
    }

    /// @notice Tests that the owner can change the decimal precisition of the token (should be 9 or 18).
    function testSetDecimals(uint8 decimals) public {
        vm.assume(decimals > 0);
        _token.setDecimals(decimals);

        assert(_token.decimals() == decimals);
    }

    /// @notice Tests that the minter can mint tokens after the lock-in period.
    function testMintAccessControl(address minter) public {
        vm.assume(minter != _minter);
        vm.warp(_initialTime + _mintLockInPeriod + 20 seconds);

        vm.startPrank(minter);
        vm.expectRevert(NotMinter.selector);
        _token.mint(address(this), 20);
    }

    ///////////////////////////////////////////////////////////////////
    ///                         DISTRIBUTION                        ///
    ///////////////////////////////////////////////////////////////////

    /// @notice Tests that the initial distribution happens correctly.
    function testInitialDistributionHappens() public view {
        assert(_token.balanceOf(address(0x123)) == 500);
        assert(_token.balanceOf(address(0x456)) == 500);
        assert(_token.totalSupply() == 1000);
    }

    /// @notice Tests that the initial distribution is restricted to the initial holders.
    function testInitialDistributionRestricted(address receiver) public view {
        vm.assume(receiver != address(0x123) && receiver != address(0x456));

        assert(_token.balanceOf(receiver) == 0);
    }

    /// @notice Tests that the initial distribution is restricted properly.
    function testMintsLockInPeriod() public asMinter {
        vm.expectRevert(MintLockInPeriodNotOver.selector);
        _token.mint(address(this), 100);
        vm.warp(_initialTime + _mintLockInPeriod - 1);
        vm.expectRevert(MintLockInPeriodNotOver.selector);
        _token.mint(address(this), 100);
        vm.warp(_initialTime + _mintLockInPeriod);
        _token.mint(address(this), 100);
        assert(_token.balanceOf(address(this)) == 100);
    }

    /// @notice Tests that the inflation cap is enforced.
    function testInflationCap() public asMinter {
        vm.warp(_initialTime + _mintLockInPeriod);
        // fails – more than initial supply + inflation cap
        vm.expectRevert(InflationCapReached.selector);
        _token.mint(address(this), 101);
        // works – below initial supply + inflation
        _token.mint(address(this), 50); // supply == 1050
        vm.warp(_initialTime + _mintLockInPeriod + 1000 seconds);
        // works - minting up to yearly cap
        _token.mint(address(this), 50); // supply == 1100
        // fails - exceeding yearly cap
        vm.expectRevert(InflationCapReached.selector);
        _token.mint(address(this), 1);
        vm.warp(_initialTime + _mintLockInPeriod + _inflationCapPeriod + 1001 seconds);
        // works - next cap is 110
        _token.mint(address(this), 60); // supply == 1160
        // fails - exceeding yearly cap
        vm.expectRevert(InflationCapReached.selector);
        _token.mint(address(this), 51);
        // succeeds - 50 is still below cap
        _token.mint(address(this), 50); // supply == 1210

        assert(_token.balanceOf(address(this)) == 210);
        assert(_token.totalSupply() == 1210);
    }

    ///////////////////////////////////////////////////////////////////
    ///                           REVERTS                           ///
    ///////////////////////////////////////////////////////////////////

    function testRenounceOwnershipReverts() public asOwner {
        vm.expectRevert("Cannot renounce ownership");
        _token.renounceOwnership();
    }
}
