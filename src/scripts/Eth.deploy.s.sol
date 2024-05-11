// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import "../lib/Constants.sol";
import {EthBridge} from "../eth/EthBridge.sol";
import {TaraClient, PillarBlock} from "../eth/TaraClient.sol";
import {TestERC20} from "../lib/TestERC20.sol";
import {IBridgeLightClient} from "../lib/IBridgeLightClient.sol";
import {ERC20MintingConnector} from "../connectors/ERC20MintingConnector.sol";
import {IBridgeConnector} from "../connectors/IBridgeConnector.sol";

contract EthDeployer is Script {
    function setUp() public {}

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

        Options memory opts;
        opts.defender.useDefenderDeploy = false;

        address taraClientProxy = Upgrades.deployUUPSProxy(
            "TaraClient.sol", abi.encodeCall(TaraClient.initialize, (3, finalizationInterval)), opts
        );

        console.log("Deployed TaraClient proxy to address", taraClientProxy);

        address ethBridgeProxy = Upgrades.deployUUPSProxy(
            "EthBridge.sol",
            abi.encodeCall(
                EthBridge.initialize,
                (TestERC20(taraAddress), IBridgeLightClient(taraClientProxy), finalizationInterval)
            ),
            opts
        );

        console.log("Deployed EthBridge proxy to address", ethBridgeProxy);

        address mintingConnectorProxy = Upgrades.deployUUPSProxy(
            "ERC20MintingConnector.sol",
            abi.encodeCall(
                ERC20MintingConnector.initialize, (address(ethBridgeProxy), TestERC20(taraAddress), taraAddress)
            ),
            opts
        );

        console.log("Deployed ERC20MintingConnector proxy to address", mintingConnectorProxy);

        // Fund the MintingConnector with 2 ETH
        (bool success,) = payable(mintingConnectorProxy).call{value: Constants.MINIMUM_CONNECTOR_DEPOSIT}("");
        if (!success) {
            revert("Failed to fund the MintingConnector");
        }

        // Add the connector to the bridge
        EthBridge bridge = EthBridge(ethBridgeProxy);
        bridge.registerContract(IBridgeConnector(mintingConnectorProxy));
    }
}
