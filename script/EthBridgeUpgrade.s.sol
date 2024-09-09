// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {EthBridge} from "../src/eth/EthBridge.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract EthBridgeUpgrade is Script {
    function run() public {
        address EthBridgeProxy = vm.envAddress("ETH_BRIDGE_ADDRESS");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        if (vm.envUint("PRIVATE_KEY") == 0) {
            revert("Skipping deployment because PRIVATE_KEY is not set");
        }
        vm.startBroadcast(deployerPrivateKey);

        address implAddressV1 = Upgrades.getImplementationAddress(
            address(EthBridgeProxy)
        );

        require(implAddressV1 != address(0), "implAddressV1 is not set");

        Options memory opts;
        opts.unsafeSkipAllChecks = true;
        Upgrades.upgradeProxy(EthBridgeProxy, "EthBridge.sol", "", opts);

        address implAddressV2 = Upgrades.getImplementationAddress(
            address(EthBridgeProxy)
        );

        console.log("implAddressV1", implAddressV1);
        console.log("implAddressV2", implAddressV2);

        require(implAddressV2 != address(0), "implAddressV2 is not set");
        require(
            implAddressV2 != implAddressV1,
            "implAddressV2 is the same as implAddressV1"
        );

        vm.stopBroadcast();
    }
}
