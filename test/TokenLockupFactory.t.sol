// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "openzeppelin/utils/math/Math.sol";
import { ERC20 } from "openzeppelin/token/ERC20/ERC20.sol";
import "../src/TokenLockupFactory.sol";
import "../src/VestingWallet.sol";

contract TestToken is ERC20{
    constructor (string memory _name, string memory _symbol) ERC20 (_name,_symbol){}

    function mint(address to, uint256 amount) public virtual {
        _mint(to,amount);
    }
}

contract TokenLockupFactoryTest is Test {
    address _owner = address(uint160(uint256(keccak256("owner"))));
    address _beneficiary = address(uint160(uint256(keccak256("beneficiary"))));
    uint256 _amount = 1 ether;
    TestToken _token;
    TokenLockupFactory _factory;

    function setUp() public {
        _token = new TestToken("Test", "TEST");
        _token.mint(_owner, type(uint256).max);
        _factory = new TokenLockupFactory(_owner);
        vm.prank(_owner);
        _token.approve(address(_factory), _amount);
    }

    function _transferHelper(address beneficiary, uint256 amount) private {
        TokenLockupFactory.TransferInfo[] memory transferInfos = new TokenLockupFactory.TransferInfo[](1);

        transferInfos[0] = TokenLockupFactory.TransferInfo({
            amount: amount,
            beneficiary: beneficiary
        });

        _factory.transfer(address(_token), transferInfos);
    }

    function testTransfer() public {
        vm.prank(_owner);
        _transferHelper(_beneficiary, _amount);
    }

    function testTransferExceedingAllowance() public {
        vm.prank(_owner);
        vm.expectRevert();
        _transferHelper(_beneficiary, _amount + 1);
    }

    function testTransferNotOwner() public {
        vm.expectRevert();
        _transferHelper(_beneficiary, _amount);
    }

    function testReleaseInTime() public {
        vm.prank(_owner);
        _transferHelper(_beneficiary, _amount);

        // Address of deployed VestingWallet should stay constant
        VestingWallet wallet = VestingWallet(address(0xffD4505B3452Dc22f8473616d50503bA9E1710Ac));

        vm.warp(40 days + 1 minutes);
        vm.prank(_beneficiary);
        wallet.release(address(_token));

        assertEq(_token.balanceOf(_beneficiary), _amount);
    }

    function testReleaseTooEarly() public {
        vm.prank(_owner);
        _transferHelper(_beneficiary, _amount);

        // Address of deployed VestingWallet should stay constant
        VestingWallet wallet = VestingWallet(address(0xffD4505B3452Dc22f8473616d50503bA9E1710Ac));

        vm.warp(39 days);
        vm.prank(_beneficiary);
        wallet.release(address(_token));

        assertEq(_token.balanceOf(_beneficiary), 0);
    }
}
