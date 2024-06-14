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
import {BridgeLightClientMock} from "./LightClientMocks.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {SharedStructs} from "src/lib/SharedStructs.sol";

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

    uint32 transfers = 100;

    function setUp() public {
        payable(caller).transfer(100 ether);
        vm.startPrank(caller);
        taraLightClient = new BridgeLightClientMock();
        ethLightClient = new BridgeLightClientMock();

        taraTokenOnEth = new TestERC20("Tara", "TARA");
        ethTokenOnTara = new TestERC20("Eth", "ETH");
        ethTokenOnTara.mintTo(address(caller), 1 ether);

        for (uint16 i = 1; i < transfers; i++) {
            address target = vm.addr(i);
            ethTokenOnTara.mintTo(target, 1 ether);
        }

        address taraBridgeProxy = Upgrades.deployUUPSProxy(
            "TaraBridge.sol", abi.encodeCall(TaraBridge.initialize, (ethLightClient, FINALIZATION_INTERVAL))
        );
        taraBridge = TaraBridge(taraBridgeProxy);
        address ethBridgeProxy = Upgrades.deployUUPSProxy(
            "EthBridge.sol", abi.encodeCall(EthBridge.initialize, (taraLightClient, FINALIZATION_INTERVAL))
        );
        ethBridge = EthBridge(ethBridgeProxy);

        // Set Up TARA side of the bridge
        address taraConnectorProxy = Upgrades.deployUUPSProxy(
            "NativeConnector.sol",
            abi.encodeCall(NativeConnector.initialize, (address(taraBridge), address(taraTokenOnEth)))
        );
        taraConnector = NativeConnector(payable(taraConnectorProxy));

        (bool success,) = payable(taraConnector).call{value: Constants.MINIMUM_CONNECTOR_DEPOSIT}("");
        if (!success) {
            revert("Failed to initialize tara native connector");
        }

        taraBridge.registerContract(taraConnector);

        address ethOnTaraMintingConnectorProxy = Upgrades.deployUUPSProxy(
            "ERC20MintingConnector.sol",
            abi.encodeCall(
                ERC20MintingConnector.initialize, (address(taraBridge), ethTokenOnTara, Constants.NATIVE_TOKEN_ADDRESS)
            )
        );
        ethOnTaraMintingConnector = ERC20MintingConnector(payable(ethOnTaraMintingConnectorProxy));

        (bool success2,) = payable(ethOnTaraMintingConnector).call{value: Constants.MINIMUM_CONNECTOR_DEPOSIT}("");
        if (!success2) {
            revert("Failed to initialize tara minting connector");
        }

        // give ownership ot erc20 to the connector
        ethTokenOnTara.transferOwnership(address(ethOnTaraMintingConnector));

        taraBridge.registerContract(ethOnTaraMintingConnector);

        // Set Up ETH side of the bridge

        address ethConnectorProxy = Upgrades.deployUUPSProxy(
            "NativeConnector.sol",
            abi.encodeCall(NativeConnector.initialize, (address(ethBridge), address(ethTokenOnTara)))
        );
        ethConnector = NativeConnector(payable(ethConnectorProxy));

        (bool success3,) = payable(ethConnector).call{value: Constants.MINIMUM_CONNECTOR_DEPOSIT}("");
        if (!success3) {
            revert("Failed to initialize eth connector");
        }

        ethBridge.registerContract(ethConnector);

        address taraOnEthMintingConnectorProxy = Upgrades.deployUUPSProxy(
            "ERC20MintingConnector.sol",
            abi.encodeCall(
                ERC20MintingConnector.initialize, (address(ethBridge), taraTokenOnEth, Constants.NATIVE_TOKEN_ADDRESS)
            )
        );
        taraOnEthMintingConnector = ERC20MintingConnector(payable(taraOnEthMintingConnectorProxy));

        (bool success4,) = payable(taraOnEthMintingConnector).call{value: Constants.MINIMUM_CONNECTOR_DEPOSIT}("");
        if (!success4) {
            revert("Failed to initialize minting connector");
        }

        // give ownership ot erc20 to the connector
        taraTokenOnEth.transferOwnership(address(taraOnEthMintingConnector));

        ethBridge.registerContract(taraOnEthMintingConnector);

        vm.stopPrank();
    }

    // define it to not fail on incoming transfers
    receive() external payable {}
}
