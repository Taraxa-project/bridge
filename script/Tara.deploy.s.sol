// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/console.sol";
import "beacon-light-client/src/BeaconLightClient.sol";
import "beacon-light-client/src/BeaconChain.sol";

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
// import {Defender, ApprovalProcessResponse} from "openzeppelin-foundry-upgrades/Defender.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import "../src/lib/Constants.sol";
import {EthBridge} from "../src/eth/EthBridge.sol";
import {TaraClient, PillarBlock} from "../src/eth/TaraClient.sol";
import {TestERC20} from "../src/lib/TestERC20.sol";
import {IBridgeLightClient} from "../src/lib/IBridgeLightClient.sol";
import {EthClient} from "../src/tara/EthClient.sol";
import {TaraBridge} from "../src/tara/TaraBridge.sol";
import {NativeConnector} from "../src/connectors/NativeConnector.sol";
import {IBridgeConnector} from "../src/connectors/IBridgeConnector.sol";
import {ERC20MintingConnector} from "../src/connectors/ERC20MintingConnector.sol";

bytes32 constant GENERAL_BRIDGE_ROOT_KEY = 0x0000000000000000000000000000000000000000000000000000000000000008;

contract TaraDeployer is Script {
    using Bytes for bytes;

    uint256 deployerPrivateKey;
    address deployerAddress;
    address taraAddressOnEth;
    address ethAddressOnTara;

    BeaconLightClient beaconClient;

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

    function deployBLC() public {
        uint64 _slot = uint64(vm.envUint("SLOT"));
        uint64 _proposer_index = uint64(vm.envUint("PROPOSER_INDEX"));
        bytes32 _parent_root = vm.envBytes32("PARENT_ROOT");
        bytes32 _state_root = vm.envBytes32("STATE_ROOT");
        bytes32 _body_root = vm.envBytes32("BODY_ROOT");
        uint256 _block_number = vm.envUint("BLOCK_NUMBER");
        bytes32 _merkle_root = vm.envBytes32("MERKLE_ROOT");
        bytes32 _sync_root = vm.envBytes32("SYNC_COMMITTEE_ROOT");
        bytes32 _genesis_validators_root = vm.envBytes32("GENESIS_ROOT");

        // Deploy BeaconLightClient

        console.log("Period: %s", _slot / 32 / 256);
        beaconClient = new BeaconLightClient(
            _slot,
            _proposer_index,
            _parent_root,
            _state_root,
            _body_root,
            _block_number,
            _merkle_root,
            _sync_root,
            _genesis_validators_root
        );

        console.log("BeaconLightClient.sol address: %s", address(beaconClient));
    }

    function deployEthClient() public returns (address ethClientProxy) {
        address ethBridgeAddress = vm.envAddress("ETH_BRIDGE_ADDRESS");
        ethClientProxy = Upgrades.deployUUPSProxy(
            "EthClient.sol", abi.encodeCall(EthClient.initialize, (beaconClient, ethBridgeAddress))
        );

        console.log("EthClient.sol proxy address: %s", ethClientProxy);
        address ethClientImpl = Upgrades.getImplementationAddress(ethClientProxy);
        console.log("EthClient.sol implementation address: %s", ethClientImpl);
        return ethClientProxy;
    }

    function deployTaraBridge(address _ethClientProxy, uint256 _finalizationInterval)
        public
        returns (address taraBrigdeProxy)
    {
        taraBrigdeProxy = Upgrades.deployUUPSProxy(
            "TaraBridge.sol",
            abi.encodeCall(
                TaraBridge.initialize,
                (IBridgeLightClient(_ethClientProxy), _finalizationInterval)
            )
        );

        console.log("TaraBridge.sol proxy address: %s", taraBrigdeProxy);
        console.log("TaraBridge.sol implementation address: %s", Upgrades.getImplementationAddress(taraBrigdeProxy));
        return taraBrigdeProxy;
    }

    function run() public {
        vm.startBroadcast(deployerPrivateKey);

        deployBLC();

        address ethClientProxy = deployEthClient();

        uint256 finalizationInterval = 100;

        address taraBrigdeProxy = deployTaraBridge(ethClientProxy, finalizationInterval);

        address taraConnectorProxy = Upgrades.deployUUPSProxy(
            "NativeConnector.sol", abi.encodeCall(NativeConnector.initialize, (taraBrigdeProxy, taraAddressOnEth))
        );

        // Fund TaraConnector with 2 ETH
        (bool success,) = payable(taraConnectorProxy).call{value: 2 ether}("");

        if (!success) {
            revert("Failed to fund the TaraConnector");
        }

        console.log("NativeConnector.sol proxy address: %s", taraConnectorProxy);
        console.log(
            "NativeConnector.sol implementation address: %s", Upgrades.getImplementationAddress(taraConnectorProxy)
        );

        // Initialize TaraConnector
        TaraBridge(taraBrigdeProxy).registerContract(IBridgeConnector(taraConnectorProxy));

        address ethMintingConnectorProxy = Upgrades.deployUUPSProxy(
            "ERC20MintingConnector.sol",
            abi.encodeCall(
                ERC20MintingConnector.initialize,
                (address(taraBrigdeProxy), TestERC20(ethAddressOnTara), Constants.NATIVE_TOKEN_ADDRESS)
            )
        );

        console.log("ERC20MintingConnector.sol proxy address: %s", ethMintingConnectorProxy);
        console.log(
            "ERC20MintingConnector.sol implementation address: %s",
            Upgrades.getImplementationAddress(ethMintingConnectorProxy)
        );

        // Fund TaraConnector with 2 ETH
        (bool success2,) = payable(ethMintingConnectorProxy).call{value: 2 ether}("");

        if (!success2) {
            revert("Failed to fund the ethMintingConnectorProxy");
        }

        // Initialize EthMintingConnectorProxy
        TaraBridge(taraBrigdeProxy).registerContract(IBridgeConnector(ethMintingConnectorProxy));

        // give ownership of erc20 to the connector
        TestERC20(ethAddressOnTara).transferOwnership(ethMintingConnectorProxy);

        console.log("TaraBridge initialized");

        vm.stopBroadcast();
    }
}
