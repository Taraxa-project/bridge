// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {EthBridge} from "../src/eth/EthBridge.sol";
import {TaraClient, PillarBlock} from "../src/eth/TaraClient.sol";
import {TestERC20} from "../src/lib/TestERC20.sol";
import {IBridgeLightClient} from "../src/lib/IBridgeLightClient.sol";
import "../src/lib/Constants.sol";

contract TokenDeployer is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        if (vm.envUint("PRIVATE_KEY") == 0) {
            revert("Skipping deployment because PRIVATE_KEY is not set");
        }
        address deployerAddress = vm.envAddress("DEPLOYMENT_ADDRESS");
        string memory symbol = vm.envString("SYMBOL");
        string memory name = vm.envString("NAME");
        console.log("Symbol: %s", symbol);
        console.log("Name: %s", name);
        console.log("Deployer address: %s", deployerAddress);
        vm.startBroadcast(deployerPrivateKey);

        TestERC20 te = new TestERC20(name, symbol);
        console.log("TestERC20 address: %s", address(te));
        address owner = te.owner();
        console.log("Owner: %s", owner);
        te.transferOwnership(deployerAddress);
        address newOwner = te.owner();
        console.log("New owner: %s", newOwner);

        // call symbol to check if the token was deployed successfully
        string memory tokenSymbol = te.symbol();
        string memory tokenName = te.name();
        require(keccak256(abi.encodePacked(tokenSymbol)) == keccak256(abi.encodePacked(symbol)), "Symbol mismatch");
        require(keccak256(abi.encodePacked(tokenName)) == keccak256(abi.encodePacked(name)), "Name mismatch");
        console.log("Deployed to: %s", address(te));
        vm.stopBroadcast();
    }
}
