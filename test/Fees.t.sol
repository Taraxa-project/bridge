// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import "../src/tara/TaraBridge.sol";
import "../src/tara/TaraConnector.sol";
import "../src/eth/EthBridge.sol";
import "../src/lib/TestERC20.sol";
import "../src/connectors/ERC20LockingConnector.sol";
import "../src/connectors/ERC20MintingConnector.sol";
import "./BridgeLightClientMock.sol";
import "../src/lib/Constants.sol";

contract FeesTest is Test {
    BridgeLightClientMock taraLightClient;
    BridgeLightClientMock ethLightClient;
    TestERC20 ethTaraToken;
    TaraBridge taraBridge;
    EthBridge ethBridge;

    address caller = vm.addr(0x1234);
    uint256 constant FINALIZATION_INTERVAL = 100;

    function setUp() public {
        payable(caller).transfer(100 ether);
        taraLightClient = new BridgeLightClientMock();
        ethLightClient = new BridgeLightClientMock();
        ethTaraToken = new TestERC20("TARA");
        taraBridge = new TaraBridge{value: 2 ether}(address(ethTaraToken), ethLightClient, FINALIZATION_INTERVAL);
        ethBridge = new EthBridge{value: 2 ether}(
            IERC20MintableBurnable(address(ethTaraToken)), taraLightClient, FINALIZATION_INTERVAL
        );
    }

    // define it to not fail on incoming transfers
    receive() external payable {}

    function test_toEthFees() public {
        vm.roll(FINALIZATION_INTERVAL);
        vm.txGasPrice(1000);
        uint256 value = 1 ether;
        TaraConnector taraBridgeToken = TaraConnector(address(taraBridge.connectors(Constants.TARA_PLACEHOLDER)));
        taraBridgeToken.lock{value: value}();

        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        taraLightClient.setBridgeRoot(state);
        ethBridge.applyState(state);

        ERC20MintingConnector ethTaraTokenConnector =
            ERC20MintingConnector(address(ethBridge.connectors(address(ethTaraToken))));
        ethTaraTokenConnector.claim{value: ethTaraTokenConnector.feeToClaim(address(this))}();
        assertEq(ethTaraToken.balanceOf(address(this)), value);
    }
}
