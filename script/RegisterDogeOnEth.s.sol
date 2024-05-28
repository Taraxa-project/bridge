// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {Constants} from "../src/lib/Constants.sol";
import {BridgeDoge} from "../src/lib/BridgeDoge.sol";
import {ERC20LockingConnector} from "../src/connectors/ERC20LockingConnector.sol";
import {EthBridge} from "../src/eth/EthBridge.sol";
import {IBridgeConnector} from "../src/connectors/IBridgeConnector.sol";

contract RegisterDogeOnEth is Script {
    address public deployerAddress;
    EthBridge public ethBridge;
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
        // check if balance is at least 2 * MINIMUM_CONNECTOR_DEPOSIT
        if (address(deployerAddress).balance < 2 * Constants.MINIMUM_CONNECTOR_DEPOSIT) {
            console.log("Skipping deployment because balance is less than 2 * MINIMUM_CONNECTOR_DEPOSIT");
            return;
        }

        address ethBridgeAddress = vm.envAddress("ETH_BRIDGE_ADDRESS");
        console.log("ETH_BRIDGE_ADDRESS: %s", ethBridgeAddress);
        ethBridge = EthBridge(ethBridgeAddress);
        dogeAddressOnEth = vm.envAddress("DOGE_ON_ETH");
        console.log("DOGE_ON_ETH: %s", dogeAddressOnEth);
        dogeAddressOnTara = vm.envAddress("DOGE_ON_TARA");
        console.log("DOGE_ON_TARA: %s", dogeAddressOnTara);
    }

    function run() public {
        vm.startBroadcast(deployerPrivateKey);

        BridgeDoge doge = BridgeDoge(dogeAddressOnEth);

        //check deployer's balance
        uint256 balance = doge.balanceOf(deployerAddress);
        console.log("Deployer's balance: %s", balance);
        if (balance != 100000000 * 10 ** doge.decimals()) {
            revert("Deployer's balance is less than 100000000 DOGE");
        }

        // Deploy ERC20LockingConnector on ETH
        address dogeLockingConnectorProxy = Upgrades.deployUUPSProxy(
            "ERC20LockingConnector.sol",
            abi.encodeCall(ERC20LockingConnector.initialize, (address(ethBridge), doge, dogeAddressOnTara))
        );

        console.log("ERC20LockingConnector.sol proxy address: %s", dogeLockingConnectorProxy);
        console.log(
            "ERC20LockingConnector.sol implementation address: %s",
            Upgrades.getImplementationAddress(dogeLockingConnectorProxy)
        );

        // Fund the LockingConnector with  ETH
        (bool success,) = payable(dogeLockingConnectorProxy).call{value: Constants.MINIMUM_CONNECTOR_DEPOSIT}("");
        if (!success) {
            revert("Failed to fund the LockingConnector");
        }

        ethBridge.registerContract(IBridgeConnector(dogeLockingConnectorProxy));

        vm.stopBroadcast();
    }
}
