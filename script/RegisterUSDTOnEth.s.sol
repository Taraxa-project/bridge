// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {Constants} from "../src/lib/Constants.sol";
import {BridgeUSDT} from "../src/lib/BridgeUSDT.sol";
import {ERC20LockingConnector} from "../src/connectors/ERC20LockingConnector.sol";
import {EthBridge} from "../src/eth/EthBridge.sol";
import {IBridgeConnector} from "../src/connectors/IBridgeConnector.sol";

contract RegisterUSDTOnEth is Script {
    address public deployerAddress;
    EthBridge public ethBridge;
    address public usdtAddressOnTara;
    address public usdtAddressOnEth;
    uint256 public deployerPrivateKey;

    function setUp() public {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployerAddress = vm.envAddress("DEPLOYMENT_ADDRESS");
        console.log("Deployer address: %s", deployerAddress);

        if (vm.envUint("PRIVATE_KEY") == 0) {
            console.log("Skipping deployment because PRIVATE_KEY is not set");
            return;
        }

        address payable ethBridgeAddress = payable(vm.envAddress("ETH_BRIDGE_ADDRESS"));
        console.log("ETH_BRIDGE_ADDRESS: %s", ethBridgeAddress);
        ethBridge = EthBridge(ethBridgeAddress);
        usdtAddressOnEth = vm.envAddress("USDT_ON_ETH");
        console.log("USDT_ON_ETH: %s", usdtAddressOnEth);
        usdtAddressOnTara = vm.envAddress("USDT_ON_TARA");
        console.log("USDT_ON_TARA: %s", usdtAddressOnTara);
    }

    function run() public {
        vm.startBroadcast(deployerPrivateKey);

        BridgeUSDT usdt = BridgeUSDT(usdtAddressOnEth);

        // Deploy ERC20LockingConnector on ETH
        address usdtLockingConnectorProxy = Upgrades.deployUUPSProxy(
            "ERC20LockingConnector.sol",
            abi.encodeCall(ERC20LockingConnector.initialize, (ethBridge, usdt, usdtAddressOnTara))
        );

        console.log("ERC20LockingConnector.sol proxy address: %s", usdtLockingConnectorProxy);
        console.log(
            "ERC20LockingConnector.sol implementation address: %s",
            Upgrades.getImplementationAddress(usdtLockingConnectorProxy)
        );

        // Fund the LockingConnector with  ETH
        (bool success,) = payable(usdtLockingConnectorProxy).call{value: Constants.MINIMUM_CONNECTOR_DEPOSIT}("");
        if (!success) {
            revert("Failed to fund the LockingConnector");
        }

        ethBridge.registerConnector{value: ethBridge.registrationFee()}(IBridgeConnector(usdtLockingConnectorProxy));

        vm.stopBroadcast();
    }
}
