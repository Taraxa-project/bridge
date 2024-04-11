// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./TaraConnector.sol";
import "../lib/ILightClient.sol";
import "../lib/Constants.sol";
import "../lib/BridgeBase.sol";

contract TaraBridge is BridgeBase {
    constructor(address tara_addresss_on_eth, IBridgeLightClient light_client) payable BridgeBase(light_client) {
        connectors[Constants.TARA_PLACEHOLDER] = new TaraConnector{value:msg.value}(address(this), tara_addresss_on_eth);
        localAddress[tara_addresss_on_eth] = Constants.TARA_PLACEHOLDER;
        tokenAddresses.push(Constants.TARA_PLACEHOLDER);
    }
}
