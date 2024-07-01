// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../lib/IBridgeLightClient.sol";
import "../lib/BridgeBase.sol";


/// @custom:oz-upgrades-from TaraBridge
contract TaraBridgeSettable is BridgeBase {
    function initialize(
        IBridgeLightClient _lightClient,
        uint256 _finalizationInterval,
        uint256 _feeMultiplier,
        uint256 _registrationFee,
        uint256 _settlementFee
    ) public initializer {
        __BridgeBase_init(_lightClient, _finalizationInterval, _feeMultiplier, _registrationFee, _settlementFee);
    }

     /**
     * @dev Sets the light client.
     * @param _lightClient The light client to be set.
     * @notice Only the owner can call this function.
     */
    function setLightClient(IBridgeLightClient _lightClient) external onlyOwner {
        lightClient = _lightClient;
    }

}
