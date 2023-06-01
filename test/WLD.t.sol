// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/WLD.sol";

contract WLDTest is Test {
    uint _initialTime = 1234 seconds;
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

    function setUp() public {
        vm.warp(_initialTime);
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

    modifier asMinter {
        vm.startPrank(_minter);
        _;
        vm.stopPrank();
    }

    function testMintsLockInPeriod() public asMinter {
        vm.expectRevert(bytes("Mint lock-in period not over"));
        _token.mint(address(this), 100);
        vm.warp(_initialTime + _mintLockInPeriod - 1);
        vm.expectRevert(bytes("Mint lock-in period not over"));
        _token.mint(address(this), 100);
        vm.warp(_initialTime + _mintLockInPeriod);
        _token.mint(address(this), 100);
        assert(_token.balanceOf(address(this)) == 100);
    }

    function testInflationCap() public asMinter {
        vm.warp(_initialTime + _mintLockInPeriod);
        // fails – more than initial supply + inflation cap
        vm.expectRevert(bytes("Inflation cap reached"));
        _token.mint(address(this), 101);
        // works – below initial supply + inflation
        _token.mint(address(this), 50); // supply == 1050
        vm.warp(_initialTime + _mintLockInPeriod + 1000 seconds);
        // works - minting up to yearly cap
        _token.mint(address(this), 50); // supply == 1100
        // fails - exceeding yearly cap
        vm.expectRevert(bytes("Inflation cap reached"));
        _token.mint(address(this), 1);
        vm.warp(_initialTime + _mintLockInPeriod + _inflationCapPeriod + 1001 seconds);
        // works - next cap is 110
        _token.mint(address(this), 60); // supply == 1160
        // fails - exceeding yearly cap
        vm.expectRevert(bytes("Inflation cap reached"));
        _token.mint(address(this), 51);
        // succeeds - 50 is still below cap
        _token.mint(address(this), 50); // supply == 1210

        assert(_token.balanceOf(address(this)) == 210);
        assert(_token.totalSupply() == 1210);
    }
}
