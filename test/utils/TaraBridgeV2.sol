// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IBridgeLightClient} from "../../src/lib/IBridgeLightClient.sol";
import {BridgeBase} from "../../src/lib/BridgeBase.sol";

/// @custom:oz-upgrades-from TaraBridge
contract TaraBridgeV2 is BridgeBase {
    uint256 public newValue;

    function initialize(
        IBridgeLightClient light_client,
        uint256 _finalizationInterval,
        uint256 _feeMultiplierFinalize,
        uint256 _feeMultiplierApply,
        uint256 _registrationFee,
        uint256 _settlementFee
    ) public initializer {
        __BridgeBase_init(
            light_client,
            _finalizationInterval,
            _feeMultiplierFinalize,
            _feeMultiplierApply,
            _registrationFee,
            _settlementFee
        );
    }

    function reinitialize(uint256 newStorageValue) public {
        newValue = newStorageValue;
    }

    function getNewStorageValue() public view returns (uint256) {
        return newValue;
    }
}
