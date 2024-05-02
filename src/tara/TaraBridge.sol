// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./TaraConnector.sol";
import "../lib/ILightClient.sol";
import "../lib/Constants.sol";
import "../lib/BridgeBase.sol";

contract TaraBridge is BridgeBase {
    /// Events
    event Initialized(address indexed tara, address indexed light_client, uint256 finalizationInterval);

    function initialize(address tara_address_on_eth, IBridgeLightClient light_client, uint256 finalizationInterval)
        public
        initializer
    {
        __BridgeBase_init(light_client, finalizationInterval);
        emit Initialized(tara_address_on_eth, address(light_client), finalizationInterval);
    }
}
