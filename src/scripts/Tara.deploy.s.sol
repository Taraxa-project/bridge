// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/console.sol";
import "beacon-light-client/src/BeaconLightClient.sol";
import "beacon-light-client/src/BeaconChain.sol";

import {Script} from "forge-std/Script.sol";
// import {Defender, ApprovalProcessResponse} from "openzeppelin-foundry-upgrades/Defender.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import "../lib/Constants.sol";
import {EthBridge} from "../eth/EthBridge.sol";
import {TaraClient, PillarBlock} from "../eth/TaraClient.sol";
import {TestERC20} from "../lib/TestERC20.sol";
import {IBridgeLightClient} from "../lib/IBridgeLightClient.sol";
import {EthClient} from "../tara/EthClient.sol";
import {TaraBridge} from "../tara/TaraBridge.sol";
import {NativeConnector} from "../connectors/NativeConnector.sol";
import {IBridgeConnector} from "../connectors/IBridgeConnector.sol";
import {ERC20MintingConnector} from "../connectors/ERC20MintingConnector.sol";

contract TaraDeployer is Script {
    using Bytes for bytes;

    function setUp() public {}

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

        // ApprovalProcessResponse memory upgradeApprovalProcess = Defender.getUpgradeApprovalProcess();

        // if (upgradeApprovalProcess.via == address(0)) {
        //     revert(
        //         string.concat(
        //             "Upgrade approval process with id ",
        //             upgradeApprovalProcess.approvalProcessId,
        //             " has no assigned address"
        //         )
        //     );
        // }

        Options memory opts;
        opts.defender.useDefenderDeploy = false;
        opts.unsafeSkipAllChecks = true;

        address ethBridgeAddress = vm.envAddress("ETH_BRIDGE_ADDRESS");
        address ethClientProxy = Upgrades.deployUUPSProxy(
            "EthClient.sol", abi.encodeCall(EthClient.initialize, (beaconClient, ethBridgeAddress)), opts
        );

        console.log("Deployed EthClient proxy to address", ethClientProxy);

        address taraAddressOnEth = vm.envAddress("TARA_ADDRESS_ON_ETH");
        console.log("TARA_ADDRESS_ON_ETH: %s", taraAddressOnEth);
        address ethAddressOnTara = vm.envAddress("ETH_ADDRESS_ON_TARA");
        console.log("ETH_ADDRESS_ON_TARA: %s", ethAddressOnTara);

        uint256 finalizationInterval = 100;

        address taraBrigdeProxy = Upgrades.deployUUPSProxy(
            "TaraBridge.sol",
            abi.encodeCall(
                TaraBridge.initialize,
                (TestERC20(ethAddressOnTara), IBridgeLightClient(address(ethClientProxy)), finalizationInterval)
            ),
            opts
        );

        console.log("Deployed TaraBridge proxy to address", taraBrigdeProxy);

        address taraConnectorProxy = Upgrades.deployUUPSProxy(
            "NativeConnector.sol", abi.encodeCall(NativeConnector.initialize, (taraBrigdeProxy, taraAddressOnEth)), opts
        );

        // Fund TaraConnector with 2 ETH
        (bool success,) = payable(taraConnectorProxy).call{value: 2 ether}("");

        if (!success) {
            revert("Failed to fund the TaraConnector");
        }

        console.log("Deployed TaraConnector proxy to address", taraConnectorProxy);

        TaraBridge taraBridge = TaraBridge(taraBrigdeProxy);

        // Initialize TaraConnector
        taraBridge.registerContract(IBridgeConnector(taraConnectorProxy));

        address ethMintingConnectorProxy = Upgrades.deployUUPSProxy(
            "ERC20MintingConnector.sol",
            abi.encodeCall(
                ERC20MintingConnector.initialize,
                (address(taraBrigdeProxy), TestERC20(ethAddressOnTara), Constants.NATIVE_TOKEN_ADDRESS)
            ),
            opts
        );

        console.log("Deployed ERC20MintingConnector proxy to address", ethMintingConnectorProxy);

        // Fund TaraConnector with 2 ETH
        (bool success2,) = payable(ethMintingConnectorProxy).call{value: 2 ether}("");

        if (!success) {
            revert("Failed to fund the ethMintingConnectorProxy");
        }

        console.log("Deployed ethMintingConnectorProxy proxy to address", ethMintingConnectorProxy);

        // Initialize EthMintingConnectorProxy
        taraBridge.registerContract(IBridgeConnector(ethMintingConnectorProxy));

        console.log("TaraBridge initialized");

        vm.stopBroadcast();
    }
}
