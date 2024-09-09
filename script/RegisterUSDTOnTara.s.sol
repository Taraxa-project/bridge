// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {Constants} from "../src/lib/Constants.sol";
import {USDT} from "../src/lib/USDT.sol";
import {ERC20LockingConnector} from "../src/connectors/ERC20LockingConnector.sol";
import {ERC20MintingConnector} from "../src/connectors/ERC20MintingConnector.sol";
import {TaraBridge} from "../src/tara/TaraBridge.sol";
import {IBridgeConnector} from "../src/connectors/IBridgeConnector.sol";

contract RegisterUSDTOnTara is Script {
    address public deployerAddress;
    TaraBridge public taraBridge;
    address public usdtAddressOnTara;
    address public usdtAddressOnEth;
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
        usdtAddressOnEth = vm.envAddress("USDT_ON_ETH");
        console.log("USDT_ON_ETH: %s", usdtAddressOnEth);
        usdtAddressOnTara = vm.envAddress("USDT_ON_TARA");
        console.log("USDT_ON_TARA: %s", usdtAddressOnTara);
    }

    function run() public {
        vm.startBroadcast(deployerPrivateKey);

        USDT usdtToken = USDT(usdtAddressOnTara);
        // Deploy ERC20MintingConnector on TARA
        address usdtMintingConnectorProxy = Upgrades.deployUUPSProxy(
            "ERC20MintingConnector.sol",
            abi.encodeCall(ERC20MintingConnector.initialize, (taraBridge, usdtToken, usdtAddressOnEth))
        );

        // Transfer token ownership to the MintingConnector
        usdtToken.transferOwnership(usdtMintingConnectorProxy);
        console.log("ERC20MintingConnector.sol proxy address: %s", usdtMintingConnectorProxy);
        console.log(
            "ERC20MintingConnector.sol implementation address: %s",
            Upgrades.getImplementationAddress(usdtMintingConnectorProxy)
        );

        // Fund the MintingConnector with  ETH
        (bool success,) = payable(usdtMintingConnectorProxy).call{value: Constants.MINIMUM_CONNECTOR_DEPOSIT}("");
        if (!success) {
            revert("Failed to fund the MintingConnector");
        }

        taraBridge.registerConnector{value: taraBridge.registrationFee()}(IBridgeConnector(usdtMintingConnectorProxy));

        vm.stopBroadcast();
    }
}
