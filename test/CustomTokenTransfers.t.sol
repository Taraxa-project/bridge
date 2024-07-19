// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {TestERC20} from "../src/lib/TestERC20.sol";
import {NativeConnector} from "../src/connectors/NativeConnector.sol";
import {ERC20LockingConnector} from "../src/connectors/ERC20LockingConnector.sol";
import {ERC20MintingConnector} from "../src/connectors/ERC20MintingConnector.sol";
import {Constants} from "../src/lib/Constants.sol";
import {SharedStructs} from "../src/lib/SharedStructs.sol";
import {SymmetricTestSetup} from "./SymmetricTestSetup.t.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract CustomTokenTransfersTest is SymmetricTestSetup {
    function test_customToken() public returns (TestERC20 taraTestToken, TestERC20 ethTestToken) {
        // deploy and register token on both sides
        vm.startPrank(caller);
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

        taraTestToken.mintTo(address(caller), 2 ether);
        taraTestToken.approve(address(taraTestTokenConnector), 1 ether);
        // give ownership of erc20s to the connectors
        taraTestToken.transferOwnership(address(taraTestTokenConnector));
        ethTestToken.transferOwnership(address(ethTestTokenConnector));

        // taraTestTokenConnector.transferOwnership(address(taraBridge));
        // ethTestTokenConnector.transferOwnership(address(ethBridge));
        vm.deal(address(caller), REGISTRATION_FEE_TARA);
        taraBridge.registerContract{value: REGISTRATION_FEE_TARA}(taraTestTokenConnector);
        vm.deal(address(caller), REGISTRATION_FEE_ETH);
        ethBridge.registerContract{value: REGISTRATION_FEE_ETH}(ethTestTokenConnector);

        uint256 settlementFee = taraBridge.settlementFee();
        vm.deal(address(caller), settlementFee);
        taraTestTokenConnector.lock{value: settlementFee}(1 ether);
        vm.roll(FINALIZATION_INTERVAL);
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        assertEq(state.state.epoch, 1, "epoch");
        taraLightClient.setBridgeRoot(state);
        assertEq(ethTestToken.balanceOf(address(caller)), 0, "token balance before");

        ethBridge.applyState(state);

        assertEq(ethTestToken.balanceOf(address(caller)), 1 ether, "token balance after");
        vm.stopPrank();
    }

    function test_multipleContractsToEth() public returns (TestERC20 taraTestToken, TestERC20 ethTestToken) {
        (taraTestToken, ethTestToken) = test_customToken();
        vm.startPrank(caller);
        uint256 value = 1 ether;
        uint256 settlementFee = taraBridge.settlementFee();

        ERC20LockingConnector taraTestTokenConnector =
            ERC20LockingConnector(payable(address(taraBridge.connectors(address(taraTestToken)))));
        taraTestToken.approve(address(taraTestTokenConnector), value);
        vm.deal(address(caller), settlementFee);
        taraTestTokenConnector.lock{value: settlementFee}(value);
        uint256 tokenBalanceBefore = ethTestToken.balanceOf(address(caller));

        NativeConnector taraBridgeTokenConnector =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));
        vm.deal(address(caller), settlementFee + 1 ether);
        taraBridgeTokenConnector.lock{value: value + settlementFee}(value);

        vm.roll(2 * FINALIZATION_INTERVAL);
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        assertEq(state.state.epoch, 2, "epoch");
        taraLightClient.setBridgeRoot(state);

        assertEq(taraTokenOnEth.balanceOf(address(caller)), 0, "tara balance before");
        assertEq(ethTestToken.balanceOf(address(caller)), tokenBalanceBefore, "token balance before");

        // call from other account to not affect balances
        ethBridge.applyState(state);

        assertEq(taraTokenOnEth.balanceOf(address(caller)), value, "tara balance after");
        assertEq(ethTestToken.balanceOf(address(caller)), tokenBalanceBefore + value, "token balance after");
    }

    function test_returnToTara() public {
        (TestERC20 taraTestToken, TestERC20 ethTestToken) = test_multipleContractsToEth();
        vm.startPrank(caller);
        uint256 value = 1 ether;
        uint256 settlementFee = ethBridge.settlementFee();

        ERC20MintingConnector ethTestTokenConnector =
            ERC20MintingConnector(payable(address(ethBridge.connectors(address(ethTestToken)))));
        ethTestToken.approve(address(ethTestTokenConnector), value);
        vm.deal(address(caller), settlementFee);
        ethTestTokenConnector.burn{value: settlementFee}(value);
        uint256 ethTestTokenBalanceBefore = taraTestToken.balanceOf(address(caller));

        ERC20MintingConnector ethTaraTokenConnector =
            ERC20MintingConnector(payable(address(ethBridge.connectors(address(taraTokenOnEth)))));
        taraTokenOnEth.approve(address(ethTaraTokenConnector), value);
        vm.deal(address(caller), value + settlementFee);
        ethTaraTokenConnector.burn{value: value + settlementFee}(value);
        uint256 taraBalanceBefore = address(caller).balance;

        vm.roll(3 * FINALIZATION_INTERVAL);
        ethBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = ethBridge.getStateWithProof();
        assertEq(state.state.epoch, 1, "epoch");
        ethLightClient.setBridgeRoot(state);

        assertEq(taraTestToken.balanceOf(address(caller)), ethTestTokenBalanceBefore, "token balance before");
        assertEq(address(caller).balance, taraBalanceBefore, "tara balance before");

        taraBridge.applyState(state);

        assertEq(taraTestToken.balanceOf(address(caller)), ethTestTokenBalanceBefore + value, "token balance after");
    }
}
