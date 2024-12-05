// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/console.sol";
import "beacon-light-client/src/BeaconLightClient.sol";
import "beacon-light-client/src/BeaconChain.sol";
import {EthClient} from "../src/tara/EthClient.sol";

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";


contract BlcReplace is Script {
    using Bytes for bytes;

    uint256 deployerPrivateKey;
    address deployerAddress;
    address ethClientProxyAddress;

    BeaconLightClient beaconClient;

    function setUp() public {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployerAddress = vm.envAddress("DEPLOYMENT_ADDRESS");
        ethClientProxyAddress = vm.envAddress("ETH_CLIENT_PROXY");
        console.log("Deployer address: %s", deployerAddress);

        if (vm.envUint("PRIVATE_KEY") == 0) {
            revert("Skipping deployment because PRIVATE_KEY is not set");
        }
    }

    function run() public {
        vm.startBroadcast(deployerPrivateKey);

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

        EthClient ethClientProxy = EthClient(ethClientProxyAddress);
        ethClientProxy.setBeaconLightClient(beaconClient);

        vm.stopBroadcast();
    }
}
