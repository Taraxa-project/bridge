// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {TaraBridgeSettable} from "../src/tara/TaraBridgeSettable.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {IBridgeLightClient} from "../src/lib/IBridgeLightClient.sol";

contract TaraBridgeUpgrade is Script {
    function run() public {
        address TaraBridgeProxy = 0xcAF2b453FE8382a4B8110356DF0508f6d71F22BF;
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        if (vm.envUint("PRIVATE_KEY") == 0) {
            revert("Skipping deployment because PRIVATE_KEY is not set");
        }
        vm.startBroadcast(deployerPrivateKey);

        address implAddressV1 = Upgrades.getImplementationAddress(address(TaraBridgeProxy));

        require(implAddressV1 != address(0), "implAddressV1 is not set");
        
        Upgrades.upgradeProxy(TaraBridgeProxy, "TaraBridgeSettable.sol",(abi.encodeCall(TaraBridgeSettable.setLightClient, IBridgeLightClient(address(1)))));

        address implAddressV2 = Upgrades.getImplementationAddress(address(TaraBridgeProxy));

        console.log("implAddressV1", implAddressV1);
        console.log("implAddressV2", implAddressV2);

        require(implAddressV2 != address(0), "implAddressV2 is not set");
        require(implAddressV2 != implAddressV1, "implAddressV2 is the same as implAddressV1");

        vm.stopBroadcast();
    }
}

