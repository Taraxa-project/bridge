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
        if (address(deployerAddress).balance < 2 * Constants.MINIMUM_CONNECTOR_DEPOSIT) {
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

        // check getters
        TaraClient taraClient = TaraClient(taraClientProxy);
        uint256 finalizationIntervalFromClient = taraClient.pillarBlockInterval();
        console.log("Finalization interval from client: %d", finalizationIntervalFromClient);
        require(finalizationIntervalFromClient == finalizationInterval, "Finalization interval mismatch");
        uint256 threshold = taraClient.threshold();
        console.log("Threshold: %d", threshold);
        require(threshold == 3, "Threshold mismatch");

        console.log("TaraClient.sol proxy address: %s", taraClientProxy);
        address taraClientImpl = Upgrades.getImplementationAddress(taraClientProxy);
        console.log("TaraClient.sol implementation address: %s", taraClientImpl);

        address ethBridgeProxy = Upgrades.deployUUPSProxy(
            "EthBridge.sol",
            abi.encodeCall(
                EthBridge.initialize,
                (TestERC20(taraAddressOnEth), IBridgeLightClient(taraClientProxy), finalizationInterval)
            ),
            opts
        );

        // check getters
        EthBridge ethBridge = EthBridge(ethBridgeProxy);
        uint256 finalizationIntervalFromBridge = ethBridge.finalizationInterval();
        console.log("Finalization interval from bridge: %d", finalizationIntervalFromBridge);
        require(finalizationIntervalFromBridge == finalizationInterval, "Finalization interval mismatch");

        console.log("EthBridge.sol proxy address: %s", ethBridgeProxy);
        address ethBridgeImpl = Upgrades.getImplementationAddress(ethBridgeProxy);
        console.log("EthBridge.sol implementation address: %s", ethBridgeImpl);

        address mintingConnectorProxy = Upgrades.deployUUPSProxy(
            "ERC20MintingConnector.sol",
            abi.encodeCall(
                ERC20MintingConnector.initialize,
                (address(ethBridgeProxy), TestERC20(taraAddressOnEth), Constants.NATIVE_TOKEN_ADDRESS)
            ),
            opts
        );

        // check getters
        ERC20MintingConnector mintingConnector = ERC20MintingConnector(payable(mintingConnectorProxy));
        address tokenAddress = mintingConnector.token();
        console.log("Token address: %s", tokenAddress);
        require(tokenAddress == taraAddressOnEth, "Token address mismatch");
        address otherNetworkAddress = mintingConnector.otherNetworkAddress();
        console.log("otherNetworkAddress address: %s", otherNetworkAddress);
        require(otherNetworkAddress == Constants.NATIVE_TOKEN_ADDRESS, "Tara Address on ETH address mismatch");

        console.log("ERC20MintingConnector.sol proxy address: %s", mintingConnectorProxy);
        address mintingConnectorImpl = Upgrades.getImplementationAddress(mintingConnectorProxy);
        console.log("ERC20MintingConnector.sol implementation address: %s", mintingConnectorImpl);

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

        // check getters
        NativeConnector nativeConnector = NativeConnector(payable(nativeConnectorProxy));
        uint256 epoch = nativeConnector.epoch();
        console.log("Epoch: %d", epoch);
        require(epoch == 0, "Epoch mismatch");
        address token = nativeConnector.token();
        console.log("Token: %s", token);
        require(token == Constants.NATIVE_TOKEN_ADDRESS, "Token address mismatch");
        // Fund the MintingConnector with 2 ETH
        (bool success2,) = payable(nativeConnectorProxy).call{value: Constants.MINIMUM_CONNECTOR_DEPOSIT}("");
        if (!success2) {
            revert("Failed to fund the NativeConnector");
        }

        bridge.registerContract(IBridgeConnector(nativeConnectorProxy));
        console.log("NativeConnector.sol proxy address: %s", nativeConnectorProxy);
        address nativeConnectorImpl = Upgrades.getImplementationAddress(nativeConnectorProxy);
        console.log("NativeConnector.sol implementation address: %s", nativeConnectorImpl);
    }
}
