// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {EthBridge} from "../src/eth/EthBridge.sol";
import {TaraClient, PillarBlock} from "../src/eth/TaraClient.sol";
import {TestERC20} from "../src/lib/TestERC20.sol";
import {IBridgeLightClient} from "../src/lib/ILightClient.sol";

contract EthDeployer is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.envAddress("DEPLOYMENT_ADDRESS");
        console.log("Deployer address: %s", deployerAddress);
        vm.startBroadcast(deployerPrivateKey);

        address taraAddress = vm.envAddress("TARA_ETH_ADDRESS");
        console.log("TARA address: %s", taraAddress);

        PillarBlock.WeightChange[]
            memory changes = new PillarBlock.WeightChange[](3);
        changes[0] = PillarBlock.WeightChange({
            validator: 0xFe3d5E3B9c2080bF338638Fd831a35A4B4344a2C,
            change: 0x84595161401484a000000
        });
        changes[1] = PillarBlock.WeightChange({
            validator: 0x515C990Ef87668E57A290F650b4C39c343d73d9a,
            change: 0x84595161401484a000000
        });
        changes[2] = PillarBlock.WeightChange({
            validator: 0x3E62C62Ac89c71412CA68688530D112433FEC78C,
            change: 0x84595161401484a000000
        });

        TaraClient client = new TaraClient(changes, 3, 100);

        EthBridge bridge = new EthBridge{value: 2 ether}(
            TestERC20(0xe01095F5f61211b2daF395E947C3dA78D7a431Ab),
            IBridgeLightClient(client)
        );

        console.log("Bridge address: %s", address(bridge));

        vm.stopBroadcast();
    }
}
