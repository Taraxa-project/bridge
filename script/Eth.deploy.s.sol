// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import "../src/lib/Constants.sol";
import {EthBridge} from "../src/eth/EthBridge.sol";
import {TaraClient, PillarBlock} from "../src/eth/TaraClient.sol";
import {TestERC20} from "../src/lib/TestERC20.sol";
import {IBridgeLightClient} from "../src/lib/IBridgeLightClient.sol";
import {ERC20MintingConnector} from "../src/connectors/ERC20MintingConnector.sol";
import {IBridgeConnector} from "../src/connectors/IBridgeConnector.sol";
import {NativeConnector} from "../src/connectors/NativeConnector.sol";

contract EthDeployer is Script {
    address public deployerAddress;
    address public taraAddressOnEth;
    address public ethAddressOnTara;
    uint256 public deployerPrivateKey;
    uint256 public finalizationInterval = 100;

    function setUp() public {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployerAddress = vm.envAddress("DEPLOYMENT_ADDRESS");
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

        taraAddressOnEth = vm.envAddress("TARA_ADDRESS_ON_ETH");
        console.log("TARA_ADDRESS_ON_ETH: %s", taraAddressOnEth);
        ethAddressOnTara = vm.envAddress("ETH_ADDRESS_ON_TARA");
        console.log("ETH_ADDRESS_ON_TARA: %s", ethAddressOnTara);
    }

    function run() public {
        vm.startBroadcast(deployerPrivateKey);
        Options memory opts;
        opts.defender.useDefenderDeploy = false;

        address taraClientProxy = Upgrades.deployUUPSProxy(
            "TaraClient.sol", abi.encodeCall(TaraClient.initialize, (3, finalizationInterval)), opts
        );

        console.log("TaraClient.sol proxy address: %s", taraClientProxy);
        console.log("TaraClient.sol implementation address: %s", Upgrades.getImplementationAddress(taraClientProxy));

        address ethBridgeProxy = Upgrades.deployUUPSProxy(
            "EthBridge.sol",
            abi.encodeCall(
                EthBridge.initialize,
                (TestERC20(taraAddressOnEth), IBridgeLightClient(taraClientProxy), finalizationInterval)
            ),
            opts
        );

        console.log("EthBridge.sol proxy address: %s", ethBridgeProxy);
        console.log("EthBridge.sol implementation address: %s", Upgrades.getImplementationAddress(ethBridgeProxy));

        address mintingConnectorProxy = Upgrades.deployUUPSProxy(
            "ERC20MintingConnector.sol",
            abi.encodeCall(
                ERC20MintingConnector.initialize,
                (address(ethBridgeProxy), TestERC20(taraAddressOnEth), Constants.NATIVE_TOKEN_ADDRESS)
            ),
            opts
        );

        console.log("ERC20MintingConnector.sol proxy address: %s", mintingConnectorProxy);
        console.log(
            "ERC20MintingConnector.sol implementation address: %s",
            Upgrades.getImplementationAddress(mintingConnectorProxy)
        );

        // Fund the MintingConnector with 2 ETH
        (bool success,) = payable(mintingConnectorProxy).call{value: Constants.MINIMUM_CONNECTOR_DEPOSIT}("");
        if (!success) {
            revert("Failed to fund the MintingConnector");
        }

        address owner = TestERC20(taraAddressOnEth).owner();
        console.log("Owner: %s", owner);

        // give ownership of erc20 to the connector
        TestERC20(taraAddressOnEth).transferOwnership(mintingConnectorProxy);

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
        console.log("NativeConnector.sol proxy address: %s", nativeConnectorProxy);
        console.log(
            "NativeConnector.sol implementation address: %s", Upgrades.getImplementationAddress(nativeConnectorProxy)
        );

        vm.stopBroadcast();
    }
}
