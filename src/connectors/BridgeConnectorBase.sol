// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../lib/Constants.sol";
import {InsufficientFunds, RefundFailed} from "../errors/ConnectorErrors.sol";
import {BridgeConnectorLogic} from "./BridgeConnectorLogic.sol";

abstract contract BridgeConnectorBase is BridgeConnectorLogic, OwnableUpgradeable, UUPSUpgradeable {
    /// gap for upgrade safety <- can be used to add new storage variables(using up to 49  32 byte slots) in new versions of this contract
    /// If used, decrease the number of slots in the next contract that inherits this one(ex. uint256[48] __gap;)
    uint256[49] __gap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    receive() external payable {
        emit Funded(msg.sender, address(this), msg.value);
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

    /**
     * @dev Refunds the specified amount to the given receiver.
     * @param receiver The address of the receiver.
     * @param amount The amount to be refunded.
     */
    function refund(address payable receiver, uint256 amount) public virtual override onlyOwner {
        super.refund(receiver, amount);
    }

    /**
     * @dev Applies the given state with a refund to the specified receiver.
     * @param _state The state to apply.
     * @param refund_receiver The address of the refund_receiver.
     * @param common_part The common part of the refund.
     */
    function applyStateWithRefund(bytes calldata _state, address payable refund_receiver, uint256 common_part)
        public
        virtual
        override
        onlyOwner
    {
        super.applyStateWithRefund(_state, refund_receiver, common_part);
    }
}
