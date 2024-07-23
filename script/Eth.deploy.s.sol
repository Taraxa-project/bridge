// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {Constants} from "../src/lib/Constants.sol";
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

    uint256 constant FINALIZATION_INTERVAL = 100;
    uint256 constant FEE_MULTIPLIER_ETH_FINALIZE = 101;
    uint256 constant FEE_MULTIPLIER_ETH_APPLY = 201;
    uint256 constant REGISTRATION_FEE_ETH = 0.001 ether;
    uint256 constant SETTLEMENT_FEE_ETH = 5 gwei;

    function setUp() public {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployerAddress = vm.envAddress("DEPLOYMENT_ADDRESS");
        console.log("Deployer address: %s", deployerAddress);

        if (vm.envUint("PRIVATE_KEY") == 0) {
            revert("Skipping deployment because PRIVATE_KEY is not set");
        }

        if (address(deployerAddress).balance < (2 * REGISTRATION_FEE_ETH)) {
            revert("Skipping deployment because balance is less than 2 *  REGISTRATION_FEE_ETH");
        }

        taraAddressOnEth = vm.envAddress("TARA_ADDRESS_ON_ETH");

        console.log("TARA_ADDRESS_ON_ETH: %s", taraAddressOnEth);
        ethAddressOnTara = vm.envAddress("ETH_ADDRESS_ON_TARA");

        console.log("ETH_ADDRESS_ON_TARA: %s", ethAddressOnTara);

        if (ethAddressOnTara == address(0) || taraAddressOnEth == address(0)) {
            revert("Skipping deployment because ETH_ADDRESS_ON_TARA or TARA_ADDRESS_ON_ETH is not set");
        }
    }

    function run() public {
        vm.startBroadcast(deployerPrivateKey);
        Options memory opts;
        opts.defender.useDefenderDeploy = false;

        address taraClientProxy = Upgrades.deployUUPSProxy(
            "TaraClient.sol", abi.encodeCall(TaraClient.initialize, (FINALIZATION_INTERVAL)), opts
        );

        console.log("TaraClient.sol proxy address: %s", taraClientProxy);
        console.log("TaraClient.sol implementation address: %s", Upgrades.getImplementationAddress(taraClientProxy));

        address ethBridgeProxy = Upgrades.deployUUPSProxy(
            "EthBridge.sol",
            abi.encodeCall(
                EthBridge.initialize,
                (
                    IBridgeLightClient(taraClientProxy),
                    FINALIZATION_INTERVAL,
                    FEE_MULTIPLIER_ETH_FINALIZE,
                    FEE_MULTIPLIER_ETH_APPLY,
                    REGISTRATION_FEE_ETH,
                    SETTLEMENT_FEE_ETH
                )
            ),
            opts
        );

        EthBridge ethBridge = EthBridge(payable(ethBridgeProxy));

        console.log("EthBridge.sol proxy address: %s", ethBridgeProxy);
        console.log("EthBridge.sol implementation address: %s", Upgrades.getImplementationAddress(ethBridgeProxy));

        address mintingConnectorProxy = Upgrades.deployUUPSProxy(
            "ERC20MintingConnector.sol",
            abi.encodeCall(
                ERC20MintingConnector.initialize,
                (ethBridge, TestERC20(taraAddressOnEth), Constants.NATIVE_TOKEN_ADDRESS)
            ),
            opts
        );

        console.log("ERC20MintingConnector.sol proxy address: %s", mintingConnectorProxy);
        console.log(
            "ERC20MintingConnector.sol implementation address: %s",
            Upgrades.getImplementationAddress(mintingConnectorProxy)
        );

        address owner = TestERC20(taraAddressOnEth).owner();
        console.log("Owner: %s", owner);

        // give ownership of erc20 to the connector
        TestERC20(taraAddressOnEth).transferOwnership(mintingConnectorProxy);

        // Add the connector to the bridge
        ethBridge.registerConnector{value: REGISTRATION_FEE_ETH}(IBridgeConnector(mintingConnectorProxy));

        // Instantiate and register the NativeConnector
        address nativeConnectorProxy = Upgrades.deployUUPSProxy(
            "NativeConnector.sol", abi.encodeCall(NativeConnector.initialize, (ethBridge, ethAddressOnTara)), opts
        );

        ethBridge.registerConnector{value: REGISTRATION_FEE_ETH}(IBridgeConnector(nativeConnectorProxy));
        console.log("NativeConnector.sol proxy address: %s", nativeConnectorProxy);
        console.log(
            "NativeConnector.sol implementation address: %s", Upgrades.getImplementationAddress(nativeConnectorProxy)
        );

        vm.stopBroadcast();
    }
}
