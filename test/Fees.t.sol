// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import {TaraBridge} from "src/tara/TaraBridge.sol";
import {NativeConnector} from "src/connectors/NativeConnector.sol";
import {EthBridge} from "src/eth/EthBridge.sol";
import {TestERC20} from "src/lib/TestERC20.sol";
import {ERC20LockingConnector} from "src/connectors/ERC20LockingConnector.sol";
import {ERC20MintingConnector} from "src/connectors/ERC20MintingConnector.sol";
import {BridgeLightClientMock} from "./LightClientMocks.sol";
import {Constants} from "src/lib/Constants.sol";
import {SharedStructs} from "src/lib/SharedStructs.sol";
import {SymmetricTestSetup} from "./SymmetricTestSetup.t.sol";

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
