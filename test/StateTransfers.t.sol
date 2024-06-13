// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../src/tara/TaraBridge.sol";
import "../src/eth/EthBridge.sol";
import "../src/lib/TestERC20.sol";
import {
    StateNotMatchingBridgeRoot, NotSuccessiveEpochs, NotEnoughBlocksPassed
} from "../src/errors/BridgeBaseErrors.sol";
import {NativeConnector} from "../src/connectors/NativeConnector.sol";
import {ERC20LockingConnector} from "../src/connectors/ERC20LockingConnector.sol";
import {ERC20MintingConnector} from "../src/connectors/ERC20MintingConnector.sol";
import {BridgeLightClientMock} from "./BridgeLightClientMock.sol";
import {Constants} from "../src/lib/Constants.sol";
import {SymmetricTestSetup} from "./SymmetricTestSetup.t.sol";
import "forge-std/console.sol";

contract StateTransfersTest is SymmetricTestSetup {
    function test_Revert_toEth_on_not_enough_blocks_passed() public {
        uint256 settlementFee = taraBridge.settlementFee();

        uint256 value = 1 ether;
        NativeConnector taraBridgeToken =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));
        taraBridgeToken.lock{value: value + settlementFee}(value);

        // vm.roll(FINALIZATION_INTERVAL);

        vm.expectRevert(
            abi.encodeWithSelector(
                NotEnoughBlocksPassed.selector,
                taraBridge.lastFinalizedBlock(),
                block.number - taraBridge.lastFinalizedBlock(),
                FINALIZATION_INTERVAL
            )
        );
        taraBridge.finalizeEpoch();
    }

    function test_Revert_toEth_without_settlement_fee() public {
        uint256 settlementFee = taraBridge.settlementFee();

        NativeConnector taraBridgeToken =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));
        uint256 value = 1 ether;
        vm.expectRevert(abi.encodeWithSelector(InsufficientFunds.selector, value + settlementFee, value));
        taraBridgeToken.lock{value: value}(value);

        vm.roll(FINALIZATION_INTERVAL);

        bytes32 bridgeRootBefore = taraBridge.getBridgeRoot();
        taraBridge.finalizeEpoch();
        bytes32 bridgeRootAfter = taraBridge.getBridgeRoot();
        assertEq(bridgeRootBefore, bridgeRootAfter, "Bridge root should not change");
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        taraLightClient.setBridgeRoot(state);
        vm.expectRevert();
        ethBridge.applyState(state);
    }

    function test_Revert_toEth_on_zero_value() public {
        uint256 settlementFee = taraBridge.settlementFee();

        NativeConnector taraBridgeToken =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));
        vm.expectRevert();
        taraBridgeToken.lock{value: settlementFee}(0);

        vm.roll(FINALIZATION_INTERVAL);

        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        taraLightClient.setBridgeRoot(state);
        vm.expectRevert();
        ethBridge.applyState(state);
    }

    function test_toEth() public {
        uint256 settlementFee = taraBridge.settlementFee();

        uint256 value = 1 ether;
        NativeConnector taraBridgeToken =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));
        taraBridgeToken.lock{value: value + settlementFee}(value);

        vm.roll(FINALIZATION_INTERVAL);

        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        taraLightClient.setBridgeRoot(state);
        ethBridge.applyState(state);

        assertEq(taraTokenOnEth.balanceOf(address(this)), value);
    }

    function test_toTara() public {
        test_toEth();
        uint256 settlementFee = taraBridge.settlementFee();

        uint256 value = 1 ether;
        ERC20MintingConnector nativeMintingConnector =
            ERC20MintingConnector(payable(address(ethBridge.connectors(address(taraTokenOnEth)))));
        taraTokenOnEth.approve(address(nativeMintingConnector), value);
        nativeMintingConnector.burn{value: settlementFee}(value);

        vm.roll(FINALIZATION_INTERVAL);

        ethBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = ethBridge.getStateWithProof();
        ethLightClient.setBridgeRoot(state);
        uint256 balance_before = address(this).balance;

        vm.prank(caller);
        taraBridge.applyState(state);
        assertEq(address(this).balance, balance_before + 1 ether);
    }

    function test_Revert_OnChangedState() public {
        uint256 settlementFee = taraBridge.settlementFee();
        uint256 value = 1 ether;
        taraConnector.lock{value: value + settlementFee}(value);

        vm.roll(FINALIZATION_INTERVAL);
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        state.state.states[0] = SharedStructs.StateWithAddress(address(0), abi.encode(1));

        bytes32 root = SharedStructs.getBridgeRoot(state.state.epoch, state.state_hashes);

        vm.expectRevert(
            abi.encodeWithSelector(
                StateNotMatchingBridgeRoot.selector, root, ethBridge.lightClient().getFinalizedBridgeRoot(0)
            )
        );
        ethBridge.applyState(state);
    }

    function test_Revert_OnChangedEpoch() public {
        uint256 settlementFee = taraBridge.settlementFee();
        uint256 value = 1 ether;
        taraConnector.lock{value: value + settlementFee}(value);

        vm.roll(FINALIZATION_INTERVAL);
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        ethLightClient.setBridgeRoot(state);
        state.state.epoch = 2;

        bytes32 root = SharedStructs.getBridgeRoot(state.state.epoch, state.state_hashes);

        vm.expectRevert(
            abi.encodeWithSelector(
                StateNotMatchingBridgeRoot.selector, root, ethBridge.lightClient().getFinalizedBridgeRoot(0)
            )
        );
        ethBridge.applyState(state);
    }

    function test_emptyEpoch() public {
        uint256 settlementFee = taraBridge.settlementFee();
        uint256 value = 1 ether;
        taraConnector.lock{value: value + settlementFee}(value);
        vm.roll(FINALIZATION_INTERVAL);
        taraBridge.finalizeEpoch();
        uint256 finalizedEpoch = taraBridge.getStateWithProof().state.epoch;
        assertEq(finalizedEpoch, 1);
        vm.roll(2 * FINALIZATION_INTERVAL);

        taraBridge.finalizeEpoch();
        // check that we are not finalizing empty epoch
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        assertEq(state.state.epoch, finalizedEpoch, "Epoch should be the same");
        assertEq(state.state.states.length, 0, "State length should be 0");
        assertEq(state.state.epoch, 1, "Epoch should be 1");
    }

    function test_futureEpoch() public {
        uint256 value = 1 ether;
        uint256 settlementFee = taraBridge.settlementFee();
        taraConnector.lock{value: value + settlementFee}(value);
        vm.roll(FINALIZATION_INTERVAL);
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state1 = taraBridge.getStateWithProof();
        taraConnector.lock{value: value + settlementFee}(value);
        vm.roll(2 * FINALIZATION_INTERVAL);
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        assertFalse(state.state.epoch == state1.state.epoch, "Epoch should be the same");
        assertFalse(
            SharedStructs.getBridgeRoot(state.state.epoch, state.state_hashes)
                == SharedStructs.getBridgeRoot(state1.state.epoch, state1.state_hashes),
            "States with different epoch should have different roots"
        );
        assertEq(state1.state_hashes[0].contractAddress, state.state_hashes[0].contractAddress, "Contract address should be the same");
        assertEq(state1.state_hashes[0].stateHash, state.state_hashes[0].stateHash, "State hash should be the same");
        assertEq(state.state.epoch, 2, "Epoch should be 2");
        assertEq(state.state.states.length, 1, "State length should be 1");
        assertEq(state.state.states[0].contractAddress, Constants.NATIVE_TOKEN_ADDRESS, "Contract address should be the same");
        taraLightClient.setBridgeRoot(state);

        vm.expectRevert(
            abi.encodeWithSelector(NotSuccessiveEpochs.selector, taraBridge.appliedEpoch(), state.state.epoch)
        );
        ethBridge.applyState(state);
    }

    function test_multipleTransfers() public {
        uint256 settlementFee = taraBridge.settlementFee();
        uint256 value = 1 ether / 1000;
        uint256 count = 100;
        address[] memory addrs = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            address payable addr = payable(address(uint160(uint256(keccak256(abi.encodePacked(i))))));
            vm.deal(addr, value + settlementFee);
            addrs[i] = addr;
            vm.prank(addr);
            taraConnector.lock{value: value + settlementFee}(value);
        }
        vm.roll(FINALIZATION_INTERVAL);
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        taraLightClient.setBridgeRoot(state);

        ethBridge.applyState(state);

        for (uint256 i = 0; i < count; i++) {
            vm.prank(addrs[i]);
            assertEq(taraTokenOnEth.balanceOf(addrs[i]), value);
        }
        assertEq(taraTokenOnEth.balanceOf(address(this)), 0);
    }
}