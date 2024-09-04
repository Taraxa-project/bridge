// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {NativeConnector} from "src/connectors/NativeConnector.sol";
import {TestERC20} from "src/lib/TestERC20.sol";
import {ERC20LockingConnector} from "src/connectors/ERC20LockingConnector.sol";
import {Constants} from "src/lib/Constants.sol";
import {SharedStructs} from "src/lib/SharedStructs.sol";
import {SymmetricTestSetup} from "./SymmetricTestSetup.t.sol";
import {IBridgeConnector} from "src/connectors/IBridgeConnector.sol";
import {console} from "forge-std/console.sol";

contract FeesTest is SymmetricTestSetup {
    function test_delistRelayerOnInsufficientSettlementFees()
        public
        returns (TestERC20 erc20onTara, ERC20LockingConnector connector)
    {
        address relayer = vm.addr(666);
        vm.deal(relayer, 1 ether);
        TestERC20 erc20onEth;
        (erc20onTara, erc20onEth) = registerCustomTokenPair();

        vm.roll(FINALIZATION_INTERVAL);
        vm.txGasPrice(1000);
        uint256 value = 1 ether;
        NativeConnector taraNativeConnector =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));

        uint256 settlementFee = taraBridge.settlementFee();
        vm.deal(address(this), 2 * value + settlementFee);

        connector = ERC20LockingConnector(payable(address(taraBridge.connectors(address(erc20onTara)))));
        vm.deal(caller, 2 * value + settlementFee);
        uint256 balance = erc20onTara.balanceOf(caller);
        vm.assertTrue(balance >= value, "Balance should be greater than value");
        vm.prank(caller);
        connector.lock{value: settlementFee}(value);
        taraNativeConnector.lock{value: value + settlementFee}(value);

        // We're consciously setting the balance of the taraBridgeToken to 0 to simulate a malicious actor
        vm.deal(address(connector), 0 ether);
        vm.assertNotEq(address(connector), address(0), "Bridge connector should not be 0");
        vm.assertNotEq(taraBridge.localAddress(address(erc20onEth)), address(0), "Token address should  be 0");

        vm.txGasPrice(20 gwei);
        vm.prank(relayer);
        taraBridge.finalizeEpoch();

        IBridgeConnector br2 = taraBridge.connectors(address(erc20onTara));
        vm.assertEq(address(br2), address(0), "Bridge connector should be 0");
        vm.assertEq(taraBridge.localAddress(address(erc20onEth)), address(0), "Token address should be 0");
    }

    function test_registerAfterDelisting() public {
        console.log("before");
        (, IBridgeConnector connector) = test_delistRelayerOnInsufficientSettlementFees();
        console.log("after");
        vm.deal(address(caller), REGISTRATION_FEE_TARA);
        console.log("CONNECTOR", address(connector));

        vm.deal(address(caller), 2 * REGISTRATION_FEE_TARA);
        vm.prank(caller);
        taraBridge.registerConnector{value: REGISTRATION_FEE_TARA}(connector);
    }
}
