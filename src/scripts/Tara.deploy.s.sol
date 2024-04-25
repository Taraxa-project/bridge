// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/console.sol";
import "beacon-light-client/src/BeaconLightClient.sol";

import {Script} from "forge-std/Script.sol";
import {EthBridge} from "../eth/EthBridge.sol";
import {TaraClient, PillarBlock} from "../eth/TaraClient.sol";
import {TestERC20} from "../lib/TestERC20.sol";
import {IBridgeLightClient} from "../lib/ILightClient.sol";
import {EthClient} from "../tara/EthClient.sol";
import {TaraBridge} from "../tara/TaraBridge.sol";

contract TaraDeployer is Script {
    using Bytes for bytes;
    using BLS12FP for Bls12Fp;

    uint256 constant SYNC_COMMITTEE_SIZE = 512;
    uint64 constant BLSPUBLICKEY_LENGTH = 48;

    uint256 constant FINALIZATION_INTERVAL = 100;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.envAddress("DEPLOYMENT_ADDRESS");
        console.log("Deployer address: %s", deployerAddress);
        vm.startBroadcast(deployerPrivateKey);

        // Deploy BeaconLightClient

        uint64 _slot = 1312501;
        uint64 _proposer_index = 1245949;
        bytes32 _parent_root = 0xefb41a2fdac5228e048509618ce3eac9345edf6d6c9d37a6d8f63b482482ac6f;
        bytes32 _state_root = 0x427f9c9c52e7dfa08f6404ccd93d9aef6a3f12f98efd7ab41110962a325a7d60;
        bytes32 _body_root = 0x6f661f79ecbb820a9d6059e8c3745e810e5a4dc75c084658e0a2471189f63654;
        uint256 _block_number = 1312501;
        bytes32 _merkle_root = 0x542b4b41fcfbe910a43b852d77ba5b87a6b6499759d51b4b583496fce13baafa;

        bytes memory _current_sync_committee_aggregated_pubkey = vm.envBytes("AGGREGATED_PUBLIC_KEY");
        bytes32 _genesis_validators_root = 0x9143aa7c615a7f7115e2b6aac319c03529df8242ae705fba9df39b79c59fa8b1;

        BeaconLightClient client = new BeaconLightClient(
            _slot,
            _proposer_index,
            _parent_root,
            _state_root,
            _body_root,
            _block_number,
            _merkle_root,
            keccak256(_current_sync_committee_aggregated_pubkey),
            _genesis_validators_root
        );

        console.log("Client address: %s", address(client));

        address taraAddress = vm.envAddress("ETH_TARA_ADDRESS");
        console.log("ETH address: %s", taraAddress);

        TaraBridge taraBridge = new TaraBridge{value: 2 ether}(
            taraAddress,
            IBridgeLightClient(address(client)),
            FINALIZATION_INTERVAL
        );

        console.log("TARA Bridge address: %s", address(taraBridge));

        address _eth_bridge_address = vm.envAddress("ETH_BRIDGE_ADDRESS");

        EthClient wrapper = new EthClient(
            client,
            _eth_bridge_address
        );

        console.log("Wrapper address: %s", address(wrapper));

        vm.stopBroadcast();
    }
}
