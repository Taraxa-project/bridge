// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import {IBridgeLightClient} from "../lib/IBridgeLightClient.sol";
import {BridgeBase} from "../lib/BridgeBase.sol";

/// @custom:oz-upgrades-from EthBridge
contract EthBridgeGasLimit is BridgeBase {
    function initialize(
        IBridgeLightClient _lightClient,
        uint256 _finalizationInterval,
        uint256 _feeMultiplierFinalize,
        uint256 _feeMultiplierApply,
        uint256 _registrationFee,
        uint256 _settlementFee,
        uint256 _gasPriceLimit
    ) public initializer {
        __initialize_EthBridge_unchained(
            _lightClient,
            _finalizationInterval,
            _feeMultiplierFinalize,
            _feeMultiplierApply,
            _registrationFee,
            _settlementFee,
            _gasPriceLimit
        );
    }

    function __initialize_EthBridge_unchained(
        IBridgeLightClient _lightClient,
        uint256 _finalizationInterval,
        uint256 _feeMultiplierFinalize,
        uint256 _feeMultiplierApply,
        uint256 _registrationFee,
        uint256 _settlementFee,
        uint256 _gasPriceLimit
    ) internal onlyInitializing {
        __BridgeBase_init(
            _lightClient,
            _finalizationInterval,
            _feeMultiplierFinalize,
            _feeMultiplierApply,
            _registrationFee,
            _settlementFee,
            _gasPriceLimit
        );
    }
}
