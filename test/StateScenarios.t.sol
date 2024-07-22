// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {SymmetricTestSetup} from "./SymmetricTestSetup.t.sol";
import {TestERC20} from "../src/lib/TestERC20.sol";
import {ERC20LockingConnectorMock} from "./baseContracts/ERC20LockingConnectorMock.sol";
import {ERC20MintingConnectorMock} from "./baseContracts/ERC20MintingConnectorMock.sol";
import {SharedStructs} from "../src/lib/SharedStructs.sol";
import "forge-std/console.sol";

contract StateScenarios is SymmetricTestSetup {
    TestERC20[] erc20sonTara;
    TestERC20[] erc20sonEth;
    ERC20LockingConnectorMock[] erc20ConnectorsOnTara;
    ERC20MintingConnectorMock[] erc20ConnectorsOnEth;

    function setUpTokens(uint256 amount) private {
        if (amount == 0 || amount > 10000) {
            return;
        }
        vm.deal(caller, 1000 ether);
        vm.startPrank(caller);
        for (uint32 i = 0; i < amount; i++) {
            TestERC20 erc20onTara = new TestERC20("TaraERC20", "TTARA");
            TestERC20 erc20onEth = new TestERC20("EthERC20", "TETH");

            ERC20LockingConnectorMock taraTestTokenConnector =
                new ERC20LockingConnectorMock(taraBridge, erc20onTara, address(erc20onEth));
            ERC20MintingConnectorMock ethTestTokenConnector =
                new ERC20MintingConnectorMock(ethBridge, erc20onEth, address(erc20onTara));

            vm.deal(caller, REGISTRATION_FEE_TARA);
            taraBridge.registerConnector{value: REGISTRATION_FEE_TARA}(taraTestTokenConnector);
            vm.deal(caller, REGISTRATION_FEE_ETH);
            ethBridge.registerConnector{value: REGISTRATION_FEE_ETH}(ethTestTokenConnector);

            // give 1000000 tokens to caller every time
            erc20onTara.mintTo(address(caller), 1000000 ether);
            erc20onEth.mintTo(address(caller), 1000000 ether);
            erc20onTara.approve(address(taraTestTokenConnector), 1000000 ether);
            erc20onEth.approve(address(ethTestTokenConnector), 1000000 ether);
            // give ownership of erc20s to the connectors
            erc20onTara.transferOwnership(address(taraTestTokenConnector));
            erc20onEth.transferOwnership(address(ethTestTokenConnector));

            erc20sonTara.push(erc20onTara);
            erc20sonEth.push(erc20onEth);
            erc20ConnectorsOnTara.push(taraTestTokenConnector);
            erc20ConnectorsOnEth.push(ethTestTokenConnector);
        }
        vm.stopPrank();
    }

    function testFuzz_registerMoreTokens(uint32 amount) public {
        if (amount == 0 || amount > 100) {
            return;
        }
        setUpTokens(amount);
        vm.deal(caller, 1000 ether);
        vm.startPrank(caller);
        for (uint32 i = 0; i < amount; i++) {
            TestERC20 erc20onTara = new TestERC20("TaraERC20", "TTARA");
            TestERC20 erc20onEth = new TestERC20("EthERC20", "TETH");

            ERC20LockingConnectorMock taraTestTokenConnector =
                new ERC20LockingConnectorMock(taraBridge, erc20onTara, address(erc20onEth));

            ERC20MintingConnectorMock ethTestTokenConnector =
                new ERC20MintingConnectorMock(ethBridge, erc20onEth, address(erc20onTara));

            vm.deal(caller, REGISTRATION_FEE_TARA);
            taraBridge.registerConnector{value: REGISTRATION_FEE_TARA}(taraTestTokenConnector);
            vm.deal(caller, REGISTRATION_FEE_ETH);
            ethBridge.registerConnector{value: REGISTRATION_FEE_ETH}(ethTestTokenConnector);

            // give 1000 tokens to caller every time
            erc20onTara.mintTo(address(caller), 1000000 ether);
            erc20onEth.mintTo(address(caller), 1000000 ether);
            erc20onTara.approve(address(taraTestTokenConnector), 1000000 ether);
            erc20onEth.approve(address(ethTestTokenConnector), 1000000 ether);

            // give ownership of erc20s to the connectors
            erc20onTara.transferOwnership(address(taraTestTokenConnector));
            erc20onEth.transferOwnership(address(ethTestTokenConnector));

            erc20sonTara.push(erc20onTara);
            erc20sonEth.push(erc20onEth);
            erc20ConnectorsOnTara.push(taraTestTokenConnector);
            erc20ConnectorsOnEth.push(ethTestTokenConnector);
        }

        uint256 settlementFeeTara = taraBridge.settlementFee();

        for (uint32 i = 0; i < erc20ConnectorsOnTara.length; i++) {
            vm.deal(caller, settlementFeeTara);
            uint256 balanceOfConnectorBefore = address(erc20ConnectorsOnTara[i]).balance;
            erc20ConnectorsOnTara[i].lock{value: settlementFeeTara}(1 ether);
            assertEq(
                erc20sonTara[i].balanceOf(address(erc20ConnectorsOnTara[i])),
                1 ether,
                "connector should have 1 ether of TTARA"
            );
            assertEq(
                address(erc20ConnectorsOnTara[i]).balance - balanceOfConnectorBefore,
                settlementFeeTara,
                "connector should have received the settlement fee"
            );
        }

        vm.roll(FINALIZATION_INTERVAL);
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        assertEq(state.state.epoch, 1, "epoch should be 1");
        taraLightClient.setBridgeRoot(state);
        ethBridge.applyState(state);

        vm.stopPrank();
    }

    function testFuzz_testTransferThresholds(uint32 tokenTransfersForEach) public {
        if (tokenTransfersForEach == 0 || tokenTransfersForEach > 100) {
            return;
        }
        setUpTokens(10);
        uint256 settlementFeeTara = taraBridge.settlementFee();
        uint256 settlementFeeEth = ethBridge.settlementFee();
        for (uint32 i = 0; i < erc20ConnectorsOnTara.length; i++) {
            for (uint32 j = 1; j <= tokenTransfersForEach; j++) {
                address target = vm.addr(j);
                vm.prank(caller);
                erc20sonTara[i].transfer(target, 1 ether);
                vm.prank(target);
                erc20sonTara[i].approve(address(erc20ConnectorsOnTara[i]), 1 ether);
                assertTrue(erc20sonTara[i].balanceOf(target) >= 1 ether, "target should have at least 1 ether");
                assertTrue(
                    erc20sonTara[i].allowance(target, address(erc20ConnectorsOnTara[i])) >= 1 ether,
                    "target should have at least 1 ether allowance"
                );
                vm.deal(target, 1 ether + settlementFeeTara);
                vm.prank(target);
                erc20ConnectorsOnTara[i].lock{value: 1 ether + settlementFeeTara}(1 ether);
            }
        }

        vm.roll(FINALIZATION_INTERVAL);
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state1 = taraBridge.getStateWithProof();
        assertEq(state1.state.epoch, 1, "epoch should be 1");
        taraLightClient.setBridgeRoot(state1);
        ethBridge.applyState(state1);

        for (uint32 i = 0; i < erc20ConnectorsOnEth.length; i++) {
            console.log("i", i);
            console.log("balance", erc20sonEth[i].balanceOf(address(erc20ConnectorsOnEth[i])));
            for (uint32 j = 1; j <= tokenTransfersForEach; j++) {
                address target = vm.addr(j);
                vm.prank(caller);
                erc20sonEth[i].transfer(target, 1 ether);
                vm.prank(target);
                erc20sonEth[i].approve(address(erc20ConnectorsOnEth[i]), 1 ether);
                assertTrue(erc20sonEth[i].balanceOf(target) >= 1 ether, "target should have at least 1 ether");
                vm.deal(target, 1 ether + settlementFeeEth);
                vm.prank(target);
                erc20ConnectorsOnEth[i].burn{value: 1 ether + settlementFeeEth}(1 ether);
            }
        }

        vm.roll(FINALIZATION_INTERVAL * 2);
        ethBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = ethBridge.getStateWithProof();
        assertEq(state.state.epoch, 1, "epoch should be 1");
        ethLightClient.setBridgeRoot(state);
        taraBridge.applyState(state);
    }
}
