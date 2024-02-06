// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import "../src/tara/TaraBridge.sol";
import "../src/tara/TaraConnector.sol";
import "../src/eth/EthBridge.sol";
import "../src/lib/TestERC20.sol";
import "../src/connectors/ERC20LockingConnector.sol";
import "../src/connectors/ERC20MintingConnector.sol";
import "./BridgeLightClientMock.sol";
import "../src/lib/Constants.sol";

contract BridgeTest is Test {
    BridgeLightClientMock taraLightClient;
    BridgeLightClientMock ethLightClient;
    TestERC20 ethTaraToken;
    TaraBridge taraBridge;
    EthBridge ethBridge;

    function setUp() public {
        taraLightClient = new BridgeLightClientMock();
        ethLightClient = new BridgeLightClientMock();
        ethTaraToken = new TestERC20("TARA");
        taraBridge = new TaraBridge(address(ethTaraToken), ethLightClient);
        ethBridge = new EthBridge(IERC20MintableBurnable(address(ethTaraToken)), taraLightClient);
    }

    // define it to not fail on incoming transfers
    receive() external payable {}

    function test_toEth() public {
        uint256 value = 1 ether;
        TaraConnector taraBridgeToken = TaraConnector(address(taraBridge.connectors(Constants.TARA_PLACEHOLDER)));
        taraBridgeToken.lock{value: value}();

        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        taraLightClient.setBridgeRoot(state);
        ethBridge.applyState(state);

        assertEq(ethTaraToken.balanceOf(address(this)), value);
    }

    function test_toTara() public {
        test_toEth();
        uint256 value = 1 ether;
        ERC20MintingConnector ethTaraConnector =
            ERC20MintingConnector(address(ethBridge.connectors(address(ethTaraToken))));
        ethTaraToken.approve(address(ethTaraConnector), value);
        ethTaraConnector.burn(value);

        ethBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = ethBridge.getStateWithProof();
        ethLightClient.setBridgeRoot(state);
        uint256 balance_before = address(this).balance;
        taraBridge.applyState(state);

        assertEq(address(this).balance, balance_before + value);
    }

    function test_failOnChangedState() public {
        uint256 value = 1 ether;
        TaraConnector taraBridgeToken = TaraConnector(address(taraBridge.connectors(Constants.TARA_PLACEHOLDER)));
        taraBridgeToken.lock{value: value}();
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        state.state.states[0] = SharedStructs.StateWithAddress(address(0), abi.encode(1));
        vm.expectRevert("State isn't matching bridge root");
        ethBridge.applyState(state);
    }

    function test_failOnChangedEpoch() public {
        uint256 value = 1 ether;
        TaraConnector taraBridgeToken = TaraConnector(address(taraBridge.connectors(Constants.TARA_PLACEHOLDER)));
        taraBridgeToken.lock{value: value}();
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        ethLightClient.setBridgeRoot(state);
        state.state.epoch = 2;
        vm.expectRevert("State isn't matching bridge root");
        ethBridge.applyState(state);
    }

    function test_emptyEpoch() public {
        uint256 value = 1 ether;
        TaraConnector taraBridgeToken = TaraConnector(address(taraBridge.connectors(Constants.TARA_PLACEHOLDER)));
        taraBridgeToken.lock{value: value}();
        taraBridge.finalizeEpoch();
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        assertEq(state.state.states.length, 1);
        assertEq(state.state.states[0].contractAddress, Constants.TARA_PLACEHOLDER);
        assertEq(state.state.states[0].state, abi.encode(new Transfer[](0)));
    }

    function test_futureEpoch() public {
        uint256 value = 1 ether;
        TaraConnector taraBridgeToken = TaraConnector(address(taraBridge.connectors(Constants.TARA_PLACEHOLDER)));
        taraBridgeToken.lock{value: value}();
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state1 = taraBridge.getStateWithProof();
        taraBridgeToken.lock{value: value}();
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
        assertEq(state.state.states.length, 1);
        assertEq(state.state.states[0].contractAddress, Constants.TARA_PLACEHOLDER);
        taraLightClient.setBridgeRoot(state);
        vm.expectRevert("Epochs should be processed sequentially");
        ethBridge.applyState(state);
    }

    function test_multipleTransfers() public {
        uint256 value = 1 ether / 1000;
        uint256 count = 100;
        address[] memory addrs = new address[](count);
        TaraConnector taraBridgeToken = TaraConnector(address(taraBridge.connectors(Constants.TARA_PLACEHOLDER)));
        for (uint256 i = 0; i < count; i++) {
            address payable addr = payable(address(uint160(uint256(keccak256(abi.encodePacked(i))))));
            addrs[i] = addr;
            addr.transfer(value);
            vm.prank(addr);
            taraBridgeToken.lock{value: value}();
        }
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        taraLightClient.setBridgeRoot(state);

        ethBridge.applyState(state);
        for (uint256 i = 0; i < count; i++) {
            assertEq(ethTaraToken.balanceOf(addrs[i]), value);
        }
    }

    function test_customToken() public returns (TestERC20 taraTestToken, TestERC20 ethTestToken) {
        // deploy and register token on both sides
        taraTestToken = new TestERC20("TEST");
        ethTestToken = new TestERC20("TEST");
        ERC20LockingConnector taraTestTokenConnector = new ERC20LockingConnector(taraTestToken, address(ethTestToken));
        ERC20MintingConnector ethTestTokenConnector = new ERC20MintingConnector(ethTestToken, address(taraTestToken));
        taraBridge.registerContract(taraTestTokenConnector);
        ethBridge.registerContract(ethTestTokenConnector);

        taraTestToken.mintTo(address(this), 10 ether);
        taraTestToken.approve(address(taraTestTokenConnector), 1 ether);
        taraTestTokenConnector.lock(1 ether);
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        assertEq(state.state.epoch, 1, "epoch");
        taraLightClient.setBridgeRoot(state);
        assertEq(ethTestToken.balanceOf(address(this)), 0, "token balance before");
        ethBridge.applyState(state);
        assertEq(ethTestToken.balanceOf(address(this)), 1 ether, "token balance after");
    }

    function test_multipleContractsToEth() public returns (TestERC20 taraTestToken, TestERC20 ethTestToken) {
        (taraTestToken, ethTestToken) = test_customToken();
        uint256 value = 1 ether;

        ERC20LockingConnector taraTestTokenConnector =
            ERC20LockingConnector(address(taraBridge.connectors(address(taraTestToken))));
        taraTestToken.approve(address(taraTestTokenConnector), value);
        taraTestTokenConnector.lock(value);
        uint256 tokenBalanceBefore = ethTestToken.balanceOf(address(this));

        TaraConnector taraBridgeToken = TaraConnector(address(taraBridge.connectors(Constants.TARA_PLACEHOLDER)));
        taraBridgeToken.lock{value: value}();

        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        assertEq(state.state.epoch, 2, "epoch");
        taraLightClient.setBridgeRoot(state);

        assertEq(ethTaraToken.balanceOf(address(this)), 0, "tara balance before");
        assertEq(ethTestToken.balanceOf(address(this)), tokenBalanceBefore, "token balance before");
        ethBridge.applyState(state);

        assertEq(ethTaraToken.balanceOf(address(this)), value, "tara balance after");
        assertEq(ethTestToken.balanceOf(address(this)), tokenBalanceBefore + value, "token balance after");
    }

    function test_returnToTara() public {
        (TestERC20 taraTestToken, TestERC20 ethTestToken) = test_multipleContractsToEth();
        uint256 value = 1 ether;

        ERC20MintingConnector ethTestTokenConnector =
            ERC20MintingConnector(address(ethBridge.connectors(address(ethTestToken))));
        ethTestToken.approve(address(ethTestTokenConnector), value);
        ethTestTokenConnector.burn(value);
        uint256 ethTestTokenBalanceBefore = taraTestToken.balanceOf(address(this));

        ERC20MintingConnector ethTaraTokenConnector =
            ERC20MintingConnector(address(ethBridge.connectors(address(ethTaraToken))));
        ethTaraToken.approve(address(ethTaraTokenConnector), value);
        ethTaraTokenConnector.burn(value);
        uint256 taraBalanceBefore = address(this).balance;

        ethBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = ethBridge.getStateWithProof();
        assertEq(state.state.epoch, 1, "epoch");
        ethLightClient.setBridgeRoot(state);

        assertEq(taraTestToken.balanceOf(address(this)), ethTestTokenBalanceBefore, "token balance before");
        assertEq(address(this).balance, taraBalanceBefore, "tara balance before");
        taraBridge.applyState(state);

        assertEq(taraTestToken.balanceOf(address(this)), ethTestTokenBalanceBefore + value, "token balance after");
        assertEq(address(this).balance, taraBalanceBefore + value, "tara balance after");
    }
}
