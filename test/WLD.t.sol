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
    address[] _initialHolders = [address(0x123), address(0x456)];
    uint256[] _initialAmounts = [501, 502];
    address[] _nextHolders = [address(0x789), address(0xABC)];
    uint256[] _nextAmounts = [503, 504];
    WLD _token;
    address _onceMinter = address(uint160(uint256(keccak256("onceMinter"))));

    function setUp() public {
        _token = new WLD(
            _initialHolders,
            _initialAmounts,
            _symbol,
            _name,
            _onceMinter
        );
    }

    function secondDistribution() public {
        vm.prank(_onceMinter, address(0x123));
        _token.mintOnce(_nextHolders, _nextAmounts);
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

    function testFailCanMintOnlyOnce() public {
        secondDistribution();
        vm.prank(_onceMinter, address(0x123));
        _token.mintOnce(_nextHolders, _nextAmounts);
    }

    function testFailOnlyOnceMinter(address other) public {
        vm.assume(other != _onceMinter);
        vm.prank(other, address(0x123));
        _token.mintOnce(_nextHolders, _nextAmounts);
    }

    function testSecondDistribution() public {
        vm.prank(_onceMinter, address(0x123));
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
        WLD token = new WLD(holders, amounts, _symbol, _name, _onceMinter);
        for (uint256 i = 0; i < 100; i++) {
            assert(token.balanceOf(holders[i]) == 1000 + i);
        }
        assert(token.totalSupply() == 100*1000 + 100*(100-1)/2);

        // Second
        for (uint256 i = 0; i < 100; i++) {
            holders[i] = address(uint160(uint256(keccak256(abi.encode(2**128 + i)))));
            amounts[i] = 2000 + i;
        }
        vm.prank(_onceMinter);
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
        WLD token = new WLD(holders, amounts, _symbol, _name, _onceMinter);
    }

    function testFailCapSecond() public {
        WLD token = new WLD(_initialHolders, _initialAmounts, _symbol, _name, _onceMinter);
        address[] memory holders = _nextHolders;
        uint256[] memory amounts = _nextAmounts;
        amounts[1] = 10**10 * 10**18;
        vm.prank(_onceMinter);
        token.mintOnce(holders, amounts);
    }
}
