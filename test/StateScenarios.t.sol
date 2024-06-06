// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {SymmetricTestSetup} from "./SymmetricTestSetup.t.sol";
import {TestERC20} from "../src/lib/TestERC20.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {ERC20LockingConnectorMock} from "./baseContracts/ERC20LockingConnectorMock.sol";
import {ERC20MintingConnectorMock} from "./baseContracts/ERC20MintingConnectorMock.sol";
import {Constants} from "../src/lib/Constants.sol";
import {SharedStructs} from "../src/lib/SharedStructs.sol";
import "forge-std/console.sol";

contract StateScenarios is Test, SymmetricTestSetup {
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

            ERC20LockingConnectorMock taraTestTokenConnector = new ERC20LockingConnectorMock{
                value: 2 * Constants.MINIMUM_CONNECTOR_DEPOSIT
            }(address(taraBridge), erc20onTara, address(erc20onEth));
            ERC20MintingConnectorMock ethTestTokenConnector = new ERC20MintingConnectorMock{
                value: 2 * Constants.MINIMUM_CONNECTOR_DEPOSIT
            }(address(ethBridge), erc20onEth, address(erc20onTara));

            taraBridge.registerContract(taraTestTokenConnector);
            ethBridge.registerContract(ethTestTokenConnector);

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
        if (amount == 0 || amount > 10000) {
            return;
        }
        setUpTokens(amount);
        vm.deal(caller, 1000 ether);
        vm.startPrank(caller);
        for (uint32 i = 0; i < amount; i++) {
            TestERC20 erc20onTara = new TestERC20("TaraERC20", "TTARA");
            TestERC20 erc20onEth = new TestERC20("EthERC20", "TETH");

            ERC20LockingConnectorMock taraTestTokenConnector = new ERC20LockingConnectorMock{
                value: 2 * Constants.MINIMUM_CONNECTOR_DEPOSIT
            }(address(taraBridge), erc20onTara, address(erc20onEth));
            ERC20MintingConnectorMock ethTestTokenConnector = new ERC20MintingConnectorMock{
                value: 2 * Constants.MINIMUM_CONNECTOR_DEPOSIT
            }(address(ethBridge), erc20onEth, address(erc20onTara));

            taraBridge.registerContract(taraTestTokenConnector);
            ethBridge.registerContract(ethTestTokenConnector);

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

        for (uint32 i = 0; i < erc20ConnectorsOnTara.length; i++) {
            erc20ConnectorsOnTara[i].lock(1 ether);
            assertEq(
                erc20sonTara[i].balanceOf(address(erc20ConnectorsOnTara[i])),
                1 ether,
                "connector should have 1 ether of TTARA"
            );
        }

        vm.roll(FINALIZATION_INTERVAL);
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        assertEq(state.state.epoch, 1, "epoch should be 1");
        taraLightClient.setBridgeRoot(state);
        ethBridge.applyState(state);
        for (uint32 i = 0; i < erc20ConnectorsOnEth.length; i++) {
            uint256 balanceOfCallerBeforeClaim = erc20sonEth[i].balanceOf(caller);
            erc20ConnectorsOnEth[i].claim{value: erc20ConnectorsOnEth[i].feeToClaim(address(caller))}();
            assertEq(
                erc20sonEth[i].balanceOf(address(erc20ConnectorsOnEth[i])),
                0 ether,
                "connector should have 0 ether of TTARA"
            );
            assertEq(
                erc20sonEth[i].balanceOf(caller),
                balanceOfCallerBeforeClaim + 1 ether,
                "caller should have received 1 ether worth of TTARA on ETH"
            );
        }

        vm.stopPrank();
    }

    function testFuzz_testTransferThresholds(uint32 tokenTransfersForEach) public {
        if (tokenTransfersForEach == 0 || tokenTransfersForEach > 100) {
            return;
        }
        setUpTokens(10);

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
                vm.prank(target);
                erc20ConnectorsOnTara[i].lock(1 ether);
            }
        }

        vm.roll(FINALIZATION_INTERVAL);
        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state1 = taraBridge.getStateWithProof();
        assertEq(state1.state.epoch, 1, "epoch should be 1");
        taraLightClient.setBridgeRoot(state1);
        ethBridge.applyState(state1);
        for (uint32 i = 0; i < erc20ConnectorsOnEth.length; i++) {
            for (uint32 j = 1; j <= tokenTransfersForEach; j++) {
                address target = vm.addr(j);

                uint256 balanceOfTargetBeforeClaim = erc20sonEth[i].balanceOf(target);
                uint256 fee = erc20ConnectorsOnEth[i].feeToClaim(address(target));
                vm.prank(target);
                erc20ConnectorsOnEth[i].claim{value: fee}();
                assertEq(
                    erc20sonEth[i].balanceOf(address(erc20ConnectorsOnEth[i])),
                    0 ether,
                    "connector should have 0 ether of TTARA"
                );
                assertEq(
                    erc20sonEth[i].balanceOf(target),
                    balanceOfTargetBeforeClaim + 1 ether,
                    "caller should have received 1 ether worth of TTARA on ETH"
                );
            }
        }

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
                vm.prank(target);
                erc20ConnectorsOnEth[i].burn(1 ether);
            }
        }

        vm.roll(FINALIZATION_INTERVAL * 2);
        ethBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = ethBridge.getStateWithProof();
        assertEq(state.state.epoch, 1, "epoch should be 1");
        ethLightClient.setBridgeRoot(state);
        taraBridge.applyState(state);

        for (uint32 i = 0; i < erc20ConnectorsOnTara.length; i++) {
            for (uint32 j = 1; j <= tokenTransfersForEach; j++) {
                address target = vm.addr(j);
                vm.prank(target);
                uint256 fee = erc20ConnectorsOnTara[i].feeToClaim(address(target));
                vm.prank(target);
                erc20ConnectorsOnTara[i].claim{value: fee}();
            }
        }
    }
}
