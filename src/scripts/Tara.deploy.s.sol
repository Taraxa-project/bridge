// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/console.sol";
import "beacon-light-client/src/BeaconLightClient.sol";
import "beacon-light-client/src/BeaconChain.sol";

import "forge-std/console.sol";
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

bytes32 constant GENERAL_BRIDGE_ROOT_KEY = 0x0000000000000000000000000000000000000000000000000000000000000005;

contract TaraDeployer is Script {
    using Bytes for bytes;

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

        bytes32 _genesis_validators_root = 0x81d0ed09d41d51e35a4e98f777e5f906996115f26fd72be32b5fb0caa82c287b;

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

        console.log("BeaconLightClient.sol address: %s", address(beaconClient));

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

        // check getters
        EthClient ethClient = EthClient(ethClientProxy);

        bytes32 bridgeRootKeyFromClient = ethClient.bridgeRootKey();
        console.logBytes32(bridgeRootKeyFromClient);
        require(bridgeRootKeyFromClient == GENERAL_BRIDGE_ROOT_KEY, "Bridge root key mismatch");

        address ethBrigdeAddressFromClient = ethClient.ethBridgeAddress();
        console.log("EthBridge address from client: %s", ethBrigdeAddressFromClient);
        require(ethBrigdeAddressFromClient == ethBridgeAddress, "EthBridge address mismatch");

        BeaconLightClient blcFromClient = ethClient.client();
        console.log("Client address from client: %s", address(blcFromClient));
        require(address(blcFromClient) == address(beaconClient), "Client address mismatch");

        console.log("EthClient.sol proxy address: %s", ethClientProxy);
        address ethClientImpl = Upgrades.getImplementationAddress(ethClientProxy);
        console.log("EthClient.sol implementation address: %s", ethClientImpl);

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

        // check getters
        TaraBridge taraBridge = TaraBridge(taraBrigdeProxy);
        uint256 finalizationIntervalFromBridge = taraBridge.finalizationInterval();
        console.log("Finalization interval from bridge: %s", finalizationIntervalFromBridge);
        require(finalizationIntervalFromBridge == finalizationInterval, "Finalization interval mismatch");

        console.log("TaraBridge.sol proxy address: %s", taraBrigdeProxy);
        address taraBridgeImpl = Upgrades.getImplementationAddress(taraBrigdeProxy);
        console.log("TaraBridge.sol implementation address: %s", taraBridgeImpl);

        address taraConnectorProxy = Upgrades.deployUUPSProxy(
            "NativeConnector.sol", abi.encodeCall(NativeConnector.initialize, (taraBrigdeProxy, taraAddressOnEth)), opts
        );

        // check getters
        NativeConnector taraConnector = NativeConnector(payable(taraConnectorProxy));
        uint256 epoch = taraConnector.epoch();
        console.log("Epoch: %d", epoch);
        require(epoch == 0, "Epoch mismatch");
        address token = taraConnector.token();
        console.log("Token: %s", token);
        require(token == Constants.NATIVE_TOKEN_ADDRESS, "Token address mismatch");

        // Fund TaraConnector with 2 ETH
        (bool success,) = payable(taraConnectorProxy).call{value: 2 ether}("");

        if (!success) {
            revert("Failed to fund the TaraConnector");
        }

        console.log("NativeConnector.sol proxy address: %s", taraConnectorProxy);
        address taraConnectorImpl = Upgrades.getImplementationAddress(taraConnectorProxy);
        console.log("NativeConnector.sol implementation address: %s", taraConnectorImpl);

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

        // check getters
        ERC20MintingConnector ethMintingConnector = ERC20MintingConnector(payable(ethMintingConnectorProxy));
        uint256 epoch2 = ethMintingConnector.epoch();
        console.log("Epoch: %d", epoch);
        require(epoch2 == 0, "Epoch mismatch");
        address token2 = ethMintingConnector.token();
        console.log("Token: %s", token2);
        require(token2 == ethAddressOnTara, "Token address mismatch");

        console.log("ERC20MintingConnector.sol proxy address: %s", ethMintingConnectorProxy);
        address ethMintingConnectorImpl = Upgrades.getImplementationAddress(ethMintingConnectorProxy);
        console.log("ERC20MintingConnector.sol implementation address: %s", ethMintingConnectorImpl);

        // Fund TaraConnector with 2 ETH
        (bool success2,) = payable(ethMintingConnectorProxy).call{value: 2 ether}("");

        if (!success2) {
            revert("Failed to fund the ethMintingConnectorProxy");
        }

        console.log("Deployed ethMintingConnectorProxy proxy to address", ethMintingConnectorProxy);

        // Initialize EthMintingConnectorProxy
        taraBridge.registerContract(IBridgeConnector(ethMintingConnectorProxy));

        address owner = TestERC20(ethAddressOnTara).owner();
        console.log("Owner of TestERC20: %s", owner);
        // give ownership of erc20 to the connector
        TestERC20(ethAddressOnTara).transferOwnership(ethMintingConnectorProxy);

        console.log("TaraBridge initialized");

        vm.stopBroadcast();
    }
}
