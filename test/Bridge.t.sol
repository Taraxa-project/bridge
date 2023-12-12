// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import "../src/tara/Bridge.sol";
import "../src/eth/Bridge.sol";
import "./BridgeLightClientMock.sol";
import "../src/lib/TestERC20.sol";

contract BridgeTest is Test {
    BridgeLightClientMock bridgeLightClient;
    TestERC20 tara_token;
    TaraBridge taraBridge;
    EthBridge ethBridge;

    function setUp() public {
        bridgeLightClient = new BridgeLightClientMock();
        tara_token = new TestERC20("TARA");
        taraBridge = new TaraBridge();
        ethBridge = new EthBridge(tara_token, bridgeLightClient);
        EthBridgeToken taraBridgeToken = ethBridge.tokens("TARA");
        tara_token.mintTo(address(taraBridgeToken), 100000 ether);
        assertEq(tara_token.balanceOf(address(taraBridgeToken)), 100000 ether);
    }

    function test_taraState() public {
        uint256 value = 1 ether;
        taraBridge.transferTara{value: value}();
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        ethBridge.finalizeEpoch(state);
        assertEq(tara_token.balanceOf(address(this)), value);
    }

    function test_failOnChangedAmount() public {
        uint256 value = 1 ether;
        taraBridge.transferTara{value: value}();
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        state.state[0].transfers[0].amount = 2 ether;
        vm.expectRevert("State hash not found in proof");
        ethBridge.finalizeEpoch(state);
    }

    function test_multipleTransfers() public {
        uint256 value = 1 ether / 1000;
        uint256 count = 100;
        address[] memory addrs = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            address payable addr = payable(address(uint160(uint256(keccak256(abi.encodePacked(i))))));
            addrs[i] = addr;
            addr.transfer(value);
            tara_token.mintTo(addr, 1);
            vm.prank(addr);
            taraBridge.transferTara{value: value}();
        }
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        bridgeLightClient.setEpochBridgeRoot(state.proof.state.epoch, state.proof.root_hash);
        ethBridge.finalizeEpoch(state);
        for (uint256 i = 0; i < count; i++) {
            assertEq(tara_token.balanceOf(addrs[i]), value + 1);
        }
    }

    function test_multipleTransfersOptimistic() public {
        uint256 value = 1 ether / 1000;
        uint256 count = 100;
        address[] memory addrs = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            address payable addr = payable(address(uint160(uint256(keccak256(abi.encodePacked(i))))));
            addrs[i] = addr;
            addr.transfer(value);
            vm.prank(addr);
            taraBridge.transferTara{value: value}();
        }
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        bridgeLightClient.setEpochBridgeRoot(state.proof.state.epoch, state.proof.root_hash);
        ethBridge.submitTokenState("TARA", state.state[0]);
        vm.roll(block.number + 11);
        ethBridge.finalize();
        for (uint256 i = 0; i < count; i++) {
            assertEq(tara_token.balanceOf(addrs[i]), value);
        }
    }
}
