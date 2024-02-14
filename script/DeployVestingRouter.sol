pragma solidity ^0.8.24;

import { Script } from "forge-std/Script.sol";
import { VestingRouter } from "src/VestingRouter.sol";

contract DeployVestingRouter is Script {
    /// @notice WLD token address on Optimism mainnet.
    address public immutable WLD_TOKEN = address(0xdC6fF44d5d932Cbd77B52E5612Ba0529DC6226F1);

    /// TODO: Fill in real values
    address[] public vestingWalletAddresses = [address(0x1)];
    uint256[] public amounts = [uint256(0x1)];

    VestingRouter public router;

    uint256 internal privateKey = vm.envUint("PRIVATE_KEY");

    function run() external {
        VestingRouter.VestingWalletInfo[] memory vestingWallets;

        for (uint256 i = 0; i < vestingWalletAddresses.length; i++) {
            vestingWallets[i] = VestingRouter.VestingWalletInfo(vestingWalletAddresses[i], amounts[i]);
        }

        vm.startBroadcast(privateKey);

        router = new VestingRouter(address(0x1), WLD_TOKEN, vestingWallets);

        vm.stopBroadcast();
    }

    function createVestingWallets() public returns (VestingRouter.VestingWalletInfo[] memory vestingWallets) { }
}
