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
import {NativeConnector} from "../connectors/NativeConnector.sol";

contract EthDeployer is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.envAddress("DEPLOYMENT_ADDRESS");
        console.log("Deployer address: %s", deployerAddress);

        if (vm.envUint("PRIVATE_KEY") == 0) {
            console.log("Skipping deployment because PRIVATE_KEY is not set");
            return;
        }
        // check if balance is at least 2 * MINIMUM_CONNECTOR_DEPOSIT
        if (address(this).balance < 2 * Constants.MINIMUM_CONNECTOR_DEPOSIT) {
            console.log("Skipping deployment because balance is less than 2 * MINIMUM_CONNECTOR_DEPOSIT");
            return;
        }

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
                (TestERC20(taraAddressOnEth), IBridgeLightClient(taraClientProxy), finalizationInterval)
            ),
            opts
        );

        console.log("Deployed EthBridge proxy to address", ethBridgeProxy);

        address mintingConnectorProxy = Upgrades.deployUUPSProxy(
            "ERC20MintingConnector.sol",
            abi.encodeCall(
                ERC20MintingConnector.initialize,
                (address(ethBridgeProxy), TestERC20(taraAddressOnEth), Constants.NATIVE_TOKEN_ADDRESS)
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

        // Instantiate and register the NativeConnector
        address nativeConnectorProxy = Upgrades.deployUUPSProxy(
            "NativeConnector.sol", abi.encodeCall(NativeConnector.initialize, (address(bridge), ethAddressOnTara)), opts
        );

        // Fund the MintingConnector with 2 ETH
        (bool success2,) = payable(nativeConnectorProxy).call{value: Constants.MINIMUM_CONNECTOR_DEPOSIT}("");
        if (!success2) {
            revert("Failed to fund the NativeConnector");
        }

        bridge.registerContract(IBridgeConnector(nativeConnectorProxy));
    }
}
