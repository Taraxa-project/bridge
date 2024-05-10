// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {EthBridge} from "../eth/EthBridge.sol";
import {TaraClient, PillarBlock} from "../eth/TaraClient.sol";
import {TestERC20} from "../lib/TestERC20.sol";
import {IBridgeLightClient} from "../lib/IBridgeLightClient.sol";
import "../lib/Constants.sol";

contract EthDeployer is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.envAddress("DEPLOYMENT_ADDRESS");
        console.log("Deployer address: %s", deployerAddress);
        vm.startBroadcast(deployerPrivateKey);

        address taraAddressOnEth = vm.envAddress("TARA_ADDRESS_ON_ETH");
        console.log("TARA_ADDRESS_ON_ETH: %s", taraAddressOnEth);
        address ethAddressOnTara = vm.envAddress("ETH_ADDRESS_ON_TARA");
        console.log("ETH_ADDRESS_ON_TARA: %s", ethAddressOnTara);

        uint256 finalizationInterval = 100;
        TaraClient client = new TaraClient(3, finalizationInterval);

        console.log("Tara Client address: %s", address(client));

        EthBridge bridge = new EthBridge{value: Constants.MINIMUM_CONNECTOR_DEPOSIT}(
            TestERC20(taraAddressOnEth), ethAddressOnTara, IBridgeLightClient(client), finalizationInterval
        );

        console.log("Bridge address: %s", address(bridge));

        vm.stopBroadcast();
    }
}
