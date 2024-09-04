// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {NativeConnector} from "src/connectors/NativeConnector.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {SymmetricTestSetup} from "./SymmetricTestSetup.t.sol";
import "forge-std/console.sol";
import {TestERC20} from "../src/lib/TestERC20.sol";
import {ERC20LockingConnector} from "../src/connectors/ERC20LockingConnector.sol";
import {ERC20MintingConnector} from "../src/connectors/ERC20MintingConnector.sol";
import {Constants} from "../src/lib/Constants.sol";

contract ConnectorRegistrationTest is SymmetricTestSetup {
    function test_revertOnDuplicateConnectorRegistration() public {
        vm.startPrank(caller);
        address ethConnectorProxy = Upgrades.deployUUPSProxy(
            "NativeConnector.sol", abi.encodeCall(NativeConnector.initialize, (ethBridge, address(ethTokenOnTara)))
        );
        NativeConnector ethConnector2 = NativeConnector(payable(ethConnectorProxy));
        vm.deal(caller, REGISTRATION_FEE_ETH);
        vm.expectRevert();
        ethBridge.registerConnector{value: REGISTRATION_FEE_ETH}(ethConnector2);
        vm.stopPrank();
    }

    function test_syncEpochOnRegistration() public returns (TestERC20 taraTestToken, TestERC20 ethTestToken) {
        // deploy and register token on both sides
        console.log("finalized epoch", taraBridge.finalizedEpoch());

        uint256 value = 1 ether;
        uint256 settlementFee = taraBridge.settlementFee();
        NativeConnector taraBridgeToken =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));
        taraBridgeToken.lock{value: value + settlementFee}(value);
        uint256 currentBlock = block.number + FINALIZATION_INTERVAL;
        vm.roll(currentBlock);
        taraBridge.finalizeEpoch();

        taraBridgeToken.lock{value: value + settlementFee}(value);
        currentBlock += FINALIZATION_INTERVAL;
        vm.roll(currentBlock);
        taraBridge.finalizeEpoch();
        ethTestToken = new TestERC20("Test", "TEST");
        taraTestToken = new TestERC20("Test", "TEST");
        address taraTestTokenConnectorProxy = Upgrades.deployUUPSProxy(
            "ERC20LockingConnector.sol",
            abi.encodeWithSelector(
                ERC20LockingConnector.initialize.selector, address(taraBridge), taraTestToken, address(ethTestToken)
            )
        );
        ERC20LockingConnector taraTestTokenConnector = ERC20LockingConnector(payable(taraTestTokenConnectorProxy));

        taraTestToken.mintTo(address(caller), 10 ether);
        // give ownership of erc20s to the connectors
        taraTestToken.transferOwnership(address(taraTestTokenConnector));

        vm.startPrank(caller);
        vm.deal(address(caller), REGISTRATION_FEE_TARA);
        taraBridge.registerConnector{value: REGISTRATION_FEE_TARA}(taraTestTokenConnector);
        // not equal right after the registration
        vm.assertNotEq(taraBridge.finalizedEpoch(), taraTestTokenConnector.epoch());

        taraTestToken.approve(address(taraTestTokenConnector), 1 ether);
        vm.deal(address(caller), settlementFee);
        taraTestTokenConnector.lock{value: settlementFee}(1 ether);

        currentBlock += FINALIZATION_INTERVAL;
        vm.roll(currentBlock);
        taraBridge.finalizeEpoch();
        // should sync after the first finalization
        vm.assertEq(taraBridge.finalizedEpoch(), taraTestTokenConnector.epoch());

        taraTestToken.approve(address(taraTestTokenConnector), 1 ether);
        vm.deal(address(caller), settlementFee);
        taraTestTokenConnector.lock{value: settlementFee}(1 ether);
        currentBlock += FINALIZATION_INTERVAL;
        vm.roll(currentBlock);
        taraBridge.finalizeEpoch();
        vm.stopPrank();
    }
}
