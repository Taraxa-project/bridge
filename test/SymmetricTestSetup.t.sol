// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import {TaraBridge} from "src/tara/TaraBridge.sol";
import {NativeConnector} from "src/connectors/NativeConnector.sol";
import {EthBridge} from "src/eth/EthBridge.sol";
import {TestERC20} from "src/lib/TestERC20.sol";
import {ERC20LockingConnector} from "src/connectors/ERC20LockingConnector.sol";
import {ERC20MintingConnector} from "src/connectors/ERC20MintingConnector.sol";
import {Constants} from "src/lib/Constants.sol";
import {BridgeLightClientMock} from "./BridgeLightClientMock.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract SymmetricTestSetup is Test {
    BridgeLightClientMock taraLightClient;
    BridgeLightClientMock ethLightClient;
    TestERC20 taraTokenOnEth;
    TestERC20 ethTokenOnTara;
    TaraBridge taraBridge;
    EthBridge ethBridge;

    address caller = vm.addr(0x1234);
    uint256 constant FINALIZATION_INTERVAL = 100;
    uint256 constant FEE_MULTIPLIER_ETH = 101;
    uint256 constant FEE_MULTIPLIER_TARA = 109;
    uint256 constant REGISTRATION_FEE_ETH = 2 ether;
    uint256 constant REGISTRATION_FEE_TARA = 950432 ether;
    uint256 constant SETTLEMENT_FEE_ETH = 500 gwei;
    uint256 constant SETTLEMENT_FEE_TARA = 50000 ether;

    function setUp() public {
        payable(caller).transfer(100 ether);
        vm.startPrank(caller);
        taraLightClient = new BridgeLightClientMock();
        ethLightClient = new BridgeLightClientMock();

        taraTokenOnEth = new TestERC20("Tara", "TARA");
        ethTokenOnTara = new TestERC20("Eth", "ETH");

        address taraBridgeProxy = Upgrades.deployUUPSProxy(
            "TaraBridge.sol",
            abi.encodeCall(
                TaraBridge.initialize,
                (ethLightClient, FINALIZATION_INTERVAL, FEE_MULTIPLIER_TARA, REGISTRATION_FEE_TARA, SETTLEMENT_FEE_TARA)
            )
        );
        taraBridge = TaraBridge(taraBridgeProxy);
        address ethBridgeProxy = Upgrades.deployUUPSProxy(
            "EthBridge.sol",
            abi.encodeCall(
                EthBridge.initialize,
                (taraLightClient, FINALIZATION_INTERVAL, FEE_MULTIPLIER_ETH, REGISTRATION_FEE_ETH, SETTLEMENT_FEE_ETH)
            )
        );
        ethBridge = EthBridge(ethBridgeProxy);

        // Set Up TARA side of the bridge
        address taraConnectorProxy = Upgrades.deployUUPSProxy(
            "NativeConnector.sol", abi.encodeCall(NativeConnector.initialize, (taraBridge, address(taraTokenOnEth)))
        );
        NativeConnector taraConnector = NativeConnector(payable(taraConnectorProxy));

        // give ownership to the bridge
        taraConnector.transferOwnership(address(taraBridge));

        vm.deal(caller, REGISTRATION_FEE_TARA);
        taraBridge.registerContract(taraConnector);

        address ethOnTaraMintingConnectorProxy = Upgrades.deployUUPSProxy(
            "ERC20MintingConnector.sol",
            abi.encodeCall(
                ERC20MintingConnector.initialize, (taraBridge, ethTokenOnTara, Constants.NATIVE_TOKEN_ADDRESS)
            )
        );
        ERC20MintingConnector ethOnTaraMintingConnector = ERC20MintingConnector(payable(ethOnTaraMintingConnectorProxy));

        // give ownership to the bridge
        ethOnTaraMintingConnector.transferOwnership(address(taraBridge));

        // give ownership ot erc20 to the connector
        ethTokenOnTara.transferOwnership(address(ethOnTaraMintingConnector));

        vm.deal(caller, REGISTRATION_FEE_TARA);
        taraBridge.registerContract(ethOnTaraMintingConnector);

        // Set Up ETH side of the bridge
        address ethConnectorProxy = Upgrades.deployUUPSProxy(
            "NativeConnector.sol", abi.encodeCall(NativeConnector.initialize, (ethBridge, address(ethTokenOnTara)))
        );
        NativeConnector ethConnector = NativeConnector(payable(ethConnectorProxy));

        // give ownership to the bridge
        ethConnector.transferOwnership(address(ethBridge));

        vm.deal(caller, REGISTRATION_FEE_ETH);
        ethBridge.registerContract(ethConnector);

        address taraOnEthMintingConnectorProxy = Upgrades.deployUUPSProxy(
            "ERC20MintingConnector.sol",
            abi.encodeCall(
                ERC20MintingConnector.initialize, (ethBridge, taraTokenOnEth, Constants.NATIVE_TOKEN_ADDRESS)
            )
        );
        ERC20MintingConnector taraOnEthMintingConnector = ERC20MintingConnector(payable(taraOnEthMintingConnectorProxy));

        // give ownership to the bridge
        taraOnEthMintingConnector.transferOwnership(address(ethBridge));

        // give token ownership ot erc20 to the connector
        taraTokenOnEth.transferOwnership(address(taraOnEthMintingConnector));

        vm.deal(caller, REGISTRATION_FEE_ETH);
        ethBridge.registerContract(taraOnEthMintingConnector);

        vm.stopPrank();
    }

    // define it to not fail on incoming transfers
    receive() external payable {}

    function test_revertOnDuplicateConnectorRegistration() public {
        vm.startPrank(caller);
        address ethConnectorProxy = Upgrades.deployUUPSProxy(
            "NativeConnector.sol", abi.encodeCall(NativeConnector.initialize, (ethBridge, address(ethTokenOnTara)))
        );
        NativeConnector ethConnector = NativeConnector(payable(ethConnectorProxy));

        // give ownership to the bridge
        ethConnector.transferOwnership(address(ethBridge));

        vm.deal(caller, REGISTRATION_FEE_ETH);

        vm.expectRevert();
        ethBridge.registerContract(ethConnector);
        vm.stopPrank();
    }
}
