// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../src/tara/TaraConnector.sol";
import "../../src/lib/ILightClient.sol";
import "../../src/lib/Constants.sol";
import "../../src/lib/BridgeBase.sol";

/// @custom:oz-upgrades-from TaraBridge
contract TaraBridgeV2 is BridgeBase {
    uint256 public newValue;
    /// Events

    event Initialized(address indexed tara, address indexed light_client, uint256 finalizationInterval);

    function initialize(address tara_address_on_eth, IBridgeLightClient light_client, uint256 finalizationInterval)
        public
        initializer
    {
        __BridgeBase_init(light_client, finalizationInterval);
        emit Initialized(tara_address_on_eth, address(light_client), finalizationInterval);
    }

    function reinitialize(uint256 newStorageValue) public {
        newValue = newStorageValue;
    }

    function getNewStorageValue() public view returns (uint256) {
        return newValue;
    }
}
