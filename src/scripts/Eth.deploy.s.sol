// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {EthBridge} from "../eth/EthBridge.sol";
import {TaraClient, PillarBlock} from "../eth/TaraClient.sol";
import {TestERC20} from "../lib/TestERC20.sol";
import {IBridgeLightClient} from "../lib/ILightClient.sol";
import {ERC20MintingConnector} from "../connectors/ERC20MintingConnector.sol";
import {IBridgeConnector} from "../connectors/IBridgeConnector.sol";

contract EthDeployer is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.envAddress("DEPLOYMENT_ADDRESS");
        console.log("Deployer address: %s", deployerAddress);
        vm.startBroadcast(deployerPrivateKey);

        address taraAddress = vm.envAddress("ETH_TARA_ADDRESS");
        console.log("ETH TARA address: %s", taraAddress);

        PillarBlock.VoteCountChange[] memory changes = new PillarBlock.VoteCountChange[](3);
        changes[0] = PillarBlock.VoteCountChange({validator: 0xFe3d5E3B9c2080bF338638Fd831a35A4B4344a2C, change: 100});
        changes[1] = PillarBlock.VoteCountChange({validator: 0x515C990Ef87668E57A290F650b4C39c343d73d9a, change: 100});
        changes[2] = PillarBlock.VoteCountChange({validator: 0x3E62C62Ac89c71412CA68688530D112433FEC78C, change: 100});

        PillarBlock.WithChanges memory genesis = PillarBlock.WithChanges({
            block: PillarBlock.FinalizationData({
                period: 100,
                stateRoot: 0x575d2ca3bbbcddf93eee5e4b1deff3191ea780b12778b2cbe4660c3a4cccbcd0,
                bridgeRoot: 0x0,
                prevHash: 0x0
            }),
            validatorChanges: changes
        });
        uint256 finalizationInterval = 100;

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

        address taraClientProxy = Upgrades.deployUUPSProxy(
            "TaraClient.sol", abi.encodeCall(TaraClient.initialize, (genesis, 3, finalizationInterval)), opts
        );

        console.log("Deployed TaraClient proxy to address", taraClientProxy);

        address ethBridgeProxy = Upgrades.deployUUPSProxy(
            "EthBridge.sol",
            abi.encodeCall(
                EthBridge.initialize,
                (TestERC20(taraAddress), IBridgeLightClient(taraClientProxy), finalizationInterval)
            ),
            opts
        );

        console.log("Deployed EthBridge proxy to address", ethBridgeProxy);

        address mintingConnectorProxy = Upgrades.deployUUPSProxy(
            "ERC20MintingConnector.sol",
            abi.encodeCall(
                ERC20MintingConnector.initialize, (address(ethBridgeProxy), TestERC20(taraAddress), taraAddress)
            ),
            opts
        );

        console.log("Deployed ERC20MintingConnector proxy to address", mintingConnectorProxy);

        // Fund the MintingConnector with 2 ETH
        (bool success,) = payable(mintingConnectorProxy).call{value: 2 ether}("");
        if (!success) {
            revert("Failed to fund the MintingConnector");
        }

        // Add the connector to the bridge
        EthBridge bridge = EthBridge(ethBridgeProxy);
        bridge.registerContract(IBridgeConnector(mintingConnectorProxy));

        vm.stopBroadcast();
    }
}
