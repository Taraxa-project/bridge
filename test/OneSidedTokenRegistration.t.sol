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

contract OneSidedTokenRegistrationTest is SymmetricTestSetup {
    function test_customToken() public returns (TestERC20 taraTestToken, TestERC20 ethTestToken) {
        // deploy and register token on both sides
        vm.startPrank(caller);
        taraTestToken = new TestERC20("Test", "TEST");
        address randomEthTestAddress = vm.addr(11111);
        ethTestToken = TestERC20(randomEthTestAddress);
        address taraTestTokenConnectorProxy = Upgrades.deployUUPSProxy(
            "ERC20LockingConnector.sol",
            abi.encodeCall(ERC20LockingConnector.initialize, (taraBridge, taraTestToken, randomEthTestAddress))
        );
        ERC20LockingConnector taraTestTokenConnector = ERC20LockingConnector(payable(taraTestTokenConnectorProxy));

        address ethTestTokenConnectorProxy = Upgrades.deployUUPSProxy(
            "ERC20MintingConnector.sol",
            abi.encodeCall(ERC20MintingConnector.initialize, (ethBridge, ethTestToken, address(taraTestToken)))
        );
        ERC20MintingConnector ethTestTokenConnector = ERC20MintingConnector(payable(ethTestTokenConnectorProxy));

        taraTestToken.mintTo(address(caller), 10 ether);
        taraTestToken.mintTo(address(this), 10 ether);
        taraTestToken.approve(address(taraTestTokenConnector), 1 ether);

        // give ownership of erc20s to the connectors
        taraTestToken.transferOwnership(address(taraTestTokenConnector));
        // ethTestToken.transferOwnership(address(ethTestTokenConnector));

        taraTestTokenConnector.transferOwnership(address(taraBridge));

        vm.deal(caller, REGISTRATION_FEE_TARA);
        taraBridge.registerContract(taraTestTokenConnector);

        taraTestTokenConnector.lock(1 ether);
        vm.roll(FINALIZATION_INTERVAL);
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        assertEq(state.state.epoch, 1, "epoch");
        taraLightClient.setBridgeRoot(state);
        // assertEq(ethTestToken.balanceOf(address(caller)), 0, "token balance before");

        ethBridge.applyState(state);

        // ethTestTokenConnector.claim{value: ethTestTokenConnector.feeToClaim(address(this))}();
        vm.stopPrank();

        // assertEq(ethTestToken.balanceOf(address(caller)), 1 ether, "token balance after");
    }

    function test_multipleContractsToEth() public returns (TestERC20 taraTestToken, TestERC20 ethTestToken) {
        (taraTestToken, ethTestToken) = test_customToken();
        uint256 value = 1 ether;

        ERC20LockingConnector taraTestTokenConnector =
            ERC20LockingConnector(payable(address(taraBridge.connectors(address(taraTestToken)))));
        taraTestToken.approve(address(taraTestTokenConnector), value);
        taraTestTokenConnector.lock(value);
        // uint256 tokenBalanceBefore = ethTestToken.balanceOf(address(this));

        NativeConnector taraBridgeTokenConnector =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));
        taraBridgeTokenConnector.lock{value: value}();

        vm.roll(2 * FINALIZATION_INTERVAL);
        vm.prank(caller);
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        assertEq(state.state.epoch, 2, "epoch");
        taraLightClient.setBridgeRoot(state);

        assertEq(taraTokenOnEth.balanceOf(address(this)), 0, "tara balance before");
        // assertEq(ethTestToken.balanceOf(address(this)), tokenBalanceBefore, "token balance before");

        // call from other account to not affect balances
        vm.prank(caller);
        ethBridge.applyState(state);

        // ethTestTokenConnector.claim{value: ethTestTokenConnector.feeToClaim(address(this))}();

        assertEq(taraTokenOnEth.balanceOf(address(this)), value, "tara balance after");
        // assertEq(ethTestToken.balanceOf(address(this)), tokenBalanceBefore + value, "token balance after");
    }

    function test_Revert_returnToTara_claimFails_on_onesidedRegistration() public {
        (TestERC20 taraTestToken, TestERC20 ethTestToken) = test_multipleContractsToEth();
        uint256 value = 1 ether;

        // ERC20MintingConnector ethTestTokenConnector =
        //     ERC20MintingConnector(payable(address(ethBridge.connectors(address(ethTestToken)))));
        // ethTestToken.approve(address(ethTestTokenConnector), value);
        // ethTestTokenConnector.burn(value);
        uint256 ethTestTokenBalanceBefore = taraTestToken.balanceOf(address(this));

        ERC20MintingConnector ethTaraTokenConnector =
            ERC20MintingConnector(payable(address(ethBridge.connectors(address(taraTokenOnEth)))));
        taraTokenOnEth.approve(address(ethTaraTokenConnector), value);
        ethTaraTokenConnector.burn(value);
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
