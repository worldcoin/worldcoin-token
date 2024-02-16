pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {VestingWallet} from "src/VestingWallet.sol";

contract DeployVestingWallets is Script {
    VestingWallet[] public vestingWallets;
    VestingWallet public vestingWallet;
    address[] public holders;
    uint256[] public amounts;

    uint256 internal privateKey = vm.envUint("PRIVATE_KEY");

    event VestingWalletDeployed(address indexed vestingWallet, address indexed recipient);

    function run() external {
        vm.startBroadcast(privateKey);

        // Import initial holders from old contract
        holders = [address(0x1)];

        uint128 fortyDaysInSeconds = 40 days;

        // 40 day cliff, then released all at once
        uint64 startTimestamp = uint64(block.timestamp + fortyDaysInSeconds);

        uint64 immediateReleaseDuration = 0;

        for (uint256 i = 0; i < holders.length; i++) {
            vestingWallet = new VestingWallet(holders[i], startTimestamp, immediateReleaseDuration);

            vestingWallets.push(vestingWallet);

            emit VestingWalletDeployed(address(vestingWallet), holders[i]);
        }

        vm.stopBroadcast();
    }
}
