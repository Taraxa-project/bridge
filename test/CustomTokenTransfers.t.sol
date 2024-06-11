// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {TaraBridge} from "../src/tara/TaraBridge.sol";
import {EthBridge} from "../src/eth/EthBridge.sol";
import {TestERC20} from "../src/lib/TestERC20.sol";
import {
    StateNotMatchingBridgeRoot, NotSuccessiveEpochs, NotEnoughBlocksPassed
} from "../src/errors/BridgeBaseErrors.sol";
import {NativeConnector} from "../src/connectors/NativeConnector.sol";
import {ERC20LockingConnector} from "../src/connectors/ERC20LockingConnector.sol";
import {ERC20MintingConnector} from "../src/connectors/ERC20MintingConnector.sol";
import {BridgeLightClientMock} from "./BridgeLightClientMock.sol";
import {Constants} from "../src/lib/Constants.sol";
import {SharedStructs} from "../src/lib/SharedStructs.sol";
import {SymmetricTestSetup} from "./SymmetricTestSetup.t.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract CustomTokenTransfersTest is SymmetricTestSetup {
    function test_customToken() public returns (TestERC20 taraTestToken, TestERC20 ethTestToken) {
        // deploy and register token on both sides
        taraTestToken = new TestERC20("Test", "TEST");
        ethTestToken = new TestERC20("Test", "TEST");
        address taraTestTokenConnectorProxy = Upgrades.deployUUPSProxy(
            "ERC20LockingConnector.sol",
            abi.encodeWithSelector(
                ERC20LockingConnector.initialize.selector, address(taraBridge), taraTestToken, address(ethTestToken)
            )
        );
        ERC20LockingConnector taraTestTokenConnector = ERC20LockingConnector(payable(taraTestTokenConnectorProxy));

        address ethTestTokenConnectorProxy = Upgrades.deployUUPSProxy(
            "ERC20MintingConnector.sol",
            abi.encodeWithSelector(
                ERC20MintingConnector.initialize.selector, address(ethBridge), ethTestToken, address(taraTestToken)
            )
        );
        ERC20MintingConnector ethTestTokenConnector = ERC20MintingConnector(payable(ethTestTokenConnectorProxy));

        taraTestToken.mintTo(address(this), 10 ether);
        taraTestToken.approve(address(taraTestTokenConnector), 1 ether);
        // give ownership of erc20s to the connectors
        taraTestToken.transferOwnership(address(taraTestTokenConnector));
        ethTestToken.transferOwnership(address(ethTestTokenConnector));

        taraTestTokenConnector.transferOwnership(address(taraBridge));
        ethTestTokenConnector.transferOwnership(address(ethBridge));

        taraBridge.registerContract{value: REGISTRATION_FEE_TARA}(taraTestTokenConnector);
        ethBridge.registerContract{value: REGISTRATION_FEE_ETH}(ethTestTokenConnector);

        uint256 settlementFee = taraBridge.settlementFee();

        taraTestTokenConnector.lock{value: 1 ether + settlementFee}(1 ether);
        vm.roll(FINALIZATION_INTERVAL);
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        assertEq(state.state.epoch, 1, "epoch");
        taraLightClient.setBridgeRoot(state);
        assertEq(ethTestToken.balanceOf(address(this)), 0, "token balance before");

        vm.prank(caller);
        ethBridge.applyState(state);

        assertEq(ethTestToken.balanceOf(address(this)), 1 ether, "token balance after");
    }

    function test_multipleContractsToEth() public returns (TestERC20 taraTestToken, TestERC20 ethTestToken) {
        (taraTestToken, ethTestToken) = test_customToken();
        uint256 value = 1 ether;
        uint256 settlementFee = taraBridge.settlementFee();

        ERC20LockingConnector taraTestTokenConnector =
            ERC20LockingConnector(payable(address(taraBridge.connectors(address(taraTestToken)))));
        taraTestToken.approve(address(taraTestTokenConnector), value);
        taraTestTokenConnector.lock{value: value + settlementFee}(value);
        uint256 tokenBalanceBefore = ethTestToken.balanceOf(address(this));

        NativeConnector taraBridgeTokenConnector =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));
        taraBridgeTokenConnector.lock{value: value + settlementFee}(value);

        vm.roll(2 * FINALIZATION_INTERVAL);
        vm.prank(caller);
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        assertEq(state.state.epoch, 2, "epoch");
        taraLightClient.setBridgeRoot(state);

        assertEq(taraTokenOnEth.balanceOf(address(this)), 0, "tara balance before");
        assertEq(ethTestToken.balanceOf(address(this)), tokenBalanceBefore, "token balance before");

        // call from other account to not affect balances
        vm.prank(caller);
        ethBridge.applyState(state);

        assertEq(taraTokenOnEth.balanceOf(address(this)), value, "tara balance after");
        assertEq(ethTestToken.balanceOf(address(this)), tokenBalanceBefore + value, "token balance after");
    }

    function test_returnToTara() public {
        (TestERC20 taraTestToken, TestERC20 ethTestToken) = test_multipleContractsToEth();
        uint256 value = 1 ether;
        uint256 settlementFee = taraBridge.settlementFee();

        ERC20MintingConnector ethTestTokenConnector =
            ERC20MintingConnector(payable(address(ethBridge.connectors(address(ethTestToken)))));
        ethTestToken.approve(address(ethTestTokenConnector), value);
        ethTestTokenConnector.burn{value: value + settlementFee}(value);
        uint256 ethTestTokenBalanceBefore = taraTestToken.balanceOf(address(this));

        ERC20MintingConnector ethTaraTokenConnector =
            ERC20MintingConnector(payable(address(ethBridge.connectors(address(taraTokenOnEth)))));
        taraTokenOnEth.approve(address(ethTaraTokenConnector), value);
        ethTaraTokenConnector.burn{value: value + settlementFee}(value);
        uint256 taraBalanceBefore = address(this).balance;

        vm.roll(3 * FINALIZATION_INTERVAL);
        ethBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = ethBridge.getStateWithProof();
        assertEq(state.state.epoch, 1, "epoch");
        ethLightClient.setBridgeRoot(state);

        assertEq(taraTestToken.balanceOf(address(this)), ethTestTokenBalanceBefore, "token balance before");
        assertEq(address(this).balance, taraBalanceBefore, "tara balance before");

        vm.prank(caller);
        taraBridge.applyState(state);

        assertEq(taraTestToken.balanceOf(address(this)), ethTestTokenBalanceBefore + value, "token balance after");
    }
}
