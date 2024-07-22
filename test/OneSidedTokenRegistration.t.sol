// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {TestERC20} from "../src/lib/TestERC20.sol";
import {NativeConnector} from "../src/connectors/NativeConnector.sol";
import {ERC20LockingConnector} from "../src/connectors/ERC20LockingConnector.sol";
import {ERC20MintingConnector} from "../src/connectors/ERC20MintingConnector.sol";
import {ERC20LockingConnectorMock} from "./baseContracts/ERC20LockingConnectorMock.sol";
import {ERC20MintingConnectorMock} from "./baseContracts/ERC20MintingConnectorMock.sol";
import {Constants} from "../src/lib/Constants.sol";
import {SharedStructs} from "../src/lib/SharedStructs.sol";
import {SymmetricTestSetup} from "./SymmetricTestSetup.t.sol";

contract OneSidedTokenRegistrationTest is SymmetricTestSetup {
    function test_Single_customToken() public returns (TestERC20 taraTestToken, TestERC20 ethTestToken) {
        // deploy and register token on both sides
        vm.startPrank(caller);
        taraTestToken = new TestERC20("Test", "TEST");
        address randomEthTestAddress = vm.addr(11111);
        ethTestToken = TestERC20(randomEthTestAddress);
        ERC20LockingConnectorMock taraTestTokenConnector =
            new ERC20LockingConnectorMock(taraBridge, taraTestToken, randomEthTestAddress);
        new ERC20MintingConnectorMock(ethBridge, ethTestToken, address(taraTestToken));

        taraTestToken.mintTo(address(caller), 10 ether);
        taraTestToken.mintTo(address(this), 10 ether);
        taraTestToken.approve(address(taraTestTokenConnector), 1 ether);

        // give ownership of erc20s to the connectors
        taraTestToken.transferOwnership(address(taraTestTokenConnector));

        uint256 settlementFee = taraBridge.settlementFee();
        vm.deal(caller, REGISTRATION_FEE_TARA);
        taraBridge.registerConnector{value: REGISTRATION_FEE_TARA}(taraTestTokenConnector);
        vm.deal(address(caller), 1 ether + settlementFee);
        taraTestTokenConnector.lock{value: 1 ether + settlementFee}(1 ether);
        vm.roll(FINALIZATION_INTERVAL);
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        assertEq(state.state.epoch, 1, "epoch");
        taraLightClient.setBridgeRoot(state);

        ethBridge.applyState(state);

        vm.stopPrank();
    }

    function test_multipleOnesidedContractsToEth() public returns (TestERC20 taraTestToken, TestERC20 ethTestToken) {
        (taraTestToken, ethTestToken) = test_Single_customToken();
        uint256 value = 1 ether;
        uint256 settlementFee = taraBridge.settlementFee();
        ERC20LockingConnector taraTestTokenConnector =
            ERC20LockingConnector(payable(address(taraBridge.connectors(address(taraTestToken)))));
        taraTestToken.approve(address(taraTestTokenConnector), value);
        vm.deal(address(this), value + settlementFee);
        taraTestTokenConnector.lock{value: value + settlementFee}(value);

        NativeConnector taraBridgeTokenConnector =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));
        vm.deal(address(this), value + settlementFee);
        taraBridgeTokenConnector.lock{value: value + settlementFee}(value);

        vm.roll(2 * FINALIZATION_INTERVAL);
        vm.prank(caller);
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        assertEq(state.state.epoch, 2, "epoch");
        taraLightClient.setBridgeRoot(state);

        assertEq(taraTokenOnEth.balanceOf(address(this)), 0, "tara balance before");

        // call from other account to not affect balances
        vm.prank(caller);
        ethBridge.applyState(state);

        assertEq(taraTokenOnEth.balanceOf(address(this)), value, "tara balance after");
    }

    function test_Revert_returnToTara_claimFails_on_onesidedRegistration() public {
        (TestERC20 taraTestToken,) = test_multipleOnesidedContractsToEth();
        uint256 value = 1 ether;

        uint256 ethTestTokenBalanceBefore = taraTestToken.balanceOf(address(this));
        uint256 settlementFee = taraBridge.settlementFee();
        ERC20MintingConnector ethTaraTokenConnector =
            ERC20MintingConnector(payable(address(ethBridge.connectors(address(taraTokenOnEth)))));
        taraTokenOnEth.approve(address(ethTaraTokenConnector), value);
        vm.deal(address(this), value + settlementFee);
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

        assertEq(taraTestToken.balanceOf(address(this)), ethTestTokenBalanceBefore, "token balance after");
    }
}
