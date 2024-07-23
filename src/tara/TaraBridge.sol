// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IBridgeLightClient} from "../lib/IBridgeLightClient.sol";
import {BridgeBase} from "../lib/BridgeBase.sol";

contract TaraBridge is BridgeBase {
    function initialize(
        IBridgeLightClient _lightClient,
        uint256 _finalizationInterval,
        uint256 _feeMultiplierFinalize,
        uint256 _feeMultiplierApply,
        uint256 _registrationFee,
        uint256 _settlementFee
    ) public initializer {
        __BridgeBase_init(
            _lightClient,
            _finalizationInterval,
            _feeMultiplierFinalize,
            _feeMultiplierApply,
            _registrationFee,
            _settlementFee
        );
    }
}
