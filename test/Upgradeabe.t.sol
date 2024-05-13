// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "forge-std/Test.sol";

import "../src/tara/TaraBridge.sol";
import {NativeConnector} from "../src/connectors/NativeConnector.sol";
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
    TestERC20 taraTokenOnEth;
    TestERC20 ethTokenOnTara;
    TaraBridge taraBridge;
    EthBridge ethBridge;

    address caller = vm.addr(0x1234);
    uint256 constant FINALIZATION_INTERVAL = 100;

    function setUp() public {
        payable(caller).transfer(100 ether);
        taraLightClient = new BridgeLightClientMock();
        ethLightClient = new BridgeLightClientMock();
        taraTokenOnEth =
            TestERC20(Upgrades.deployUUPSProxy("TestERC20.sol", abi.encodeCall(TestERC20.initialize, ("Tara", "TARA"))));
        ethTokenOnTara =
            TestERC20(Upgrades.deployUUPSProxy("TestERC20.sol", abi.encodeCall(TestERC20.initialize, ("Eth", "ETH"))));
        taraBridge = TaraBridge(
            Upgrades.deployUUPSProxy(
                "TaraBridge.sol",
                abi.encodeCall(TaraBridge.initialize, (taraTokenOnEth, ethLightClient, FINALIZATION_INTERVAL))
            )
        );
        ethBridge = EthBridge(
            Upgrades.deployUUPSProxy(
                "EthBridge.sol",
                abi.encodeCall(EthBridge.initialize, (taraTokenOnEth, taraLightClient, FINALIZATION_INTERVAL))
            )
        );

        // Set Up TARA side of the bridge

        NativeConnector taraConnector = NativeConnector(
            payable(
                Upgrades.deployUUPSProxy(
                    "NativeConnector.sol",
                    abi.encodeCall(NativeConnector.initialize, (address(taraBridge), address(taraTokenOnEth)))
                )
            )
        );
        (bool success,) = payable(taraConnector).call{value: Constants.MINIMUM_CONNECTOR_DEPOSIT}("");
        if (!success) {
            revert("Failed to initialize tara native connector");
        }

        taraBridge.registerContract(taraConnector);

        ERC20MintingConnector ethOnTaraMintingConnector = ERC20MintingConnector(
            payable(
                Upgrades.deployUUPSProxy(
                    "ERC20MintingConnector.sol",
                    abi.encodeCall(
                        ERC20MintingConnector.initialize,
                        (address(taraBridge), taraTokenOnEth, Constants.NATIVE_TOKEN_ADDRESS)
                    )
                )
            )
        );

        (bool success2,) = payable(ethOnTaraMintingConnector).call{value: Constants.MINIMUM_CONNECTOR_DEPOSIT}("");
        if (!success2) {
            revert("Failed to initialize tara minting connector");
        }

        taraBridge.registerContract(ethOnTaraMintingConnector);

        // Set Up ETH side of the bridge

        NativeConnector ethConnector = NativeConnector(
            payable(
                Upgrades.deployUUPSProxy(
                    "NativeConnector.sol",
                    abi.encodeCall(NativeConnector.initialize, (address(ethBridge), address(ethTokenOnTara)))
                )
            )
        );
        (bool success3,) = payable(ethConnector).call{value: Constants.MINIMUM_CONNECTOR_DEPOSIT}("");
        if (!success3) {
            revert("Failed to initialize eth connector");
        }

        ethBridge.registerContract(ethConnector);

        ERC20MintingConnector taraOnEthMintingConnector = ERC20MintingConnector(
            payable(
                Upgrades.deployUUPSProxy(
                    "ERC20MintingConnector.sol",
                    abi.encodeCall(
                        ERC20MintingConnector.initialize,
                        (address(ethBridge), taraTokenOnEth, Constants.NATIVE_TOKEN_ADDRESS)
                    )
                )
            )
        );

        (bool success4,) = payable(taraOnEthMintingConnector).call{value: Constants.MINIMUM_CONNECTOR_DEPOSIT}("");
        if (!success4) {
            revert("Failed to initialize minting connector");
        }

        ethBridge.registerContract(taraOnEthMintingConnector);
    }

    // define it to not fail on incoming transfers
    receive() external payable {}

    function test_upgrade_ethBridge() public {
        Options memory opts;
        opts.referenceContract = "EthBridge.sol";

        uint256 newFinalizationInterval = 6666;

        address implAddressV1 = Upgrades.getImplementationAddress(address(ethBridge));
        vm.prank(caller);
        Upgrades.upgradeProxy(
            address(ethBridge), "EthBridgeV2.sol", (abi.encodeCall(EthBridgeV2.reinitialize, newFinalizationInterval))
        );
        address implAddressV2 = Upgrades.getImplementationAddress(address(ethBridge));
        assertNotEq(implAddressV1, implAddressV2, "Implementation address should not change after upgrade");
        EthBridgeV2 upgradedBridge = EthBridgeV2(address(ethBridge));
        assertEq(upgradedBridge.getNewStorageValue(), newFinalizationInterval);
    }

    function test_upgrade_taraBridge() public {
        Options memory opts;
        opts.referenceContract = "TaraBridge.sol";

        uint256 newFinalizationInterval = 6666;
        address implAddressV1 = Upgrades.getImplementationAddress(address(taraBridge));
        vm.prank(caller);
        Upgrades.upgradeProxy(
            address(taraBridge),
            "TaraBridgeV2.sol",
            (abi.encodeCall(TaraBridgeV2.reinitialize, newFinalizationInterval))
        );
        address implAddressV2 = Upgrades.getImplementationAddress(address(taraBridge));
        assertNotEq(implAddressV1, implAddressV2, "Implementation address should not change after upgrade");
        TaraBridgeV2 upgradedBridge = TaraBridgeV2(address(taraBridge));
        assertEq(upgradedBridge.getNewStorageValue(), newFinalizationInterval);
    }
}
