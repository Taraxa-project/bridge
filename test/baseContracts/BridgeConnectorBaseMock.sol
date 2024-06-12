// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import {InsufficientFunds, RefundFailed} from "../../src/errors/ConnectorErrors.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../src/lib/Constants.sol";
import {BridgeConnectorLogic} from "../../src/connectors/BridgeConnectorLogic.sol";

abstract contract BridgeConnectorBaseMock is BridgeConnectorLogic, Ownable {
    constructor(address bridge) payable Ownable(msg.sender) {
        if (msg.value < Constants.MINIMUM_CONNECTOR_DEPOSIT) {
            revert InsufficientFunds({expected: Constants.MINIMUM_CONNECTOR_DEPOSIT, actual: msg.value});
        }
        _transferOwnership(bridge);
    }

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
