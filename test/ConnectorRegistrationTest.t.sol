// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import {TaraBridge} from "src/tara/TaraBridge.sol";
import {NativeConnector} from "src/connectors/NativeConnector.sol";
import {EthBridge} from "src/eth/EthBridge.sol";
import {TestERC20} from "src/lib/TestERC20.sol";
import {ERC20LockingConnector} from "src/connectors/ERC20LockingConnector.sol";
import {ERC20MintingConnector} from "src/connectors/ERC20MintingConnector.sol";
import {Constants} from "src/lib/Constants.sol";
import {BridgeLightClientMock} from "./BridgeLightClientMock.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {SharedStructs} from "src/lib/SharedStructs.sol";
import {SymmetricTestSetup} from "./SymmetricTestSetup.t.sol";

contract ConnectorRegistrationTest is SymmetricTestSetup {
    function test_revertOnDuplicateConnectorRegistration() public {
        vm.startPrank(caller);
        address ethConnectorProxy = Upgrades.deployUUPSProxy(
            "NativeConnector.sol",
            abi.encodeCall(NativeConnector.initialize, (ethBridge, address(ethTokenOnTara)))
        );
        NativeConnector ethConnector2 = NativeConnector(payable(ethConnectorProxy));
        vm.deal(caller, REGISTRATION_FEE_ETH);
        vm.expectRevert();
        ethBridge.registerContract{value: REGISTRATION_FEE_ETH}(ethConnector2);
        vm.stopPrank();
    }
}
