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
import {BridgeLightClientMock} from "./utils/LightClientMocks.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {SharedStructs} from "src/lib/SharedStructs.sol";
import {SymmetricTestSetup} from "./SymmetricTestSetup.t.sol";

contract GasBenchmarksTest is SymmetricTestSetup {
    function test_revertOnDuplicateConnectorRegistration() public {
        vm.startPrank(caller);
        address ethConnectorProxy = Upgrades.deployUUPSProxy(
            "NativeConnector.sol",
            abi.encodeCall(NativeConnector.initialize, (address(ethBridge), address(ethTokenOnTara)))
        );
        NativeConnector ethConnector2 = NativeConnector(payable(ethConnectorProxy));

        (bool success3,) = payable(ethConnector2).call{value: Constants.MINIMUM_CONNECTOR_DEPOSIT}("");
        if (!success3) {
            revert("Failed to initialize eth connector");
        }

        vm.expectRevert();
        ethBridge.registerContract(ethConnector2);
        vm.stopPrank();
    }

    function test_plain_toEthTransfer() public {
        vm.startPrank(caller);
        ethTokenOnTara.approve(address(ethOnTaraMintingConnector), 1 ether);
        ethOnTaraMintingConnector.burn(1 ether);
        vm.roll(FINALIZATION_INTERVAL);
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        assertEq(state.state.epoch, 1, "epoch");
        taraLightClient.setBridgeRoot(state);
        assertEq(ethTokenOnTara.balanceOf(address(caller)), 0, "token balance before");

        ethBridge.applyState(state);

        vm.deal(address(caller), 1 ether);
        vm.deal(address(ethConnector), 1 ether);
        uint256 balanceBefore = address(caller).balance;
        ethTokenOnTara.approve(address(ethConnector), 1 ether);
        ethConnector.claim{value: ethConnector.feeToClaim(address(caller))}();

        assertEq(address(caller).balance, balanceBefore + 1 ether, "token balance after");
        vm.stopPrank();
    }

    function test_plain_multipleTxes_ForSameToken_toEthTransfer() public {
        for (uint16 i = 1; i < transfers; i++) {
            address target = vm.addr(i);
            vm.startPrank(target);
            ethTokenOnTara.approve(address(ethOnTaraMintingConnector), 1 ether);
            ethOnTaraMintingConnector.burn(1 ether);
            vm.stopPrank();
        }

        vm.roll(FINALIZATION_INTERVAL);
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        assertEq(state.state.epoch, 1, "epoch");
        taraLightClient.setBridgeRoot(state);

        ethBridge.applyState(state);

        for (uint16 i = 1; i < transfers; i++) {
            address target = vm.addr(i);
            vm.startPrank(target);
            vm.deal(address(target), 1 ether);
            vm.deal(address(ethConnector), 1 ether);
            uint256 balanceBefore = address(target).balance;
            ethTokenOnTara.approve(address(ethConnector), 1 ether);
            ethConnector.claim{value: ethConnector.feeToClaim(address(target))}();

            assertEq(address(target).balance, balanceBefore + 1 ether, "token balance after");
            vm.stopPrank();
        }
    }
}
