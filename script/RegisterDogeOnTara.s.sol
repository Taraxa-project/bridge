// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {Constants} from "../src/lib/Constants.sol";
import {TestERC20} from "../src/lib/TestERC20.sol";
import {ERC20LockingConnector} from "../src/connectors/ERC20LockingConnector.sol";
import {ERC20MintingConnector} from "../src/connectors/ERC20MintingConnector.sol";
import {TaraBridge} from "../src/tara/TaraBridge.sol";
import {IBridgeConnector} from "../src/connectors/IBridgeConnector.sol";

contract RegisterDogeOnTara is Script {
    address public deployerAddress;
    TaraBridge public taraBridge;
    address public dogeAddressOnTara;
    address public dogeAddressOnEth;
    uint256 public deployerPrivateKey;
    uint256 public finalizationInterval = 100;

    function setUp() public {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployerAddress = vm.envAddress("DEPLOYMENT_ADDRESS");
        console.log("Deployer address: %s", deployerAddress);

        if (vm.envUint("PRIVATE_KEY") == 0) {
            console.log("Skipping deployment because PRIVATE_KEY is not set");
            return;
        }

        address payable taraBridgeAddress = payable(vm.envAddress("TARA_BRIDGE_ADDRESS"));
        console.log("TARA_BRIDGE_ADDRESS: %s", taraBridgeAddress);
        taraBridge = TaraBridge(taraBridgeAddress);
        dogeAddressOnEth = vm.envAddress("DOGE_ON_ETH");
        console.log("DOGE_ON_ETH: %s", dogeAddressOnEth);
        dogeAddressOnTara = vm.envAddress("DOGE_ON_TARA");
        console.log("DOGE_ON_TARA: %s", dogeAddressOnTara);
    }

    function run() public {
        vm.startBroadcast(deployerPrivateKey);

        TestERC20 dogeToken = TestERC20(dogeAddressOnTara);
        // Deploy ERC20MintingConnector on TARA
        address dogeMintingConnectorProxy = Upgrades.deployUUPSProxy(
            "ERC20MintingConnector.sol",
            abi.encodeCall(ERC20MintingConnector.initialize, (taraBridge, dogeToken, dogeAddressOnEth))
        );

        // Transfer token ownership to the MintingConnector
        dogeToken.transferOwnership(dogeMintingConnectorProxy);
        console.log("ERC20MintingConnector.sol proxy address: %s", dogeMintingConnectorProxy);
        console.log(
            "ERC20MintingConnector.sol implementation address: %s",
            Upgrades.getImplementationAddress(dogeMintingConnectorProxy)
        );

        // Fund the MintingConnector with  ETH
        (bool success,) = payable(dogeMintingConnectorProxy).call{value: Constants.MINIMUM_CONNECTOR_DEPOSIT}("");
        if (!success) {
            revert("Failed to fund the MintingConnector");
        }

        taraBridge.registerContract{value: taraBridge.registrationFee()}(IBridgeConnector(dogeMintingConnectorProxy));

        vm.stopBroadcast();
    }
}
