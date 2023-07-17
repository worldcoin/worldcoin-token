// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/WLD.sol";

contract WLDTest is Test {
    ///////////////////////////////////////////////////////////////////
    ///                           STORAGE                           ///
    ///////////////////////////////////////////////////////////////////
    string _symbol = "WLD";
    string _name = "Worldcoin";
    // setting inflation to 10% YOY
    uint256 _initialTime = 1234 seconds;
    uint256 _inflationCapPeriod = 31556926 seconds;
    uint256 _inflationCapNumerator = 1;
    uint256 _inflationCapDenominator = 10;
    // one year before minting possible
    uint256 _mintLockInPeriod = 31556926 seconds;
    address[] _initialHolders = [address(0x123), address(0x456)];
    uint256[] _initialAmounts = [501, 502];
    address[] _nextHolders = [address(0x789), address(0xABC)];
    uint256[] _nextAmounts = [503, 504];

    WLD _token;
    address _owner = address(0x123);
    address _minter = address(uint160(uint256(keccak256("wld minter"))));

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

    function setUp() public asOwner() {
        vm.warp(_initialTime);
        _token = new WLD(
            _initialHolders,
            _initialAmounts,
            _symbol,
            _name,
            _inflationCapPeriod,
            _inflationCapNumerator,
            _inflationCapDenominator,
            _mintLockInPeriod
        );
        _token.setMinter(_minter);
    }

    function secondDistribution() public asOwner() {
        _token.mintOnce(_nextHolders, _nextAmounts);
    }

    ///////////////////////////////////////////////////////////////////
    ///                        ADMIN ACTIONS                        ///
    ///////////////////////////////////////////////////////////////////

    /// @notice Tests that the owner can set a new minter
    function testSetMinterSucceeds(address minter) public asOwner {
        _token.setMinter(minter);

        assert(_token.minter() == minter);
    }

    /// @notice Tests that the decimals are hardcoded to 18.
    function testDecimals() public view {
        assert(_token.decimals() == 18);
    }

    /// @notice Tests that the minter can mint tokens after the lock-in period.
    function testMintAccessControl(address minter) public {
        vm.assume(minter != _minter);
        vm.warp(_initialTime + _mintLockInPeriod + 20 seconds);

        vm.prank(minter);
        vm.expectRevert();
        _token.mint(address(this), 20);
    }

    ///////////////////////////////////////////////////////////////////
    ///                         DISTRIBUTION                        ///
    ///////////////////////////////////////////////////////////////////

    /// @notice Tests that the initial distribution happens correctly.
    function testInitialDistributionHappens() public view {
        assert(_token.balanceOf(address(0x123)) == 501);
        assert(_token.balanceOf(address(0x456)) == 502);
        assert(_token.totalSupply() == 1003);
    }

    /// @notice Tests that the initial distribution is restricted to the initial holders.
    function testInitialDistributionRestricted(address receiver) public view {
        vm.assume(receiver != address(0x123) && receiver != address(0x456));

        assert(_token.balanceOf(receiver) == 0);
    }

    function testCanMintOnce() public {
        secondDistribution();
    }

    /// @notice Tests that the initial distribution is restricted properly.
    function testMintsLockInPeriod() public asMinter {
        // fails – lock-in period not over
        vm.expectRevert();
        _token.mint(address(this), 100);

        // fails – lock-in period not over
        vm.warp(_initialTime + _mintLockInPeriod - 1);
        vm.expectRevert();
        _token.mint(address(this), 100);
        
        // works – lock-in period over
        vm.warp(_initialTime + _mintLockInPeriod);
        _token.mint(address(this), 100);

        // assert(_token.balanceOf(address(this)) == 100);
    }

    /// @notice Tests that the inflation cap is enforced.
    function testInflationCap() public asMinter {
        vm.warp(_initialTime + _mintLockInPeriod);
        
        // fails – more than initial supply + inflation cap
        vm.expectRevert();
        _token.mint(address(this), 101);

        // works – below initial supply + inflation
        _token.mint(address(this), 50); // supply == 1050
        vm.warp(_initialTime + _mintLockInPeriod + 1000 seconds);
        
        // works - minting up to yearly cap
        _token.mint(address(this), 50); // supply == 1100
        
        // fails - exceeding yearly cap
        vm.expectRevert();
        _token.mint(address(this), 1);
        vm.warp(_initialTime + _mintLockInPeriod + _inflationCapPeriod + 1001 seconds);
        
        // works - next cap is 110
        _token.mint(address(this), 60); // supply == 1160
        
        // fails - exceeding yearly cap
        vm.expectRevert();
        _token.mint(address(this), 51);

        // succeeds - 50 is still below cap
        _token.mint(address(this), 50); // supply == 1210

        assert(_token.balanceOf(address(this)) == 210);
        assert(_token.totalSupply() == 1213);
    }

    ///////////////////////////////////////////////////////////////////
    ///                           REVERTS                           ///
    ///////////////////////////////////////////////////////////////////

    function testFailCanMintOnlyOnce() public asMinter() {
        secondDistribution();
        _token.mintOnce(_nextHolders, _nextAmounts);
    }

    function testFailOnlyOnceMinter(address other) public {
        vm.assume(other != _owner);
        vm.prank(other, address(0x123));
        _token.mintOnce(_nextHolders, _nextAmounts);
    }

    function testSecondDistribution() public asOwner() {
        _token.mintOnce(_initialHolders, _initialAmounts);
        assert(_token.balanceOf(address(0x123)) == 501*2);
        assert(_token.balanceOf(address(0x456)) == 502*2);
        assert(_token.totalSupply() == 1003*2);
    }

    function testSecondDistributionAdditive() public {
        secondDistribution();
        assert(_token.balanceOf(address(0x123)) == 501);
        assert(_token.balanceOf(address(0x456)) == 502);
        assert(_token.balanceOf(address(0x789)) == 503);
        assert(_token.balanceOf(address(0xABC)) == 504);
        assert(_token.totalSupply() == 2010);
    }

    function testSecondDistributionRestricted(address receiver) public {
        secondDistribution();
        vm.assume(receiver != address(0x123) && receiver != address(0x456));
        vm.assume(receiver != address(0x789) && receiver != address(0xABC));
        assert(_token.balanceOf(receiver) == 0);
    }

    function testLargeDistribution() public {
        address[] memory holders = new address[](100);
        uint256[] memory amounts = new uint256[](100);

        // Initial
        for (uint256 i = 0; i < 100; i++) {
            holders[i] = address(uint160(uint256(keccak256(abi.encode(i)))));
            amounts[i] = 1000 + i;
        }
        WLD token = new WLD(holders, amounts, _symbol, _name, _inflationCapPeriod, _inflationCapNumerator, _inflationCapDenominator, _mintLockInPeriod);
        for (uint256 i = 0; i < 100; i++) {
            assert(token.balanceOf(holders[i]) == 1000 + i);
        }
        assert(token.totalSupply() == 100*1000 + 100*(100-1)/2);

        // Second
        for (uint256 i = 0; i < 100; i++) {
            holders[i] = address(uint160(uint256(keccak256(abi.encode(2**128 + i)))));
            amounts[i] = 2000 + i;
        }
        token.mintOnce(holders, amounts);
        for (uint256 i = 0; i < 100; i++) {
            assert(token.balanceOf(holders[i]) == 2000 + i);
        }
        assert(token.totalSupply() == 100*3000 + 2*100*(100-1)/2);
    }

    function testFailCapInitial() public {
        address[] memory holders = _initialHolders;
        uint256[] memory amounts = _initialAmounts;
        amounts[1] = 10**10 * 10**18;
        WLD token = new WLD(holders, amounts, _symbol, _name, _inflationCapPeriod, _inflationCapNumerator, _inflationCapDenominator, _mintLockInPeriod);
    }

    function testFailCapSecond() public {
        WLD token = new WLD(_initialHolders, _initialAmounts, _symbol, _name, _inflationCapPeriod, _inflationCapNumerator, _inflationCapDenominator, _mintLockInPeriod);
        address[] memory holders = _nextHolders;
        uint256[] memory amounts = _nextAmounts;
        amounts[1] = 10**10 * 10**18;
        vm.startPrank(_owner);
        token.mintOnce(holders, amounts);
        vm.stopPrank();
    }
}
