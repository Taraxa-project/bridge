//// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {TaraBridge} from "../src/tara/TaraBridge.sol";
import {EthBridge} from "../src/eth/EthBridge.sol";
import {TestERC20} from "../src/lib/TestERC20.sol";
import {NativeConnector} from "../src/connectors/NativeConnector.sol";
import {ERC20LockingConnector} from "../src/connectors/ERC20LockingConnector.sol";
import {ERC20MintingConnector} from "../src/connectors/ERC20MintingConnector.sol";
import {Constants} from "../src/lib/Constants.sol";
import {SharedStructs} from "../src/lib/SharedStructs.sol";
import {SymmetricTestSetup} from "./SymmetricTestSetup.t.sol";
import {IBridgeConnector} from "src/connectors/IBridgeConnector.sol";
import {NotBridge} from "../src/errors/ConnectorErrors.sol";

contract ConnectorAccessLevelTest is SymmetricTestSetup {
    function test_Revert_NativeConnector_ApplyState_NonBridge() public {
        NativeConnector taraBridgeToken =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));
        vm.expectRevert(abi.encodeWithSelector(NotBridge.selector, address(this)));
        taraBridgeToken.applyState(abi.encode(1));
        vm.expectRevert(abi.encodeWithSelector(NotBridge.selector, address(this)));
        taraBridgeToken.finalize(1);
    }

    function test_Revert_MintingConnector_ApplyState_NonBridge() public {
        ERC20MintingConnector nativeMintingConnector =
            ERC20MintingConnector(payable(address(ethBridge.connectors(address(taraTokenOnEth)))));
        vm.expectRevert(abi.encodeWithSelector(NotBridge.selector, address(this)));
        nativeMintingConnector.applyState(abi.encode(1));
        vm.expectRevert(abi.encodeWithSelector(NotBridge.selector, address(this)));
        nativeMintingConnector.finalize(1);
    }

    function test_Revert_LockingConnector_ApplyState_NonBridge() public {
        (TestERC20 erc20onTara, ) = registerCustomTokenPair();
        ERC20LockingConnector nativeLockingConnector =
            ERC20LockingConnector(payable(address(taraBridge.connectors(address(erc20onTara)))));
        vm.expectRevert(abi.encodeWithSelector(NotBridge.selector, address(this)));
        nativeLockingConnector.applyState(abi.encode(1));
        vm.expectRevert(abi.encodeWithSelector(NotBridge.selector, address(this)));
        nativeLockingConnector.finalize(1);

         address relayer = vm.addr(666);
        vm.deal(relayer, 1 ether);

        vm.roll(FINALIZATION_INTERVAL);
        vm.txGasPrice(1000);
        uint256 value = 1 ether;
        NativeConnector taraBridgeToken =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));

        uint256 settlementFee = taraBridge.settlementFee();
        vm.deal(address(this), 2* value + settlementFee);
        taraBridgeToken.lock{value: value + settlementFee}(value);

        ERC20LockingConnector erc20onTaraConnector = ERC20LockingConnector(payable(address(taraBridge.connectors(address(erc20onTara)))));
        vm.deal(caller,  2* value + settlementFee);
        uint256 balance = erc20onTara.balanceOf(caller);
        vm.assertTrue(balance >= value, "Balance should be greater than value");
        vm.prank(caller);
        erc20onTaraConnector.lock{value: settlementFee}(value);

        // We're consciously setting the balance of the taraBridgeToken to 0 to simulate a malicious actor
        vm.deal(address(taraBridgeToken), 0 ether);

        IBridgeConnector br = taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS);
        vm.assertNotEq(address(br), address(0), "Bridge connector should not be 0");

        vm.txGasPrice(20 gwei);
        vm.prank(relayer);
        taraBridge.finalizeEpoch();

        IBridgeConnector br2 = taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS);
        vm.assertEq(address(br2), address(0), "Bridge connector should be 0");
    }


    function test_Plain_toEth() public {
        uint256 settlementFee = taraBridge.settlementFee();

        uint256 value = 1 ether;
        NativeConnector taraBridgeToken =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));
        taraBridgeToken.lock{value: value + settlementFee}(value);

        vm.roll(FINALIZATION_INTERVAL);

        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        taraLightClient.setBridgeRoot(state);
        ethBridge.applyState(state);

        assertEq(taraTokenOnEth.balanceOf(address(this)), value);
    }

}

