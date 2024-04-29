// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "../lib/SharedStructs.sol";
import "../lib/ILightClient.sol";
import "../connectors/IBridgeConnector.sol";
import "../connectors/ERC20MintingConnector.sol";
import "../lib/TestERC20.sol";
import "../lib/Constants.sol";
import "../lib/BridgeBase.sol";

contract EthBridge is BridgeBase {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// Events
    event Initialized(address indexed tara, address indexed light_client, uint256 finalizationInterval);

    function initialize(IERC20MintableBurnable tara, IBridgeLightClient light_client, uint256 finalizationInterval)
        public
        initializer
    {
        __initialize_EthBridge_unchained(tara, light_client, finalizationInterval);
    }

    function __initialize_EthBridge_unchained(
        IERC20MintableBurnable tara,
        IBridgeLightClient light_client,
        uint256 finalizationInterval
    ) internal initializer {
        __BridgeBase_init(light_client, finalizationInterval);
        localAddress[Constants.TARA_PLACEHOLDER] = address(tara);
        tokenAddresses.push(address(tara));

        emit Initialized(address(tara), address(light_client), finalizationInterval);
    }
}
