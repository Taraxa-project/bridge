// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {NativeConnector} from "../src/connectors/NativeConnector.sol";
import {TestERC20} from "../src/lib/TestERC20.sol";
import {EthBridgeV2} from "./utils/EthBridgeV2.sol";
import {TaraBridgeV2} from "./utils/TaraBridgeV2.sol";
import {SymmetricTestSetup} from "./SymmetricTestSetup.t.sol";
import {IBridgeConnector} from "../src/connectors/IBridgeConnector.sol";

contract UpgradeabilityTest is SymmetricTestSetup {
    function test_upgrade_ethBridge() public {
        vm.startPrank(caller);
        Options memory opts;
        opts.referenceContract = "EthBridge.sol";

        uint256 newFinalizationInterval = 6666;

        address implAddressV1 = Upgrades.getImplementationAddress(address(ethBridge));

        Upgrades.upgradeProxy(
            address(ethBridge), "EthBridgeV2.sol", (abi.encodeCall(EthBridgeV2.reinitialize, newFinalizationInterval))
        );
        address implAddressV2 = Upgrades.getImplementationAddress(address(ethBridge));
        assertNotEq(implAddressV1, implAddressV2, "Implementation address should change after upgrade");
        EthBridgeV2 upgradedBridge = EthBridgeV2(payable(address(ethBridge)));
        assertEq(upgradedBridge.getNewStorageValue(), newFinalizationInterval);
        vm.stopPrank();
    }

    function test_Revert_ConnectorRegistration_Not_By_Owner() public {
        vm.startPrank(caller);
        Upgrades.upgradeProxy(address(ethBridge), "EthBridgeV2.sol", (abi.encodeCall(EthBridgeV2.reinitialize, 6666)));
        EthBridgeV2 upgradedBridge = EthBridgeV2(payable(address(ethBridge)));
        vm.stopPrank();
        address newNativeConnectorProxy = Upgrades.deployUUPSProxy(
            "NativeConnector.sol", abi.encodeCall(NativeConnector.initialize, (taraBridge, address(taraTokenOnEth)))
        );
        address ownerOfUpgradedBridge = upgradedBridge.owner();
        console.log("Owner of upgraded bridge: ", ownerOfUpgradedBridge);
        address caller3 = vm.addr(666669);
        console.log("Caller: ", caller3);
        vm.startPrank(caller3);
        vm.expectRevert();
        upgradedBridge.registerConnectorOwner(IBridgeConnector(newNativeConnectorProxy));
        vm.stopPrank();
    }

    function test_upgrade_taraBridge() public {
        vm.startPrank(caller);
        Options memory opts;
        opts.referenceContract = "TaraBridge.sol";

        uint256 newFinalizationInterval = 6666;
        address implAddressV1 = Upgrades.getImplementationAddress(address(taraBridge));
        Upgrades.upgradeProxy(
            address(taraBridge),
            "TaraBridgeV2.sol",
            (abi.encodeCall(TaraBridgeV2.reinitialize, newFinalizationInterval))
        );
        address implAddressV2 = Upgrades.getImplementationAddress(address(taraBridge));
        assertNotEq(implAddressV1, implAddressV2, "Implementation address should not change after upgrade");
        TaraBridgeV2 upgradedBridge = TaraBridgeV2(payable(address(taraBridge)));
        assertEq(upgradedBridge.getNewStorageValue(), newFinalizationInterval);
        vm.stopPrank();
    }
}
