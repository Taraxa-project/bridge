// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "forge-std/Test.sol";

import "../src/tara/TaraBridge.sol";
import {NativeConnector} from "../src/connectors/NativeConnector.sol";
import "../src/eth/EthBridge.sol";
import "../src/lib/TestERC20.sol";
import {
    StateNotMatchingBridgeRoot, NotSuccessiveEpochs, NotEnoughBlocksPassed
} from "../src/errors/BridgeBaseErrors.sol";
import "../src/connectors/ERC20LockingConnector.sol";
import "../src/connectors/ERC20MintingConnector.sol";
import "./BridgeLightClientMock.sol";
import "../src/lib/Constants.sol";
import "./upgradeableMocks/EthBridgeV2.sol";
import "./upgradeableMocks/TaraBridgeV2.sol";
import "./SymmetricTestSetup.t.sol";

contract UpgradeabilityTest is SymmetricTestSetup {
    function test_upgrade_ethBridge() public {
        Options memory opts;
        opts.referenceContract = "EthBridge.sol";

        uint256 newFinalizationInterval = 6666;

        address implAddressV1 = Upgrades.getImplementationAddress(address(ethBridge));
        vm.prank(caller);
        Upgrades.upgradeProxy(
            address(ethBridge), "EthBridgeV2.sol", (abi.encodeCall(EthBridgeV2.reinitialize, newFinalizationInterval))
        );
        address implAddressV2 = Upgrades.getImplementationAddress(address(ethBridge));
        assertNotEq(implAddressV1, implAddressV2, "Implementation address should not change after upgrade");
        EthBridgeV2 upgradedBridge = EthBridgeV2(address(ethBridge));
        assertEq(upgradedBridge.getNewStorageValue(), newFinalizationInterval);
    }

    function test_Revert_ConnectorRegistration_By_Not_Owner() public {
        EthBridgeV2 upgradedBridge = EthBridgeV2(address(ethBridge));

        address newNativeConnectorProxy = Upgrades.deployUUPSProxy(
            "NativeConnector.sol", abi.encodeCall(NativeConnector.initialize, (taraBridge, address(taraTokenOnEth)))
        );
        // vm.prank(caller);
        vm.expectRevert();
        upgradedBridge.registerContractOwner(IBridgeConnector(newNativeConnectorProxy));
    }

    function test_upgrade_taraBridge() public {
        Options memory opts;
        opts.referenceContract = "TaraBridge.sol";

        uint256 newFinalizationInterval = 6666;
        address implAddressV1 = Upgrades.getImplementationAddress(address(taraBridge));
        vm.prank(caller);
        Upgrades.upgradeProxy(
            address(taraBridge),
            "TaraBridgeV2.sol",
            (abi.encodeCall(TaraBridgeV2.reinitialize, newFinalizationInterval))
        );
        address implAddressV2 = Upgrades.getImplementationAddress(address(taraBridge));
        assertNotEq(implAddressV1, implAddressV2, "Implementation address should not change after upgrade");
        TaraBridgeV2 upgradedBridge = TaraBridgeV2(address(taraBridge));
        assertEq(upgradedBridge.getNewStorageValue(), newFinalizationInterval);
    }
}
