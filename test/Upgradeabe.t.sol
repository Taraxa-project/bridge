// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import "forge-std/Test.sol";
import "../src/tara/TaraBridge.sol";
import "../src/tara/TaraConnector.sol";
import "../src/eth/EthBridge.sol";
import "../src/lib/TestERC20.sol";
import {
    StateNotMatchingBridgeRoot, NotSuccessiveEpochs, NotEnoughBlocksPassed
} from "../src/errors/BridgeBaseErrors.sol";
import "../src/connectors/ERC20LockingConnector.sol";
import "../src/connectors/ERC20MintingConnector.sol";
import "./BridgeLightClientMock.sol";
import "../src/lib/Constants.sol";
import "./upgradeableMocks/EthBridgeV2.sol";
import "./upgradeableMocks/TaraBridgeV2.sol";

contract UpgradeabilityTest is Test {
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
        address taraTokenProxy =
            Upgrades.deployUUPSProxy("TestERC20.sol", abi.encodeCall(TestERC20.initialize, ("Tara", "TARA")));
        ethTaraToken = TestERC20(taraTokenProxy);

        address taraBridgeProxy = Upgrades.deployUUPSProxy(
            "TaraBridge.sol",
            abi.encodeCall(TaraBridge.initialize, (address(ethTaraToken), ethLightClient, FINALIZATION_INTERVAL))
        );
        taraBridge = TaraBridge(taraBridgeProxy);

        address ethBridgeProxy = Upgrades.deployUUPSProxy(
            "EthBridge.sol",
            abi.encodeCall(EthBridge.initialize, (ethTaraToken, taraLightClient, FINALIZATION_INTERVAL))
        );
        ethBridge = EthBridge(ethBridgeProxy);

        address taraConnectorProxy = Upgrades.deployUUPSProxy(
            "TaraConnector.sol", abi.encodeCall(TaraConnector.initialize, (address(taraBridge), address(ethTaraToken)))
        );
        (bool success,) = payable(taraConnectorProxy).call{value: 2 ether}("");
        if (!success) {
            revert("Failed to initialize tara connector");
        }

        address mintingConnectorProxy = Upgrades.deployUUPSProxy(
            "ERC20MintingConnector.sol",
            abi.encodeCall(ERC20MintingConnector.initialize, (address(ethBridge), ethTaraToken, address(ethTaraToken)))
        );

        (bool success2,) = payable(mintingConnectorProxy).call{value: 2 ether}("");
        if (!success2) {
            revert("Failed to initialize minting connector");
        }

        ethBridge.registerContract(ERC20MintingConnector(payable(mintingConnectorProxy)));
        taraBridge.registerContract(TaraConnector(payable(taraConnectorProxy)));
    }

    // define it to not fail on incoming transfers
    receive() external payable {}

    function test_toEth() public {
        uint256 value = 1 ether;
        TaraConnector taraBridgeToken =
            TaraConnector(payable(address(taraBridge.connectors(Constants.TARA_PLACEHOLDER))));
        taraBridgeToken.lock{value: value}();

        vm.roll(FINALIZATION_INTERVAL);

        taraBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = taraBridge.getStateWithProof();
        taraLightClient.setBridgeRoot(state);
        ethBridge.applyState(state);

        ERC20MintingConnector ethTaraTokenConnector =
            ERC20MintingConnector(payable(address(ethBridge.connectors(address(ethTaraToken)))));
        ethTaraTokenConnector.claim{value: ethTaraTokenConnector.feeToClaim(address(this))}();
        assertEq(ethTaraToken.balanceOf(address(this)), value);
    }

    function test_toTara() public {
        test_toEth();
        uint256 value = 1 ether;
        ERC20MintingConnector ethTaraConnector =
            ERC20MintingConnector(payable(address(ethBridge.connectors(address(ethTaraToken)))));
        ethTaraToken.approve(address(ethTaraConnector), value);
        ethTaraConnector.burn(value);

        vm.roll(FINALIZATION_INTERVAL);

        ethBridge.finalizeEpoch();
        SharedStructs.StateWithProof memory state = ethBridge.getStateWithProof();
        ethLightClient.setBridgeRoot(state);
        uint256 balance_before = address(this).balance;

        vm.prank(caller);
        taraBridge.applyState(state);

        TaraConnector taraConnector = TaraConnector(payable(address(taraBridge.connectors(Constants.TARA_PLACEHOLDER))));
        uint256 claim_fee = taraConnector.feeToClaim(address(this));
        taraConnector.claim{value: claim_fee}();
        assertEq(address(this).balance, balance_before + value - claim_fee);
    }

    function test_upgrade_ethBridge() public {
        Options memory opts;
        opts.referenceContract = "EthBridge.sol";

        uint256 newFinalizationInterval = 6666;
        vm.prank(caller);
        Upgrades.upgradeProxy(
            address(ethBridge), "EthBridgeV2.sol", (abi.encodeCall(EthBridgeV2.reinitialize, newFinalizationInterval))
        );

        EthBridgeV2 upgradedBridge = EthBridgeV2(address(ethBridge));
        assertEq(upgradedBridge.getNewStorageValue(), newFinalizationInterval);
    }

    function test_upgrade_taraBridge() public {
        Options memory opts;
        opts.referenceContract = "TaraBridge.sol";

        uint256 newFinalizationInterval = 6666;
        vm.prank(caller);
        Upgrades.upgradeProxy(
            address(taraBridge),
            "TaraBridgeV2.sol",
            (abi.encodeCall(TaraBridgeV2.reinitialize, newFinalizationInterval))
        );

        TaraBridgeV2 upgradedBridge = TaraBridgeV2(address(taraBridge));
        assertEq(upgradedBridge.getNewStorageValue(), newFinalizationInterval);
    }
}
