pragma solidity ^0.8.24;

import { Script } from "forge-std/Script.sol";
import { TokenLockupFactory } from "src/TokenLockupFactory.sol";

contract DeployTokenLockupFactory is Script {
    address public immutable WLD_TOKEN = vm.envAddress("TOKEN_ADDRESS");
    address public owner = vm.envAddress("FACTORY_OWNER");

    function run() external {
        vm.startBroadcast();

        new TokenLockupFactory(owner);

        vm.stopBroadcast();
    }
}
