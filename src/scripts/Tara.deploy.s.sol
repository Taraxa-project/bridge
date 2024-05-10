// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/console.sol";
import "beacon-light-client/src/BeaconLightClient.sol";
import "beacon-light-client/src/BeaconChain.sol";

import {Script} from "forge-std/Script.sol";
import {EthBridge} from "../eth/EthBridge.sol";
import {TaraClient, PillarBlock} from "../eth/TaraClient.sol";
import {TestERC20} from "../lib/TestERC20.sol";
import {IBridgeLightClient} from "../lib/IBridgeLightClient.sol";
import {EthClient} from "../tara/EthClient.sol";
import {TaraBridge} from "../tara/TaraBridge.sol";
import "../lib/Constants.sol";

contract TaraDeployer is Script {
    using Bytes for bytes;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.envAddress("DEPLOYMENT_ADDRESS");
        console.log("Deployer address: %s", deployerAddress);
        vm.startBroadcast(deployerPrivateKey);

        // Deploy BeaconLightClient

        uint64 _slot = uint64(vm.envUint("SLOT"));
        uint64 _proposer_index = uint64(vm.envUint("PROPOSER_INDEX"));
        bytes32 _parent_root = vm.envBytes32("PARENT_ROOT");
        bytes32 _state_root = vm.envBytes32("STATE_ROOT");
        bytes32 _body_root = vm.envBytes32("BODY_ROOT");
        uint256 _block_number = vm.envUint("BLOCK_NUMBER");
        bytes32 _merkle_root = vm.envBytes32("MERKLE_ROOT");
        bytes32 _sync_root = vm.envBytes32("SYNC_COMMITTEE_ROOT");
        console.log("Period: %s", _slot / 32 / 256);

        bytes32 _genesis_validators_root = 0x9143aa7c615a7f7115e2b6aac319c03529df8242ae705fba9df39b79c59fa8b1;

        BeaconLightClient beaconClient = new BeaconLightClient(
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

        console.log("Beacon Client address: %s", address(beaconClient));

        address ethBridgeAddress = vm.envAddress("ETH_BRIDGE_ADDRESS");
        EthClient ethClient = new EthClient(beaconClient, ethBridgeAddress);

        console.log("Client wrapper address: %s", address(ethClient));

        address taraAddressOnEth = vm.envAddress("TARA_ADDRESS_ON_ETH");
        console.log("TARA_ADDRESS_ON_ETH: %s", taraAddressOnEth);
        address ethAddressOnTara = vm.envAddress("ETH_ADDRESS_ON_TARA");
        console.log("ETH_ADDRESS_ON_TARA: %s", ethAddressOnTara);

        uint256 finalizationInterval = 100;
        TaraBridge taraBridge = new TaraBridge{value: Constants.MINIMUM_CONNECTOR_DEPOSIT}(
            TestERC20(ethAddressOnTara), taraAddressOnEth, IBridgeLightClient(address(ethClient)), finalizationInterval
        );

        console.log("TARA Bridge address: %s", address(taraBridge));

        vm.stopBroadcast();
    }
}
