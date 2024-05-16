// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../lib/IBridgeLightClient.sol";
import "../lib/BridgeBase.sol";
import "../connectors/ERC20MintingConnector.sol";

contract TaraBridge is BridgeBase {
    /// Events
    event Initialized(address indexed tara, address indexed light_client, uint256 finalizationInterval);

    function initialize(IERC20MintableBurnable tara, IBridgeLightClient light_client, uint256 finalizationInterval)
        public
        initializer
    {
        __BridgeBase_init(light_client, finalizationInterval);
        emit Initialized(address(tara), address(light_client), finalizationInterval);
    }
}
