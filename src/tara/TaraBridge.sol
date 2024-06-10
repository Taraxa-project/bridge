// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../lib/IBridgeLightClient.sol";
import "../lib/BridgeBase.sol";
import "../connectors/ERC20MintingConnector.sol";

contract TaraBridge is BridgeBase {
    function initialize(
        IBridgeLightClient light_client,
        uint256 finalizationInterval,
        uint256 _feeMultiplier,
        uint256 _registrationFee,
        uint256 _settlementFee
    ) public initializer {
        __BridgeBase_init(light_client, finalizationInterval, _feeMultiplier, _registrationFee, _settlementFee);
    }
}
