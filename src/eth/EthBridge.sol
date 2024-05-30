// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "../lib/IBridgeLightClient.sol";
import "../connectors/ERC20MintingConnector.sol";
import "../lib/BridgeBase.sol";

contract EthBridge is BridgeBase {
    function initialize(IBridgeLightClient light_client, uint256 finalizationInterval)
        public
        initializer
    {
        __initialize_EthBridge_unchained(light_client, finalizationInterval);
    }

    function __initialize_EthBridge_unchained(
        IBridgeLightClient light_client,
        uint256 finalizationInterval
    ) internal onlyInitializing {
        __BridgeBase_init(light_client, finalizationInterval);
    }
}
