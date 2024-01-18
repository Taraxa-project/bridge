// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import "../src/tara/TaraBridge.sol";
import "../src/eth/EthBridge.sol";
import "../src/lib/TestERC20.sol";
import "../src/connectors/ERC20LockingConnector.sol";
import "../src/connectors/ERC20MintingConnector.sol";
import "./BridgeLightClientMock.sol";

contract BridgeTest is Test {
    BridgeLightClientMock taraLightClient;
    BridgeLightClientMock ethLightClient;
    TestERC20 taraToken;
    TaraBridge taraBridge;
    EthBridge ethBridge;
    address constant TARA_DEFAULT = address(1);

    function setUp() public {
        taraLightClient = new BridgeLightClientMock();
        ethLightClient = new BridgeLightClientMock();
        taraToken = new TestERC20("TARA");
        taraBridge = new TaraBridge(address(taraToken), ethLightClient);
        ethBridge = new EthBridge(IERC20MintableBurnable(address(taraToken)), taraLightClient);
    }

    // define it to not fail on incoming transfers
    receive() external payable {}

    function test_taraState() public {
        uint256 value = 1 ether;
        TaraConnector taraBridgeToken = TaraConnector(address(taraBridge.contracts(TARA_DEFAULT)));
        taraBridgeToken.lock{value: value}();

        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        taraLightClient.setBridgeRoot(keccak256(abi.encode(state.state_hashes)));
        ethBridge.applyState(state);

        assertEq(taraToken.balanceOf(address(this)), value);
    }

    function test_ethState() public {
        test_taraState();
        uint256 value = 1 ether;
        ERC20MintingConnector ethTaraConnector = ERC20MintingConnector(address(ethBridge.contracts(address(taraToken))));
        taraToken.approve(address(ethTaraConnector), value);
        ethTaraConnector.burn(value);

        ethBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = ethBridge.getStateWithProof();
        ethLightClient.setBridgeRoot(keccak256(abi.encode(state.state_hashes)));
        uint256 balance_before = address(this).balance;
        taraBridge.applyState(state);

        assertEq(address(this).balance, balance_before + value);
    }

    function test_failOnChangedState() public {
        uint256 value = 1 ether;
        TaraConnector taraBridgeToken = TaraConnector(address(taraBridge.contracts(TARA_DEFAULT)));
        taraBridgeToken.lock{value: value}();
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        state.state.states[0] = SharedStructs.StateWithAddress(address(0), abi.encode(1));
        vm.expectRevert("State isn't matching bridge root");
        ethBridge.applyState(state);
    }

    function test_multipleTransfers() public {
        uint256 value = 1 ether / 1000;
        uint256 count = 100;
        address[] memory addrs = new address[](count);
        TaraConnector taraBridgeToken = TaraConnector(address(taraBridge.contracts(TARA_DEFAULT)));
        for (uint256 i = 0; i < count; i++) {
            address payable addr = payable(address(uint160(uint256(keccak256(abi.encodePacked(i))))));
            addrs[i] = addr;
            addr.transfer(value);
            vm.prank(addr);
            taraBridgeToken.lock{value: value}();
        }
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        bytes32 bridge_root = keccak256(abi.encode(state.state_hashes));
        taraLightClient.setBridgeRoot(bridge_root);

        ethBridge.applyState(state);
        for (uint256 i = 0; i < count; i++) {
            assertEq(taraToken.balanceOf(addrs[i]), value);
        }
    }

    function test_customToken() public {
        // deploy and register token on both sides
        TestERC20 taraTestToken = new TestERC20("TEST");
        TestERC20 ethTestToken = new TestERC20("TEST");
        ERC20LockingConnector taraTestTokenConnector = new ERC20LockingConnector(taraTestToken, address(ethTestToken));
        ERC20MintingConnector ethTestTokenConnector = new ERC20MintingConnector(ethTestToken, address(taraTestToken));
        taraBridge.registerContract(taraTestTokenConnector);
        ethBridge.registerContract(ethTestTokenConnector);

        taraTestToken.mintTo(address(this), 10 ether);
        taraTestToken.approve(address(taraTestTokenConnector), 1 ether);
        taraTestTokenConnector.lock(1 ether);
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        bytes32 bridge_root = keccak256(abi.encode(state.state_hashes));
        taraLightClient.setBridgeRoot(bridge_root);
        assertEq(ethTestToken.balanceOf(address(this)), 0);
        ethBridge.applyState(state);
        assertEq(ethTestToken.balanceOf(address(this)), 1 ether);
    }
}
