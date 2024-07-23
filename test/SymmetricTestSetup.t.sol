// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {TaraBridge} from "src/tara/TaraBridge.sol";
import {NativeConnector} from "src/connectors/NativeConnector.sol";
import {EthBridge} from "src/eth/EthBridge.sol";
import {TestERC20} from "src/lib/TestERC20.sol";
import {ERC20LockingConnector} from "src/connectors/ERC20LockingConnector.sol";
import {ERC20MintingConnector} from "src/connectors/ERC20MintingConnector.sol";
import {Constants} from "src/lib/Constants.sol";
import {BridgeLightClientMock} from "./utils/LightClientMocks.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract SymmetricTestSetup is Test {
    BridgeLightClientMock taraLightClient;
    BridgeLightClientMock ethLightClient;
    ERC20MintingConnector ethOnTaraMintingConnector;
    ERC20MintingConnector taraOnEthMintingConnector;
    NativeConnector taraConnector;
    NativeConnector ethConnector;
    TestERC20 taraTokenOnEth;
    TestERC20 ethTokenOnTara;
    TaraBridge taraBridge;
    EthBridge ethBridge;

    address caller = vm.addr(0x1234);
    uint256 constant FINALIZATION_INTERVAL = 100;
    uint256 constant FEE_MULTIPLIER_ETH_FINALIZE = 110;
    uint256 constant FEE_MULTIPLIER_ETH_APPLY = 210;
    uint256 constant FEE_MULTIPLIER_TARA_FINALIZE = 110;
    uint256 constant FEE_MULTIPLIER_TARA_APPLY = 210;
    uint256 constant REGISTRATION_FEE_ETH = 2 ether;
    uint256 constant REGISTRATION_FEE_TARA = 950432 ether;
    uint256 constant SETTLEMENT_FEE_ETH = 500 gwei;
    uint256 constant SETTLEMENT_FEE_TARA = 50000 ether;

    uint32 transfers = 100;

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
                (
                    ethLightClient,
                    FINALIZATION_INTERVAL,
                    FEE_MULTIPLIER_TARA_FINALIZE,
                    FEE_MULTIPLIER_TARA_APPLY,
                    REGISTRATION_FEE_TARA,
                    SETTLEMENT_FEE_TARA
                )
            )
        );
        taraBridge = TaraBridge(payable(taraBridgeProxy));
        address ethBridgeProxy = Upgrades.deployUUPSProxy(
            "EthBridge.sol",
            abi.encodeCall(
                EthBridge.initialize,
                (
                    taraLightClient,
                    FINALIZATION_INTERVAL,
                    FEE_MULTIPLIER_ETH_FINALIZE,
                    FEE_MULTIPLIER_ETH_APPLY,
                    REGISTRATION_FEE_ETH,
                    SETTLEMENT_FEE_ETH
                )
            )
        );
        ethBridge = EthBridge(payable(ethBridgeProxy));

        // Set Up TARA side of the bridge
        address taraConnectorProxy = Upgrades.deployUUPSProxy(
            "NativeConnector.sol", abi.encodeCall(NativeConnector.initialize, (taraBridge, address(taraTokenOnEth)))
        );
        taraConnector = NativeConnector(payable(taraConnectorProxy));

        vm.deal(caller, REGISTRATION_FEE_TARA);
        taraBridge.registerContract{value: REGISTRATION_FEE_TARA}(taraConnector);

        address ethOnTaraMintingConnectorProxy = Upgrades.deployUUPSProxy(
            "ERC20MintingConnector.sol",
            abi.encodeCall(
                ERC20MintingConnector.initialize, (taraBridge, ethTokenOnTara, Constants.NATIVE_TOKEN_ADDRESS)
            )
        );
        ethOnTaraMintingConnector = ERC20MintingConnector(payable(ethOnTaraMintingConnectorProxy));

        // give ownership of erc20 to the connector
        ethTokenOnTara.transferOwnership(address(ethOnTaraMintingConnector));

        // ethOnTaraMintingConnector.transferOwnership(address(taraBridge));

        vm.deal(caller, address(caller).balance + REGISTRATION_FEE_TARA);
        taraBridge.registerContract{value: REGISTRATION_FEE_TARA}(ethOnTaraMintingConnector);

        // Set Up ETH side of the bridge
        address ethConnectorProxy = Upgrades.deployUUPSProxy(
            "NativeConnector.sol", abi.encodeCall(NativeConnector.initialize, (ethBridge, address(ethTokenOnTara)))
        );
        ethConnector = NativeConnector(payable(ethConnectorProxy));

        vm.deal(caller, address(caller).balance + REGISTRATION_FEE_ETH);
        ethBridge.registerContract{value: REGISTRATION_FEE_ETH}(ethConnector);

        address taraOnEthMintingConnectorProxy = Upgrades.deployUUPSProxy(
            "ERC20MintingConnector.sol",
            abi.encodeCall(
                ERC20MintingConnector.initialize, (ethBridge, taraTokenOnEth, Constants.NATIVE_TOKEN_ADDRESS)
            )
        );
        taraOnEthMintingConnector = ERC20MintingConnector(payable(taraOnEthMintingConnectorProxy));

        // give token ownership ot erc20 to the connector
        taraTokenOnEth.transferOwnership(address(taraOnEthMintingConnector));

        // taraOnEthMintingConnector.transferOwnership(address(ethBridge));

        vm.deal(caller, address(caller).balance + REGISTRATION_FEE_ETH);
        ethBridge.registerContract{value: REGISTRATION_FEE_ETH}(taraOnEthMintingConnector);

        vm.stopPrank();
    }

    function registerCustomTokenPair() public returns (TestERC20 erc20onTara, TestERC20 erc20onEth) {
        vm.startPrank(caller);
        erc20onTara = new TestERC20("TestTara", "TARATEST");
        erc20onEth = new TestERC20("TestETH", "ETHTEST");
        address taraTestTokenConnectorProxy = Upgrades.deployUUPSProxy(
            "ERC20LockingConnector.sol",
            abi.encodeWithSelector(
                ERC20LockingConnector.initialize.selector, address(taraBridge), erc20onTara, address(erc20onEth)
            )
        );
        ERC20LockingConnector taraTestTokenConnector = ERC20LockingConnector(payable(taraTestTokenConnectorProxy));

        address ethTestTokenConnectorProxy = Upgrades.deployUUPSProxy(
            "ERC20MintingConnector.sol",
            abi.encodeWithSelector(
                ERC20MintingConnector.initialize.selector, address(ethBridge), erc20onEth, address(erc20onTara)
            )
        );
        ERC20MintingConnector ethTestTokenConnector = ERC20MintingConnector(payable(ethTestTokenConnectorProxy));

        erc20onTara.mintTo(address(caller), 200 ether);
        erc20onEth.mintTo(address(caller), 200 ether);
        erc20onTara.approve(address(taraTestTokenConnector), 1 ether);
        erc20onEth.approve(address(ethTestTokenConnector), 1 ether);
        // give ownership of erc20s to the connectors
        erc20onTara.transferOwnership(address(taraTestTokenConnector));
        erc20onEth.transferOwnership(address(ethTestTokenConnector));

        // taraTestTokenConnector.transferOwnership(address(taraBridge));
        // ethTestTokenConnector.transferOwnership(address(ethBridge));
        vm.deal(address(caller), REGISTRATION_FEE_TARA);
        taraBridge.registerContract{value: REGISTRATION_FEE_TARA}(taraTestTokenConnector);
        vm.deal(address(caller), REGISTRATION_FEE_ETH);
        ethBridge.registerContract{value: REGISTRATION_FEE_ETH}(ethTestTokenConnector);

        vm.stopPrank();
    }

    // define it to not fail on incoming transfers
    receive() external payable {}
}
