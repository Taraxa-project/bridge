// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import "src/tara/TaraBridge.sol";
import "src/connectors/NativeConnector.sol";
import "src/eth/EthBridge.sol";
import "src/lib/TestERC20.sol";
import "src/connectors/ERC20LockingConnector.sol";
import "src/connectors/ERC20MintingConnector.sol";
import "src/lib/Constants.sol";
import "./BridgeLightClientMock.sol";

contract SymmetricTestSetup is Test {
    BridgeLightClientMock taraLightClient;
    BridgeLightClientMock ethLightClient;
    TestERC20 taraTokenOnEth;
    TestERC20 ethTokenOnTara;
    TaraBridge taraBridge;
    EthBridge ethBridge;

    address caller = vm.addr(0x1234);
    uint256 constant FINALIZATION_INTERVAL = 100;

    function setUp() public {
        payable(caller).transfer(100 ether);
        vm.startPrank(caller);
        taraLightClient = new BridgeLightClientMock();
        ethLightClient = new BridgeLightClientMock();
        taraTokenOnEth = new TestERC20();
        taraTokenOnEth.initialize("Tara", "TARA");
        ethTokenOnTara = new TestERC20();
        ethTokenOnTara.initialize("Eth", "ETH");
        taraBridge = new TaraBridge();
        taraBridge.initialize(taraTokenOnEth, ethLightClient, FINALIZATION_INTERVAL);
        ethBridge = new EthBridge();
        ethBridge.initialize(taraTokenOnEth, taraLightClient, FINALIZATION_INTERVAL);

        // Set Up TARA side of the bridge

        NativeConnector taraConnector = new NativeConnector();
        taraConnector.initialize(address(taraBridge), address(taraTokenOnEth));
        (bool success,) = payable(taraConnector).call{value: Constants.MINIMUM_CONNECTOR_DEPOSIT}("");
        if (!success) {
            revert("Failed to initialize tara native connector");
        }

        taraBridge.registerContract(taraConnector);

        ERC20MintingConnector ethOnTaraMintingConnector = new ERC20MintingConnector();
        ethOnTaraMintingConnector.initialize(address(taraBridge), ethTokenOnTara, Constants.NATIVE_TOKEN_ADDRESS);

        (bool success2,) = payable(ethOnTaraMintingConnector).call{value: Constants.MINIMUM_CONNECTOR_DEPOSIT}("");
        if (!success2) {
            revert("Failed to initialize tara minting connector");
        }

        // give ownership ot erc20 to the connector
        ethTokenOnTara.transferOwnership(address(ethOnTaraMintingConnector));

        taraBridge.registerContract(ethOnTaraMintingConnector);

        // Set Up ETH side of the bridge

        NativeConnector ethConnector = new NativeConnector();
        ethConnector.initialize(address(ethBridge), address(ethTokenOnTara));
        (bool success3,) = payable(ethConnector).call{value: Constants.MINIMUM_CONNECTOR_DEPOSIT}("");
        if (!success3) {
            revert("Failed to initialize eth connector");
        }

        ethBridge.registerContract(ethConnector);

        ERC20MintingConnector taraOnEthMintingConnector = new ERC20MintingConnector();
        taraOnEthMintingConnector.initialize(address(ethBridge), taraTokenOnEth, Constants.NATIVE_TOKEN_ADDRESS);

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
