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
        ethTaraToken = new TestERC20();
        ethTaraToken.initialize("Tara", "TARA");
        taraBridge = new TaraBridge();
        taraBridge.initialize(address(ethTaraToken), ethLightClient, FINALIZATION_INTERVAL);
        ethBridge = new EthBridge();
        ethBridge.initialize(IERC20MintableBurnable(address(ethTaraToken)), taraLightClient, FINALIZATION_INTERVAL);

        TaraConnector taraConnector = new TaraConnector();
        taraConnector.initialize(address(taraBridge), address(ethTaraToken));
        (bool success,) = payable(taraConnector).call{value: 2 ether}("");
        if (!success) {
            revert("Failed to initialize tara connector");
        }
        ERC20MintingConnector mintingConnector = new ERC20MintingConnector();
        mintingConnector.initialize(address(ethBridge), ethTaraToken, address(ethTaraToken));

        (bool success2,) = payable(mintingConnector).call{value: 2 ether}("");
        if (!success2) {
            revert("Failed to initialize minting connector");
        }

        ethBridge.registerContract(mintingConnector);
        taraBridge.registerContract(taraConnector);
    }

    // define it to not fail on incoming transfers
    receive() external payable {}

    function test_toEthFees() public {
        vm.roll(FINALIZATION_INTERVAL);
        vm.txGasPrice(1000);
        uint256 value = 1 ether;
        TaraConnector taraBridgeToken =
            TaraConnector(payable(address(taraBridge.connectors(Constants.TARA_PLACEHOLDER))));
        taraBridgeToken.lock{value: value}();

        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        taraLightClient.setBridgeRoot(state);
        ethBridge.applyState(state);

        ERC20MintingConnector ethTaraTokenConnector =
            ERC20MintingConnector(payable(address(ethBridge.connectors(address(ethTaraToken)))));
        ethTaraTokenConnector.claim{value: ethTaraTokenConnector.feeToClaim(address(this))}();
        assertEq(ethTaraToken.balanceOf(address(this)), value);
    }
}
