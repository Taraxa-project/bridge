// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./IBridgeConnector.sol";
import "../lib/Constants.sol";
import "../lib/BridgeBase.sol";

import {InsufficientFunds, RefundFailed} from "../errors/ConnectorErrors.sol";

abstract contract BridgeConnectorBase is IBridgeConnector, OwnableUpgradeable, UUPSUpgradeable {
    BridgeBase public bridge;
    /// gap for upgrade safety <- can be used to add new storage variables(using up to 49  32 byte slots) in new versions of this contract
    /// If used, decrease the number of slots in the next contract that inherits this one(ex. uint256[48] __gap;)
    uint256[49] __gap;

    /// Events
    event Funded(address indexed sender, address indexed connectorBase, uint256 amount);
    event Refunded(address indexed receiver, uint256 amount);

    modifier onlySettled() {
        uint256 fee = bridge.settlementFee();
        if (msg.value < fee) {
            revert InsufficientFunds(fee, msg.value);
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function __BridgeConnectorBase_init(BridgeBase _bridge) public onlyInitializing {
        __BridgeConnectorBase_init_unchained(_bridge);
    }

    function __BridgeConnectorBase_init_unchained(BridgeBase _bridge) internal onlyInitializing {
        __UUPSUpgradeable_init();
        __Ownable_init(msg.sender);
        _transferOwnership(address(_bridge));
        bridge = _bridge;
    }

    function owner() public view override(IBridgeConnector, OwnableUpgradeable) returns (address) {
        return super.owner();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function applyState(bytes calldata) external virtual;
}
