// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "../lib/IBridgeLightClient.sol";
import "../connectors/ERC20MintingConnector.sol";
import "../lib/BridgeBase.sol";

contract EthBridge is BridgeBase {
    function initialize(
        IBridgeLightClient _lightClient,
        uint256 _finalizationInterval,
        uint256 _feeMultiplier,
        uint256 _registrationFee,
        uint256 _settlementFee
    ) public initializer {
        __initialize_EthBridge_unchained(
            _lightClient, _finalizationInterval, _feeMultiplier, _registrationFee, _settlementFee
        );
    }

    function __initialize_EthBridge_unchained(
        IBridgeLightClient _lightClient,
        uint256 _finalizationInterval,
        uint256 _feeMultiplier,
        uint256 _registrationFee,
        uint256 _settlementFee
    ) internal onlyInitializing {
        __BridgeBase_init(_lightClient, _finalizationInterval, _feeMultiplier, _registrationFee, _settlementFee);
    }
}
