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
    uint256[] _initialAmounts = [500, 500];
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
}
