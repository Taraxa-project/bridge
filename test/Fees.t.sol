// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import {TaraBridge} from "src/tara/TaraBridge.sol";
import {NativeConnector} from "src/connectors/NativeConnector.sol";
import {EthBridge} from "src/eth/EthBridge.sol";
import {TestERC20} from "src/lib/TestERC20.sol";
import {ERC20LockingConnector} from "src/connectors/ERC20LockingConnector.sol";
import {ERC20MintingConnector} from "src/connectors/ERC20MintingConnector.sol";
import {BridgeLightClientMock} from "./BridgeLightClientMock.sol";
import {Constants} from "src/lib/Constants.sol";
import {SharedStructs} from "src/lib/SharedStructs.sol";
import {SymmetricTestSetup} from "./SymmetricTestSetup.t.sol";
import {IBridgeConnector} from "src/connectors/IBridgeConnector.sol";

contract FeesTest is SymmetricTestSetup {
    function test_finalizeEpoch_toEth_BridgeDoesNotHaveEnoughEth_DoesNotGivePayout_To_Relayer() public {
        vm.roll(FINALIZATION_INTERVAL);
        vm.txGasPrice(1000);
        uint256 value = 1 ether;
        NativeConnector taraBridgeToken =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));

        uint256 balanceOfNativeConnectorBefore = address(taraBridgeToken).balance;
        uint256 settlementFee = taraBridge.settlementFee();
        taraBridgeToken.lock{value: value + settlementFee}(value);

        uint256 balanceOfNativeConnectorAfter = address(taraBridgeToken).balance;

        vm.assertEq(
            balanceOfNativeConnectorAfter,
            balanceOfNativeConnectorBefore + settlementFee + value,
            "Balance of native connector should be increased by settlement fee + value"
        );
        address sampleRelayer = vm.addr(666666);
        vm.deal(sampleRelayer, 0.1 ether);
        uint256 balanceOfRelayerBefore = address(sampleRelayer).balance;
        vm.deal(address(taraBridge), 0 ether);
        vm.txGasPrice(100000000 gwei);
        vm.prank(sampleRelayer);
        taraBridge.finalizeEpoch();
        uint256 balanceOfRelayerAfterEpoch = address(sampleRelayer).balance;
        console.log("Difference: ", balanceOfRelayerAfterEpoch - balanceOfRelayerBefore);
        vm.assertTrue(
            balanceOfRelayerAfterEpoch <= balanceOfRelayerBefore,
            "Relayer should not have received payout"
        );
        uint256 balanceOfNativeConnectorAfterEpoch = address(taraBridgeToken).balance;
        vm.assertEq(
            balanceOfNativeConnectorAfterEpoch,
            balanceOfNativeConnectorBefore + value,
            "Native connector should've forwarded the settlement fee to the bridge"
        );
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        taraLightClient.setBridgeRoot(state);
        ethBridge.applyState(state);

        assertEq(taraTokenOnEth.balanceOf(address(this)), value);
    }
    function test_toEthFees() public {
        vm.roll(FINALIZATION_INTERVAL);
        vm.txGasPrice(1000);
        uint256 value = 1 ether;
        NativeConnector taraBridgeToken =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));

        uint256 balanceOfNativeConnectorBefore = address(taraBridgeToken).balance;
        uint256 settlementFee = taraBridge.settlementFee();
        taraBridgeToken.lock{value: value + settlementFee}(value);

        uint256 balanceOfNativeConnectorAfter = address(taraBridgeToken).balance;

        vm.assertEq(
            balanceOfNativeConnectorAfter,
            balanceOfNativeConnectorBefore + settlementFee + value,
            "Balance of native connector should be increased by settlement fee + value"
        );

        taraBridge.finalizeEpoch();
        uint256 balanceOfNativeConnectorAfterEpoch = address(taraBridgeToken).balance;
        vm.assertEq(
            balanceOfNativeConnectorAfterEpoch,
            balanceOfNativeConnectorBefore + value,
            "Native connector should've forwarded the settlement fee to the bridge"
        );
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        taraLightClient.setBridgeRoot(state);
        ethBridge.applyState(state);

        assertEq(taraTokenOnEth.balanceOf(address(this)), value);
    }

    function test_checkRelayerFees_for_oneTransfer() public {
        address relayer = vm.addr(666);
        vm.deal(relayer, 1 ether);

        vm.roll(FINALIZATION_INTERVAL);
        vm.txGasPrice(1000);
        uint256 value = 1 ether;
        NativeConnector taraBridgeToken =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));

        uint256 settlementFee = taraBridge.settlementFee();
        taraBridgeToken.lock{value: value + settlementFee}(value);

        uint256 relayerBalanceBefore = address(relayer).balance;
        vm.txGasPrice(20 gwei);
        vm.prank(relayer);
        taraBridge.finalizeEpoch();
        uint256 relayerBalanceAfterEpoch = address(relayer).balance;
        console.log("Relayer balance before: ", relayerBalanceBefore);
        console.log("Relayer balance after epoch: ", relayerBalanceAfterEpoch);
        assertTrue(
            relayerBalanceAfterEpoch > relayerBalanceBefore, "Relayer balance after epoch should be greater than before"
        );
        assertTrue(relayerBalanceAfterEpoch - relayerBalanceBefore < settlementFee, "Relayer paid too much after epoch");
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        taraLightClient.setBridgeRoot(state);

        vm.txGasPrice(20 gwei);
        vm.prank(relayer);
        ethBridge.applyState(state);
        uint256 relayerBalanceAfterApplyState = address(relayer).balance;
        console.log("Relayer balance after apply state: ", relayerBalanceAfterApplyState);
        assertTrue(
            relayerBalanceAfterApplyState > relayerBalanceAfterEpoch,
            "Relayer balance after apply state should be greater than after epoch"
        );
        assertTrue(
            relayerBalanceAfterEpoch - relayerBalanceBefore < settlementFee, "Relayer paid too much after applyng state"
        );
        assertEq(taraTokenOnEth.balanceOf(address(this)), value);
    }

    function test_checkRelayerFees_for_hundredTransfers() public {
        address relayer = vm.addr(666);
        vm.deal(relayer, 1 ether);

        vm.roll(FINALIZATION_INTERVAL);
        vm.txGasPrice(1000);
        uint256 value = 1 ether;
        NativeConnector taraBridgeToken =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));
        uint256 settlementFee = taraBridge.settlementFee();
        taraBridgeToken.lock{value: value + settlementFee}(value);
        for (uint256 i = 1; i <= 100; i++) {
            address locker = vm.addr(i);
            vm.deal(locker, value + settlementFee);
            vm.prank(locker);
            taraBridgeToken.lock{value: value + settlementFee}(value);
        }

        uint256 relayerBalanceBefore = address(relayer).balance;
        vm.txGasPrice(500 gwei);
        vm.prank(relayer);
        taraBridge.finalizeEpoch();
        uint256 relayerBalanceAfterEpoch = address(relayer).balance;
        console.log("Relayer balance before: ", relayerBalanceBefore);
        console.log("Relayer balance after epoch: ", relayerBalanceAfterEpoch);
        assertTrue(
            relayerBalanceAfterEpoch > relayerBalanceBefore, "Relayer balance after epoch should be greater than before"
        );
        assertTrue(relayerBalanceAfterEpoch - relayerBalanceBefore < settlementFee, "Relayer paid too much after epoch");
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        taraLightClient.setBridgeRoot(state);
        vm.txGasPrice(500 gwei);
        vm.prank(relayer);
        ethBridge.applyState(state);
        uint256 relayerBalanceAfterApplyState = address(relayer).balance;
        console.log("Relayer balance after apply state: ", relayerBalanceAfterApplyState);
        assertTrue(
            relayerBalanceAfterApplyState > relayerBalanceAfterEpoch,
            "Relayer balance after apply state should be greater than after epoch"
        );
        assertTrue(
            relayerBalanceAfterEpoch - relayerBalanceBefore < settlementFee, "Relayer paid too much after applyng state"
        );
        assertEq(taraTokenOnEth.balanceOf(address(this)), value);
    }

    function test_Revert_delist_Relayer_on_insufficient_settlement_fees() public {
        address relayer = vm.addr(666);
        vm.deal(relayer, 1 ether);

        vm.roll(FINALIZATION_INTERVAL);
        vm.txGasPrice(1000);
        uint256 value = 1 ether;
        NativeConnector taraBridgeToken =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));

        uint256 settlementFee = taraBridge.settlementFee();
        vm.deal(address(this), value + settlementFee);
        taraBridgeToken.lock{value: value + settlementFee}(value);

        // We're consciously setting the balance of the taraBridgeToken to 0 to simulate a malicious actor
        vm.deal(address(taraBridgeToken), 0 ether);

        IBridgeConnector br = taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS);
        vm.assertNotEq(address(br), address(0), "Bridge connector should not be 0");

        vm.txGasPrice(20 gwei);
        vm.prank(relayer);
        taraBridge.finalizeEpoch();

        IBridgeConnector br2 = taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS);
        vm.assertEq(address(br2), address(0), "Bridge connector should be 0");
    }
}
