// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {EthBridge} from "../src/eth/EthBridge.sol";
import {EthBridgeGasLimit} from "../src/eth/EthBridgeGasLimit.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {IBridgeLightClient} from "../src/lib/IBridgeLightClient.sol";

contract EthBridgeUpgrade is Script {
    function run() public {
        address EthBridgeProxy = 0x359CF536b1fd6248ebAd1449E1B3727caB33A01d;
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        if (vm.envUint("PRIVATE_KEY") == 0) {
            revert("Skipping deployment because PRIVATE_KEY is not set");
        }
        vm.startBroadcast(deployerPrivateKey);

        address implAddressV1 = Upgrades.getImplementationAddress(address(EthBridgeProxy));

        require(implAddressV1 != address(0), "implAddressV1 is not set");

        Options memory opts;
        opts.referenceContract = "EthBridge.sol";

        EthBridge bridge = EthBridge(payable(EthBridgeProxy));

        IBridgeLightClient client = bridge.lightClient();
        uint256 finalizationInterval = bridge.finalizationInterval();
        uint256 feeMultiplierFinalize = bridge.feeMultiplierFinalize();
        uint256 feeMultiplierApply = bridge.feeMultiplierApply();
        uint256 registrationFee = bridge.registrationFee();
        uint256 settlementFee = bridge.settlementFee();
        uint256 gasPriceLimit = 2 gwei;

        Upgrades.upgradeProxy(
            EthBridgeProxy,
            "EthBridgeGasLimit.sol",
            (
                abi.encodeCall(
                    EthBridgeGasLimit.initialize,
                    (
                        client,
                        finalizationInterval,
                        feeMultiplierFinalize,
                        feeMultiplierApply,
                        registrationFee,
                        settlementFee,
                        gasPriceLimit
                    )
                )
            )
        );

        address implAddressV2 = Upgrades.getImplementationAddress(address(EthBridgeProxy));

        console.log("implAddressV1", implAddressV1);
        console.log("implAddressV2", implAddressV2);

        require(implAddressV2 != address(0), "implAddressV2 is not set");
        require(implAddressV2 != implAddressV1, "implAddressV2 is the same as implAddressV1");

        vm.stopBroadcast();
    }
}
