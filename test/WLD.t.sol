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
    address[] _initialHolders = [address(0x123), address(0x456)];
    uint256[] _initialAmounts = [500, 500];
    WLD _token;
    address _owner = address(0x123);

    /// @notice Emmitted in revert if the owner attempts to resign ownership.
    error CannotRenounceOwnership();

    function setUp() public {
        vm.warp(_initialTime);
        vm.startPrank(_owner);
        _token = new WLD(
            _symbol,
            _name,
            _initialHolders,
            _initialAmounts
        );
        vm.stopPrank();
    }

    ///////////////////////////////////////////////////////////////////
    ///                          MODIFIERS                          ///
    ///////////////////////////////////////////////////////////////////

    modifier asOwner() {
        vm.startPrank(_owner);
        _;
        vm.stopPrank();
    }

    ///////////////////////////////////////////////////////////////////
    ///                        ADMIN ACTIONS                        ///
    ///////////////////////////////////////////////////////////////////


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

    /// @notice Tests that the decimals are hardcoded to 18.
    function testDecimals() public view {
        assert(_token.decimals() == 18);
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

    ///////////////////////////////////////////////////////////////////
    ///                           REVERTS                           ///
    ///////////////////////////////////////////////////////////////////

    function testRenounceOwnershipReverts() public asOwner {
        vm.expectRevert(CannotRenounceOwnership.selector);
        _token.renounceOwnership();
    }
}
