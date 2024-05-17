// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {EthBridge} from "../eth/EthBridge.sol";
import {TaraClient, PillarBlock} from "../eth/TaraClient.sol";
import {WETH9} from "../lib/WETH9.sol";
import {IBridgeLightClient} from "../lib/IBridgeLightClient.sol";
import "../lib/Constants.sol";

contract WrapperDeployer is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        if (vm.envUint("PRIVATE_KEY") == 0) {
            console.log("Skipping deployment because PRIVATE_KEY is not set");
            return;
        }
        address deployerAddress = vm.envAddress("DEPLOYMENT_ADDRESS");
        string memory symbol = vm.envString("SYMBOL");
        string memory name = vm.envString("NAME");
        console.log("Symbol: %s", symbol);
        console.log("Name: %s", name);
        console.log("Deployer address: %s", deployerAddress);
        vm.startBroadcast(deployerPrivateKey);

        WETH9 wrappedAsset = new WETH9(name, symbol);

        console.log("Wrapper address: %s", address(wrappedAsset));

        // call symbol to check if the token was deployed successfully
        string memory tokenSymbol = wrappedAsset.symbol();
        string memory tokenName = wrappedAsset.name();
        require(keccak256(abi.encodePacked(tokenSymbol)) == keccak256(abi.encodePacked(symbol)), "Symbol mismatch");
        require(keccak256(abi.encodePacked(tokenName)) == keccak256(abi.encodePacked(name)), "Name mismatch");
        console.log("Deployed to: %s", address(wrappedAsset));
        vm.stopBroadcast();
    }
}
