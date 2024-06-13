// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../lib/Constants.sol";
import {InsufficientFunds, RefundFailed} from "../errors/ConnectorErrors.sol";

abstract contract UpgradeableBase is OwnableUpgradeable, UUPSUpgradeable {
    /// gap for upgrade safety <- can be used to add new storage variables(using up to 49  32 byte slots) in new versions of this contract
    /// If used, decrease the number of slots in the next contract that inherits this one(ex. uint256[48] __gap;)
    uint256[49] __gap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function __BridgeConnectorBase_init(address bridge) public onlyInitializing {
        __BridgeConnectorBase_init_unchained(bridge);
    }

    function __BridgeConnectorBase_init_unchained(address bridge) internal onlyInitializing {
        __UUPSUpgradeable_init();
        __Ownable_init(msg.sender);
        _transferOwnership(bridge);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
