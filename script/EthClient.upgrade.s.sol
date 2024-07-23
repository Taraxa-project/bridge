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
import {EthClientV2} from "../src/tara/EthClientV2.sol";

contract EthClientUpgraderDeployer is Script {
    using Bytes for bytes;

    uint256 deployerPrivateKey;
    address deployerAddress;

    BeaconLightClient beaconClient;

    function setUp() public {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployerAddress = vm.envAddress("DEPLOYMENT_ADDRESS");
        console.log("Deployer address: %s", deployerAddress);

        if (vm.envUint("PRIVATE_KEY") == 0) {
            revert("Skipping deployment because PRIVATE_KEY is not set");
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

    function upgradeEthClient(address _ethClientProxy) public {
        address implAddressV1 = Upgrades.getImplementationAddress(address(_ethClientProxy));

        require(implAddressV1 != address(0), "implAddressV1 is not set");
        address initBLCAddress = address(EthClient(payable(_ethClientProxy)).client());
        console.log("initBLCAddress", initBLCAddress);

        Upgrades.upgradeProxy(
            _ethClientProxy, "EthClientV2.sol", (abi.encodeCall(EthClientV2.setBeaconLightClient, beaconClient))
        );

        address implAddressV2 = Upgrades.getImplementationAddress(address(_ethClientProxy));

        console.log("implAddressV1", implAddressV1);
        console.log("implAddressV2", implAddressV2);

        address newBLCAddress = address(EthClientV2(payable(_ethClientProxy)).client());
        console.log("newBLCAddress", newBLCAddress);

        require(implAddressV2 != address(0), "implAddressV2 is not set");
        require(implAddressV2 != implAddressV1, "implAddressV2 is the same as implAddressV1");
        require(newBLCAddress != address(0), "newBLCAddress is not set");
        require(newBLCAddress != initBLCAddress, "newBLCAddress is the same as initBLCAddress");
    }

    function run() public {
        vm.startBroadcast(deployerPrivateKey);

        deployBLC();

        address ethClientProxy = 0x9814b171aCa172B7a7ABDdDa6a42c0aCCa8fBABb;

        upgradeEthClient(ethClientProxy);
        console.log("TaraBridge ETHClient implementation upgraded");

        vm.stopBroadcast();
    }
}
