// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {NativeConnector} from "src/connectors/NativeConnector.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {SymmetricTestSetup} from "./SymmetricTestSetup.t.sol";

contract ConnectorRegistrationTest is SymmetricTestSetup {
    function test_revertOnDuplicateConnectorRegistration() public {
        vm.startPrank(caller);
        address ethConnectorProxy = Upgrades.deployUUPSProxy(
            "NativeConnector.sol", abi.encodeCall(NativeConnector.initialize, (ethBridge, address(ethTokenOnTara)))
        );
        NativeConnector ethConnector2 = NativeConnector(payable(ethConnectorProxy));
        vm.deal(caller, REGISTRATION_FEE_ETH);
        vm.expectRevert();
        ethBridge.registerContract{value: REGISTRATION_FEE_ETH}(ethConnector2);
        vm.stopPrank();
    }
}
