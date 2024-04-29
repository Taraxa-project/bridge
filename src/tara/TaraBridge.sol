// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./TaraConnector.sol";
import "../lib/ILightClient.sol";
import "../lib/Constants.sol";
import "../lib/BridgeBase.sol";

contract TaraBridge is BridgeBase {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// Events
    event Initialized(address indexed tara, address indexed light_client, uint256 finalizationInterval);

    function initialize(address tara_address_on_eth, IBridgeLightClient light_client, uint256 finalizationInterval)
        public
        payable
        initializer
    {
        __BridgeBase_init(light_client, finalizationInterval);
        connectors[Constants.TARA_PLACEHOLDER] = new TaraConnector();
        TaraConnector(address(connectors[Constants.TARA_PLACEHOLDER])).initialize{value: msg.value}(
            address(this), tara_address_on_eth
        );
        localAddress[tara_address_on_eth] = Constants.TARA_PLACEHOLDER;
        tokenAddresses.push(Constants.TARA_PLACEHOLDER);
        emit Initialized(tara_address_on_eth, address(light_client), finalizationInterval);
    }
}
