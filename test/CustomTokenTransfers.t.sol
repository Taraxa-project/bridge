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

        // fund connectors
        (bool success,) = payable(address(taraTestTokenConnector)).call{value: 2 ether}("");
        if (!success) {
            revert("Failed to fund tara connector");
        }
        (bool success2,) = payable(address(ethTestTokenConnector)).call{value: 2 ether}("");
        if (!success2) {
            revert("Failed to fund eth connector");
        }

        taraBridge.registerContract(taraTestTokenConnector);
        ethBridge.registerContract(ethTestTokenConnector);

        taraTestToken.mintTo(address(caller), 10 ether);
        taraTestToken.approve(address(taraTestTokenConnector), 1 ether);

        // give ownership of erc20s to the connectors
        taraTestToken.transferOwnership(address(taraTestTokenConnector));
        ethTestToken.transferOwnership(address(ethTestTokenConnector));

        taraTestTokenConnector.lock(1 ether);
        vm.roll(FINALIZATION_INTERVAL);
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        assertEq(state.state.epoch, 1, "epoch");
        taraLightClient.setBridgeRoot(state);
        assertEq(ethTestToken.balanceOf(address(caller)), 0, "token balance before");

        ethBridge.applyState(state);

        ethTestTokenConnector.claim{value: ethTestTokenConnector.feeToClaim(address(caller))}();
        vm.stopPrank();

        assertEq(ethTestToken.balanceOf(address(caller)), 1 ether, "token balance after");
    }

    function test_multipleContractsToEth() public returns (TestERC20 taraTestToken, TestERC20 ethTestToken) {
        (taraTestToken, ethTestToken) = test_customToken();
        vm.startPrank(caller);
        uint256 value = 1 ether;

        ERC20LockingConnector taraTestTokenConnector =
            ERC20LockingConnector(payable(address(taraBridge.connectors(address(taraTestToken)))));
        taraTestToken.approve(address(taraTestTokenConnector), value);
        taraTestTokenConnector.lock(value);
        uint256 tokenBalanceBefore = ethTestToken.balanceOf(address(caller));

        NativeConnector taraBridgeTokenConnector =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));
        taraBridgeTokenConnector.lock{value: value}();

        vm.roll(2 * FINALIZATION_INTERVAL);
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        assertEq(state.state.epoch, 2, "epoch");
        taraLightClient.setBridgeRoot(state);

        assertEq(taraTokenOnEth.balanceOf(address(caller)), 0, "tara balance before");
        assertEq(ethTestToken.balanceOf(address(caller)), tokenBalanceBefore, "token balance before");

        // call from other account to not affect balances
        ethBridge.applyState(state);

        ERC20MintingConnector ethTestTokenConnector =
            ERC20MintingConnector(payable(address(ethBridge.connectors(address(ethTestToken)))));
        ethTestTokenConnector.claim{value: ethTestTokenConnector.feeToClaim(address(caller))}();

        NativeConnector ethNativeConnector = NativeConnector(
            payable(
                address(ethBridge.connectors(address(ethBridge.localAddress(address(Constants.NATIVE_TOKEN_ADDRESS)))))
            )
        );
        ethNativeConnector.claim{value: ethNativeConnector.feeToClaim(address(caller))}();

        assertEq(taraTokenOnEth.balanceOf(address(caller)), value, "tara balance after");
        assertEq(ethTestToken.balanceOf(address(caller)), tokenBalanceBefore + value, "token balance after");
        vm.stopPrank();
    }

    function test_returnToTara() public {
        (TestERC20 taraTestToken, TestERC20 ethTestToken) = test_multipleContractsToEth();
        vm.startPrank(caller);
        uint256 value = 1 ether;

        ERC20MintingConnector ethTestTokenConnector =
            ERC20MintingConnector(payable(address(ethBridge.connectors(address(ethTestToken)))));
        ethTestToken.approve(address(ethTestTokenConnector), value);
        ethTestTokenConnector.burn(value);
        uint256 ethTestTokenBalanceBefore = taraTestToken.balanceOf(address(caller));

        ERC20MintingConnector ethTaraTokenConnector =
            ERC20MintingConnector(payable(address(ethBridge.connectors(address(taraTokenOnEth)))));
        taraTokenOnEth.approve(address(ethTaraTokenConnector), value);
        ethTaraTokenConnector.burn(value);
        uint256 taraBalanceBefore = address(caller).balance;

        vm.roll(3 * FINALIZATION_INTERVAL);
        ethBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = ethBridge.getStateWithProof();
        assertEq(state.state.epoch, 1, "epoch");
        ethLightClient.setBridgeRoot(state);

        assertEq(taraTestToken.balanceOf(address(caller)), ethTestTokenBalanceBefore, "token balance before");
        assertEq(address(caller).balance, taraBalanceBefore, "tara balance before");

        taraBridge.applyState(state);

        ERC20MintingConnector taraTestTokenConnector =
            ERC20MintingConnector(payable(address(taraBridge.connectors(address(taraTestToken)))));
        uint256 claim_fee = taraTestTokenConnector.feeToClaim(address(caller));
        taraTestTokenConnector.claim{value: claim_fee}();

        NativeConnector taraConnector =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));
        uint256 claim_fee2 = taraConnector.feeToClaim(address(caller));
        taraConnector.claim{value: claim_fee2}();

        assertEq(taraTestToken.balanceOf(address(caller)), ethTestTokenBalanceBefore + value, "token balance after");
        assertEq(address(caller).balance, taraBalanceBefore + value - claim_fee - claim_fee2, "tara balance after");
        vm.stopPrank();
    }
}
