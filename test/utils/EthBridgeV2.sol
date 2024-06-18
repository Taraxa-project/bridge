// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "../../src/lib/SharedStructs.sol";
import "../../src/lib/IBridgeLightClient.sol";
import "../../src/connectors/IBridgeConnector.sol";
import "../../src/connectors/ERC20MintingConnector.sol";
import "../../src/lib/TestERC20.sol";
import "../../src/lib/Constants.sol";
import "../../src/lib/BridgeBase.sol";

/// @custom:oz-upgrades-from EthBridge
contract EthBridgeV2 is BridgeBase {
    // add new value to the storage to test upgradeability
    uint256 public newValue;
    /// Events

    event Initialized(address indexed tara, address indexed light_client, uint256 finalizationInterval);

    function initialize(IERC20MintableBurnable tara, IBridgeLightClient light_client, uint256 finalizationInterval)
        public
        initializer
    {
        __initialize_EthBridge_unchained(tara, light_client, finalizationInterval);
    }

    function reinitialize(uint256 newStorageValue) public {
        newValue = newStorageValue;
    }

    function __initialize_EthBridge_unchained(
        IERC20MintableBurnable tara,
        IBridgeLightClient light_client,
        uint256 finalizationInterval
    ) internal onlyInitializing {
        __BridgeBase_init(light_client, finalizationInterval);
        emit Initialized(address(tara), address(light_client), finalizationInterval);
    }

    function getNewStorageValue() public view returns (uint256) {
        return newValue;
    }

    function registerContractOwner(IBridgeConnector connector) public onlyOwner {
        connectors[address(connector)] = connector;
        emit ConnectorRegistered(
            address(connector),
            connector.getContractSource(),
            connector.getContractDestination()
        );
    }
}
