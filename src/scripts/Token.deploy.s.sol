// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {EthBridge} from "../eth/EthBridge.sol";
import {TaraClient, PillarBlock} from "../eth/TaraClient.sol";
import {TestERC20} from "../lib/TestERC20.sol";
import {IBridgeLightClient} from "../lib/IBridgeLightClient.sol";
import "../lib/Constants.sol";

contract TokenDeployer is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.envAddress("DEPLOYMENT_ADDRESS");
        string memory symbol = vm.envString("SYMBOL");
        console.log("Symbol: %s", symbol);
        console.log("Deployer address: %s", deployerAddress);
        vm.startBroadcast(deployerPrivateKey);
        TestERC20 te = new TestERC20(symbol);
        console.log("Deployed to:", address(te));
        vm.stopBroadcast();
    }
}
