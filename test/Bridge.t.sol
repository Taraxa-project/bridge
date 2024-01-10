// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import "../src/tara/Bridge.sol";
import "../src/eth/Bridge.sol";
import "./BridgeLightClientMock.sol";
import "../src/lib/TestERC20.sol";

contract BridgeTest is Test {
    BridgeLightClientMock bridgeLightClient;
    TestERC20 taraToken;
    TaraBridge taraBridge;
    EthBridge ethBridge;

    function setUp() public {
        bridgeLightClient = new BridgeLightClientMock();
        taraToken = new TestERC20("TARA");
        taraBridge = new TaraBridge();
        ethBridge = new EthBridge(taraToken, bridgeLightClient);
        EthBridgeToken taraBridgeToken = ethBridge.tokens("TARA");
        taraToken.mintTo(address(taraBridgeToken), 100000 ether);
        assertEq(taraToken.balanceOf(address(taraBridgeToken)), 100000 ether);
    }

    function test_taraState() public {
        uint256 value = 1 ether;
        taraBridge.transferTara{value: value}();
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        bridgeLightClient.setEpochBridgeRoot(state.proof.state.epoch, state.proof.root_hash);
        ethBridge.finalizeEpoch(state);
        assertEq(taraToken.balanceOf(address(this)), value);
    }

    function test_failOnChangedAmount() public {
        uint256 value = 1 ether;
        taraBridge.transferTara{value: value}();
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        state.state[0].transfers[0].amount = 2 ether;
        vm.expectRevert("Bridge root hash doesn't match");
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
            taraToken.mintTo(addr, 1);
            vm.prank(addr);
            taraBridge.transferTara{value: value}();
        }
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        bridgeLightClient.setEpochBridgeRoot(state.proof.state.epoch, state.proof.root_hash);
        for (uint256 i = 0; i < count; i++) {
            assertEq(state.state[0].transfers[i].account, addrs[i]);
            assertEq(state.state[0].transfers[i].amount, value);
        }
        ethBridge.finalizeEpoch(state);
        for (uint256 i = 0; i < count; i++) {
            assertEq(taraToken.balanceOf(addrs[i]), value + 1);
        }
    }

    function test_customToken() public {
        TestERC20 taraTestToken = new TestERC20("TEST");
        TestERC20 ethTestToken = new TestERC20("TEST");

        taraBridge.registerToken(address(taraTestToken), "TEST");
        ethBridge.registerToken(address(ethTestToken), "TEST");
        assertEq(taraBridge.tokens("TEST").getName(), "TEST");
        assertEq(ethBridge.tokens("TEST").getName(), "TEST");

        taraTestToken.mintTo(address(this), 100000 ether);
        ethTestToken.mintTo(address(ethBridge.tokens("TEST")), 100000 ether);

        taraTestToken.approve(address(taraBridge), 1 ether);
        taraBridge.transferToken("TEST", 1 ether);
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        bridgeLightClient.setEpochBridgeRoot(state.proof.state.epoch, state.proof.root_hash);
        assertEq(ethTestToken.balanceOf(address(this)), 0);
        ethBridge.finalizeEpoch(state);
        assertEq(ethTestToken.balanceOf(address(this)), 1 ether);
    }
}
