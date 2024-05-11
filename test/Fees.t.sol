// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import "src/tara/TaraBridge.sol";
import "src/connectors/NativeConnector.sol";
import "src/eth/EthBridge.sol";
import "src/lib/TestERC20.sol";
import "src/connectors/ERC20LockingConnector.sol";
import "src/connectors/ERC20MintingConnector.sol";
import "./BridgeLightClientMock.sol";
import "src/lib/Constants.sol";
import "./SymmetricTestSetup.t.sol";

contract FeesTest is SymmetricTestSetup {
    function test_toEthFees() public {
        vm.roll(FINALIZATION_INTERVAL);
        vm.txGasPrice(1000);
        uint256 value = 1 ether;
        NativeConnector taraBridgeToken =
            NativeConnector(payable(address(taraBridge.connectors(Constants.NATIVE_TOKEN_ADDRESS))));
        taraBridgeToken.lock{value: value}();

        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        taraLightClient.setBridgeRoot(state);
        ethBridge.applyState(state);

        ERC20MintingConnector ethTaraTokenConnector =
            ERC20MintingConnector(payable(address(ethBridge.connectors(address(taraTokenOnEth)))));
        ethTaraTokenConnector.claim{value: ethTaraTokenConnector.feeToClaim(address(this))}();
        assertEq(taraTokenOnEth.balanceOf(address(this)), value);
    }
}
