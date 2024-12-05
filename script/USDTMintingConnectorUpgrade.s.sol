// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {USDTMintingConnector} from "../src/connectors/USDTMintingConnector.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract USDTMintingConnectorUpgrade is Script {
    function run() public {
        address USDTMintingConnectorProxy = 0x386331BEF4551b476B2c803B13373193B004289E;
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        if (vm.envUint("PRIVATE_KEY") == 0) {
            revert("Skipping deployment because PRIVATE_KEY is not set");
        }
        vm.startBroadcast(deployerPrivateKey);

        address implAddressV1 = Upgrades.getImplementationAddress(
            address(USDTMintingConnectorProxy)
        );

        require(implAddressV1 != address(0), "implAddressV1 is not set");

        Upgrades.upgradeProxy(USDTMintingConnectorProxy, "USDTMintingConnector.sol", "");

        address implAddressV2 = Upgrades.getImplementationAddress(
            address(USDTMintingConnectorProxy)
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
