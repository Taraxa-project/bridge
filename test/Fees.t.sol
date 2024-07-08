// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {NativeConnector} from "src/connectors/NativeConnector.sol";
import {TestERC20} from "src/lib/TestERC20.sol";
import {ERC20LockingConnector} from "src/connectors/ERC20LockingConnector.sol";
import {Constants} from "src/lib/Constants.sol";
import {SharedStructs} from "src/lib/SharedStructs.sol";
import {SymmetricTestSetup} from "./SymmetricTestSetup.t.sol";
import {IBridgeConnector} from "src/connectors/IBridgeConnector.sol";
import {console} from "forge-std/console.sol";

contract FeesTest is SymmetricTestSetup {
    function test_finalizeEpoch_toEth_BridgeDoesNotHaveEnoughEth_DoesNotGivePayout_To_Relayer() public {
        vm.roll(FINALIZATION_INTERVAL);
        vm.txGasPrice(1000);
        uint256 value = 1 ether;
        NativeConnector taraBridgeToken =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));

        uint256 balanceOfNativeConnectorBefore = address(taraBridgeToken).balance;
        uint256 settlementFee = taraBridge.settlementFee();
        taraBridgeToken.lock{value: value + settlementFee}();

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
        vm.assertTrue(balanceOfRelayerAfterEpoch <= balanceOfRelayerBefore, "Relayer should not have received payout");
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

    function test_toEthFees_SameAddress_DoubleLocksInSameEpoch_Should_Settle_OnlyOnce() public {
        vm.roll(FINALIZATION_INTERVAL);
        uint256 value = 1 ether;
        NativeConnector nativeConnector =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));

        uint256 balanceOfNativeConnectorBefore = address(nativeConnector).balance;
        uint256 bridgeSettlementFee = taraBridge.settlementFee();
        uint256 settlementFee = nativeConnector.estimateSettlementFee(address(this));
        vm.assertEq(settlementFee, bridgeSettlementFee, "Settlement fee should be the same as the bridge's");
        nativeConnector.lock{value: value + settlementFee}();
        uint256 newSettlementFee = nativeConnector.estimateSettlementFee(address(this));
        vm.assertEq(newSettlementFee, 0, "Settlement fee should be 0");
        nativeConnector.lock{value: value + newSettlementFee}();

        uint256 balanceOfNativeConnectorAfter = address(nativeConnector).balance;

        vm.assertEq(
            balanceOfNativeConnectorAfter,
            balanceOfNativeConnectorBefore + settlementFee + 2 * value,
            "Balance of native connector should be increased by 2*(settlement fee + value)"
        );
        uint256 balanceOfBridgeBefore = address(taraBridge).balance;
        taraBridge.finalizeEpoch();
        uint256 balanceOfBridgeAfterEpoch = address(taraBridge).balance;
        vm.assertEq(
            balanceOfBridgeAfterEpoch,
            balanceOfBridgeBefore + settlementFee,
            "Bridge should've received the settlement fee"
        );
        uint256 balanceOfNativeConnectorAfterEpoch = address(nativeConnector).balance;
        vm.assertEq(
            balanceOfNativeConnectorAfterEpoch,
            2 * value,
            "Native connector should've forwarded the settlement fee to the bridge"
        );
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        taraLightClient.setBridgeRoot(state);
        ethBridge.applyState(state);

        assertEq(taraTokenOnEth.balanceOf(address(this)), 2 * value);
    }

    function test_toEthFees_DiffAddresses_DoubleLocksInSameEpoch_Should_Settle_Twice() public {
        vm.roll(FINALIZATION_INTERVAL);
        uint256 value = 1 ether;
        NativeConnector nativeConnector =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));

        uint256 balanceOfNativeConnectorBefore = address(nativeConnector).balance;
        uint256 settlementFee = taraBridge.settlementFee();
        nativeConnector.lock{value: value + settlementFee}();
        vm.deal(address(caller), value + settlementFee);
        vm.prank(address(caller));
        nativeConnector.lock{value: value + settlementFee}();

        uint256 balanceOfNativeConnectorAfter = address(nativeConnector).balance;

        vm.assertEq(
            balanceOfNativeConnectorAfter,
            balanceOfNativeConnectorBefore + 2 * (settlementFee + value),
            "Balance of native connector should be increased by 2*(settlement fee + value)"
        );

        vm.deal(address(taraBridge), 1 ether);
        uint256 balanceOfBridgeBefore = address(taraBridge).balance;
        taraBridge.finalizeEpoch();
        uint256 balanceOfBridgeAfterEpoch = address(taraBridge).balance;
        vm.assertGt(balanceOfBridgeAfterEpoch, 2 * settlementFee, "Bridge should've received the settlement fee");
        uint256 balanceOfNativeConnectorAfterEpoch = address(nativeConnector).balance;
        vm.assertEq(
            balanceOfNativeConnectorAfterEpoch,
            2 * value,
            "Native connector should've forwarded the settlement fee to the bridge"
        );
        uint256 balanceOfBridge = address(taraBridge).balance;
        vm.assertEq(
            balanceOfBridge, balanceOfBridgeBefore + 2 * settlementFee, "Bridge should've received the settlement fee"
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
        taraBridgeToken.lock{value: value + settlementFee}();

        uint256 relayerBalanceBefore = address(relayer).balance;
        vm.txGasPrice(20 gwei);
        vm.prank(relayer);
        taraBridge.finalizeEpoch();
        uint256 relayerBalanceAfterEpoch = address(relayer).balance;
        console.log("Relayer balance before: ", relayerBalanceBefore);
        console.log("Relayer balance after epoch: ", relayerBalanceAfterEpoch);
        assertTrue(
            relayerBalanceAfterEpoch >= relayerBalanceBefore,
            "Relayer balance after epoch should be greater than before"
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
            relayerBalanceAfterApplyState >= relayerBalanceAfterEpoch,
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
        taraBridgeToken.lock{value: value + settlementFee}();
        for (uint256 i = 1; i <= 100; i++) {
            address locker = vm.addr(i);
            vm.deal(locker, value + settlementFee);
            vm.prank(locker);
            taraBridgeToken.lock{value: value + settlementFee}();
        }

        uint256 relayerBalanceBefore = address(relayer).balance;
        vm.txGasPrice(500 gwei);
        vm.prank(relayer);
        taraBridge.finalizeEpoch();
        uint256 relayerBalanceAfterEpoch = address(relayer).balance;
        console.log("Relayer balance before: ", relayerBalanceBefore);
        console.log("Relayer balance after epoch: ", relayerBalanceAfterEpoch);
        assertTrue(
            relayerBalanceAfterEpoch >= relayerBalanceBefore,
            "Relayer balance after epoch should be greater than before"
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
            relayerBalanceAfterApplyState >= relayerBalanceAfterEpoch,
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

        (TestERC20 erc20onTara2,) = registerCustomTokenPair();

        vm.roll(FINALIZATION_INTERVAL);
        vm.txGasPrice(1000);
        uint256 value = 1 ether;
        NativeConnector taraBridgeToken =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));

        uint256 settlementFee = taraBridge.settlementFee();
        vm.deal(address(this), 2 * value + settlementFee);
        taraBridgeToken.lock{value: value + settlementFee}();

        ERC20LockingConnector erc20onTara2Connector =
            ERC20LockingConnector(payable(address(taraBridge.connectors(address(erc20onTara2)))));
        vm.deal(caller, 2 * value + settlementFee);
        uint256 balance = erc20onTara2.balanceOf(caller);
        vm.assertTrue(balance >= value, "Balance should be greater than value");
        vm.prank(caller);
        erc20onTara2Connector.lock{value: settlementFee}(value);

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
