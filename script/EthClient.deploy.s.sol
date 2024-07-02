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
import {TaraBridgeSettable} from "../src/tara/TaraBridgeSettable.sol";

contract EthClientUpgraderDeployer is Script {
    using Bytes for bytes;

    uint256 deployerPrivateKey;
    address deployerAddress;
    address taraAddressOnEth;
    address ethAddressOnTara;
    address taraBridgeProxy;
    address ethBridgeAddress;

    BeaconLightClient beaconClient;

    function setUp() public {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployerAddress = vm.envAddress("DEPLOYMENT_ADDRESS");
        console.log("Deployer address: %s", deployerAddress);

        if (vm.envUint("PRIVATE_KEY") == 0) {
            revert("Skipping deployment because PRIVATE_KEY is not set");
        }

        taraAddressOnEth = vm.envAddress("TARA_ADDRESS_ON_ETH");
        console.log("TARA_ADDRESS_ON_ETH: %s", taraAddressOnEth);
        ethAddressOnTara = vm.envAddress("ETH_ADDRESS_ON_TARA");
        console.log("ETH_ADDRESS_ON_TARA: %s", ethAddressOnTara);
        taraBridgeProxy = vm.envAddress("TARA_BRIDGE_PROXY");
        console.log("TARA_BRIDGE_PROXY: %s", taraBridgeProxy);
        ethBridgeAddress = vm.envAddress("ETH_BRIDGE_ADDRESS");
        console.log("ETH_BRIDGE_ADDRESS: %s", ethBridgeAddress);
        if (taraAddressOnEth == address(0) || ethAddressOnTara == address(0) || taraBridgeProxy == address(0) || ethBridgeAddress == address(0)) {
            revert("Skipping deployment because TARA_ADDRESS_ON_ETH or ETH_ADDRESS_ON_TARA or TARA_BRIDGE_PROXY or ETH_BRIDGE_ADDRESS is not set");
        }
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
        ethClientProxy = Upgrades.deployUUPSProxy(
            "EthClient.sol", abi.encodeCall(EthClient.initialize, (beaconClient, ethBridgeAddress))
        );

        console.log("EthClient.sol proxy address: %s", ethClientProxy);
        address ethClientImpl = Upgrades.getImplementationAddress(ethClientProxy);
        console.log("EthClient.sol implementation address: %s", ethClientImpl);
        return ethClientProxy;
    }

    function setNewEthClient(address _ethClientProxy)
        public
    {
        TaraBridgeSettable taraBridge = TaraBridgeSettable(payable(taraBridgeProxy));
        IBridgeLightClient oldEthClient = taraBridge.lightClient();
        console.log("Old EthClient.sol proxy address: %s", address(oldEthClient));
        taraBridge.setLightClient(IBridgeLightClient(_ethClientProxy));

        IBridgeLightClient newEthClient = taraBridge.lightClient();
        console.log("New EthClient.sol proxy address: %s", address(newEthClient));
        require(address(newEthClient)  != address(oldEthClient), "New EthClient.sol proxy address cannot be the same as the old one");
    }

    function run() public {
        vm.startBroadcast(deployerPrivateKey);

        deployBLC();

        address ethClientProxy = deployEthClient();

        setNewEthClient(ethClientProxy);
        console.log("TaraBridge ETHClient implementation upgraded");

        vm.stopBroadcast();
    }
}
