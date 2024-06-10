// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

import {InvalidEpoch, NoFinalizedState} from "../errors/ConnectorErrors.sol";
import "../lib/SharedStructs.sol";
import "../lib/Constants.sol";
import {TokenConnectorLogic} from "./TokenConnectorLogic.sol";
import "./TokenState.sol";
import {BridgeConnectorBase} from "./BridgeConnectorBase.sol";
import {BridgeConnectorLogic} from "./BridgeConnectorLogic.sol";
import {IBridgeConnector} from "./IBridgeConnector.sol";

abstract contract TokenConnectorBase is BridgeConnectorBase, TokenConnectorLogic {
    function TokenConnectorBase_init(address bridge, address _token, address token_on_other_network)
        public
        onlyInitializing
    {
        __TokenConnectorBase_init(bridge, _token, token_on_other_network);
    }

    function __TokenConnectorBase_init(address bridge, address _token, address token_on_other_network)
        internal
        onlyInitializing
    {
        require(
            bridge != address(0) && _token != address(0) && token_on_other_network != address(0),
            "TokenConnectorBase: invalid bridge, token, or token_on_other_network"
        );
        __BridgeConnectorBase_init(bridge);
        otherNetworkAddress = token_on_other_network;
        token = _token;
        state = new TokenState(0);
    }

    function finalize(uint256 epoch_to_finalize)
        public
        override(TokenConnectorLogic, IBridgeConnector)
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
     * @dev Applies the given state with a refund to the specified receiver.
     * @param _state The state to apply.
     * @param refund_receiver The address of the refund_receiver.
     * @param common_part The common part of the refund.
     */
    function applyStateWithRefund(bytes calldata _state, address payable refund_receiver, uint256 common_part)
        public
        override(BridgeConnectorBase, BridgeConnectorLogic)
        onlyOwner
    {
        super.applyStateWithRefund(_state, refund_receiver, common_part);
    }

    /**
     * @dev Refunds the specified amount to the given receiver.
     * @param receiver The address of the receiver.
     * @param amount The amount to be refunded.
     */
    function refund(address payable receiver, uint256 amount)
        public
        override(BridgeConnectorBase, BridgeConnectorLogic)
        onlyOwner
    {
        super.refund(receiver, amount);
    }
}
