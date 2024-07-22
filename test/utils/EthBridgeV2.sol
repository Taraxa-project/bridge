// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import {SharedStructs} from "../../src/lib/SharedStructs.sol";
import {IBridgeLightClient} from "../../src/lib/IBridgeLightClient.sol";
import {IBridgeConnector} from "../../src/connectors/IBridgeConnector.sol";
import {ERC20MintingConnector} from "../../src/connectors/ERC20MintingConnector.sol";
import {TestERC20} from "../../src/lib/TestERC20.sol";
import {Constants} from "../../src/lib/Constants.sol";
import {BridgeBase} from "../../src/lib/BridgeBase.sol";

/// @custom:oz-upgrades-from EthBridge
contract EthBridgeV2 is BridgeBase {
    // add new value to the storage to test upgradeability
    uint256 public newValue;

    function initialize(
        IBridgeLightClient _light_client,
        uint256 _finalizationInterval,
        uint256 _feeMultiplier,
        uint256 _registrationFee,
        uint256 _settlementFee
    ) public initializer {
        __initialize_EthBridge_unchained(
            _light_client, _feeMultiplier, _registrationFee, _settlementFee, _finalizationInterval
        );
    }

    function reinitialize(uint256 newStorageValue) public {
        newValue = newStorageValue;
    }

    function __initialize_EthBridge_unchained(
        IBridgeLightClient light_client,
        uint256 _feeMultiplier,
        uint256 _registrationFee,
        uint256 _settlementFee,
        uint256 _finalizationInterval
    ) internal onlyInitializing {
        __BridgeBase_init(light_client, _finalizationInterval, _feeMultiplier, _registrationFee, _settlementFee);
    }

    function getNewStorageValue() public view returns (uint256) {
        return newValue;
    }

    function registerConnectorOwner(IBridgeConnector connector) public onlyOwner {
        connectors[address(connector)] = connector;
        emit ConnectorRegistered(address(connector), connector.getSourceContract(), connector.getDestinationContract());
    }
}
