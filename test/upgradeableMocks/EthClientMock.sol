// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {Test, console} from "forge-std/Test.sol";
import {EthClient} from "../../src/tara/EthClient.sol";
import {BeaconLightClient} from "beacon-light-client/src/BeaconLightClient.sol";

contract EthClientMock is EthClient {
    function initializeIt(BeaconLightClient _client, address _eth_bridge_address) public initializer {
        bridgeRootKey = 0x0000000000000000000000000000000000000000000000000000000000000000;
        ethBridgeAddress = _eth_bridge_address;
        client = _client;
        emit Initialized(address(_client), _eth_bridge_address);
    }
}
