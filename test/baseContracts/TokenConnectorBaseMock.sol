// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {InvalidEpoch, NoFinalizedState} from "../../src/errors/ConnectorErrors.sol";
import "../../src/lib/SharedStructs.sol";
import "../../src/lib/Constants.sol";
import "./BridgeConnectorBaseMock.sol";
import "../../src/connectors/TokenState.sol";
import "../../src/connectors/TokenConnectorLogic.sol";

abstract contract TokenConnectorBaseMock is BridgeConnectorBaseMock, TokenConnectorLogic {
    constructor(address bridge, address _token, address token_on_other_network)
        payable
        BridgeConnectorBaseMock(bridge)
    {
        otherNetworkAddress = token_on_other_network;
        token = _token;
        state = new TokenState(0);
    }

    function finalize(uint256 epoch_to_finalize)
        public
        override(IBridgeConnector, TokenConnectorLogic)
        onlyOwner
        returns (bytes32)
    {
        if (epoch_to_finalize != state.epoch()) {
            revert InvalidEpoch({expected: state.epoch(), actual: epoch_to_finalize});
        }

        // increase epoch if there are no pending transfers
        if (state.empty() && address(finalizedState) != address(0) && finalizedState.empty()) {
            state.increaseEpoch();
            finalizedState.increaseEpoch();
        } else {
            finalizedState = state;
            state = new TokenState(epoch_to_finalize + 1);
        }
        emit Finalized(epoch_to_finalize);
        return keccak256(finalizedSerializedTransfers());
    }

    /**
     * @dev Refunds the specified amount to the given receiver.
     * @param receiver The address of the receiver.
     * @param amount The amount to be refunded.
     */
    function refund(address payable receiver, uint256 amount)
        public
        override(BridgeConnectorBaseMock, BridgeConnectorLogic)
        onlyOwner
    {
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
        override(BridgeConnectorBaseMock, BridgeConnectorLogic)
        onlyOwner
    {
        super.applyStateWithRefund(_state, refund_receiver, common_part);
    }
}
