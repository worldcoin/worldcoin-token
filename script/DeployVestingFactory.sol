pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {VestingFactory} from "src/VestingFactory.sol";

contract DeployVestingRouter is Script {
    /// @notice WLD token address on Optimism mainnet.
    address public immutable WLD_TOKEN = address(0xdC6fF44d5d932Cbd77B52E5612Ba0529DC6226F1);

    /// TODO: Fill in real values
    address[] public vestingWalletAddresses = [address(0x1)];
    uint256[] public amounts = [uint256(0x1)];
    uint64[] public startTimestamps = [uint64(0x1)];
    uint64[] public durationSeconds = [uint64(0x1)];

    VestingFactory public router;

    uint256 internal _privateKey = vm.envUint("PRIVATE_KEY");
    address public safeProxy = vm.envAddress("SAFE_PROXY");
    address public owner = vm.envAddress("FACTORY_OWNER");

    function run() external {
        VestingFactory.VestingWalletInfo[] memory vestingWallets;

        for (uint256 i = 0; i < vestingWalletAddresses.length; i++) {
            vestingWallets[i] = VestingFactory.VestingWalletInfo({
                amount: amounts[i],
                beneficiary: vestingWalletAddresses[i],
                startTimestamp: startTimestamps[i],
                durationSeconds: durationSeconds[i]
            });
        }

        vm.startBroadcast(_privateKey);

        router = new VestingFactory(safeProxy, owner);

        router.createVestingWallets(WLD_TOKEN, vestingWallets);

        vm.stopBroadcast();
    }
}
