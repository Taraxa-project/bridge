// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../src/tara/TaraBridge.sol";
import "../src/eth/EthBridge.sol";
import "../src/lib/TestERC20.sol";
import {
    StateNotMatchingBridgeRoot, NotSuccessiveEpochs, NotEnoughBlocksPassed
} from "../src/errors/BridgeBaseErrors.sol";
import "../src/connectors/NativeConnector.sol";
import "../src/connectors/ERC20LockingConnector.sol";
import "../src/connectors/ERC20MintingConnector.sol";
import "./BridgeLightClientMock.sol";
import "../src/lib/Constants.sol";
import "./SymmetricTestSetup.t.sol";

contract StateTransfersTest is SymmetricTestSetup {
    function test_Revert_toEth_on_not_enough_blocks_passed() public {
        uint256 value = 1 ether;
        NativeConnector taraBridgeToken =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));
        taraBridgeToken.lock{value: value}();

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

    function test_Revert_toEth_on_zero_value() public {
        NativeConnector taraBridgeToken =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));
        vm.expectRevert();
        taraBridgeToken.lock{value: 0}();

        vm.roll(FINALIZATION_INTERVAL);

        vm.expectRevert();
        taraBridge.finalizeEpoch();
        vm.expectRevert();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        taraLightClient.setBridgeRoot(state);
        vm.expectRevert();
        ethBridge.applyState(state);

        ERC20MintingConnector ethTaraTokenConnector =
            ERC20MintingConnector(payable(address(ethBridge.connectors(address(taraTokenOnEth)))));
        vm.expectRevert();
        ethTaraTokenConnector.claim{value: 0}();
    }

    function test_toEth() public {
        uint256 value = 1 ether;
        NativeConnector taraBridgeToken =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));
        taraBridgeToken.lock{value: value}();

        vm.roll(FINALIZATION_INTERVAL);

        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        taraLightClient.setBridgeRoot(state);
        ethBridge.applyState(state);

        ERC20MintingConnector ethTaraTokenConnector =
            ERC20MintingConnector(payable(address(ethBridge.connectors(address(taraTokenOnEth)))));
        ethTaraTokenConnector.claim{value: ethTaraTokenConnector.feeToClaim(address(this))}();
        assertEq(taraTokenOnEth.balanceOf(address(this)), value);
    }

    function test_toTara() public {
        test_toEth();
        uint256 value = 1 ether;
        ERC20MintingConnector ethNativeConnector =
            ERC20MintingConnector(payable(address(ethBridge.connectors(address(taraTokenOnEth)))));
        taraTokenOnEth.approve(address(ethNativeConnector), value);
        ethNativeConnector.burn(value);

        vm.roll(FINALIZATION_INTERVAL);

        ethBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = ethBridge.getStateWithProof();
        ethLightClient.setBridgeRoot(state);
        uint256 balance_before = address(this).balance;

        vm.prank(caller);
        taraBridge.applyState(state);

        NativeConnector taraConnector =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));
        uint256 claim_fee = taraConnector.feeToClaim(address(this));
        taraConnector.claim{value: claim_fee}();
        assertEq(address(this).balance, balance_before + value - claim_fee);
    }

    function test_Revert_OnChangedState() public {
        uint256 value = 1 ether;
        NativeConnector taraConnector =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));
        taraConnector.lock{value: value}();

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
        uint256 value = 1 ether;
        NativeConnector taraConnector =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));
        taraConnector.lock{value: value}();

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
        uint256 value = 1 ether;
        NativeConnector taraConnector =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));
        taraConnector.lock{value: value}();
        vm.roll(FINALIZATION_INTERVAL);
        taraBridge.finalizeEpoch();
        uint256 finalizedEpoch = taraBridge.getStateWithProof().state.epoch;
        assertEq(finalizedEpoch, 1, "finalized epoch should be 1");

        vm.roll(2 * FINALIZATION_INTERVAL);

        vm.expectRevert();
        taraBridge.finalizeEpoch();
        // check that we are not finalizing empty epoch
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        assertEq(state.state.epoch, finalizedEpoch, "epoch should be the same as the finalized epoch");
        assertEq(state.state.states.length, 2, "state should have 2 states");
        assertEq(state.state.epoch, 1, "epoch should be 1");
        assertEq(
            state.state.states[0].contractAddress, Constants.NATIVE_TOKEN_ADDRESS, "first state should be native token"
        );
    }

    function test_futureEpoch() public {
        uint256 value = 1 ether;
        NativeConnector taraConnector =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));
        taraConnector.lock{value: value}();
        vm.roll(FINALIZATION_INTERVAL);
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state1 = taraBridge.getStateWithProof();
        taraConnector.lock{value: value}();
        vm.roll(2 * FINALIZATION_INTERVAL);
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        assertFalse(state.state.epoch == state1.state.epoch);
        assertFalse(
            SharedStructs.getBridgeRoot(state.state.epoch, state.state_hashes)
                == SharedStructs.getBridgeRoot(state1.state.epoch, state1.state_hashes),
            "States with different epoch should have different roots"
        );
        assertEq(state1.state_hashes[0].contractAddress, state.state_hashes[0].contractAddress);
        assertEq(state1.state_hashes[0].stateHash, state.state_hashes[0].stateHash);
        assertEq(state.state.epoch, 2);
        assertEq(state.state.states.length, 2);
        assertEq(state.state.states[0].contractAddress, Constants.NATIVE_TOKEN_ADDRESS);
        taraLightClient.setBridgeRoot(state);

        vm.expectRevert(
            abi.encodeWithSelector(NotSuccessiveEpochs.selector, taraBridge.appliedEpoch(), state.state.epoch)
        );
        ethBridge.applyState(state);
    }

    function test_multipleTransfers() public {
        uint256 value = 1 ether / 1000;
        uint256 count = 100;
        address[] memory addrs = new address[](count);
        NativeConnector taraConnector =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));
        for (uint256 i = 0; i < count; i++) {
            address payable addr = payable(address(uint160(uint256(keccak256(abi.encodePacked(i))))));
            addrs[i] = addr;
            addr.transfer(10 * value);
            vm.prank(addr);
            taraConnector.lock{value: value}();
        }
        vm.roll(FINALIZATION_INTERVAL);
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        taraLightClient.setBridgeRoot(state);

        ethBridge.applyState(state);
        ERC20LockingConnector ethNativeConnector = ERC20LockingConnector(
            payable(
                address(ethBridge.connectors(address(ethBridge.localAddress(address(Constants.NATIVE_TOKEN_ADDRESS)))))
            )
        );
        for (uint256 i = 0; i < count; i++) {
            vm.prank(addrs[i]);
            uint256 fee = ethNativeConnector.feeToClaim(addrs[i]);
            vm.prank(addrs[i]);
            ethNativeConnector.claim{value: fee}();
            assertEq(taraTokenOnEth.balanceOf(addrs[i]), value);
        }
        assertEq(taraTokenOnEth.balanceOf(address(this)), 0);
    }
}
