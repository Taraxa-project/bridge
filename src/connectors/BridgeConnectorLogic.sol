// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./IBridgeConnector.sol";
import "../lib/Constants.sol";
import {InsufficientFunds, RefundFailed} from "../errors/ConnectorErrors.sol";

abstract contract BridgeConnectorLogic is IBridgeConnector {
    mapping(address => uint256) public feeToClaim; // will always be in slot 0

    /// Events
    event Funded(address indexed sender, address indexed connectorBase, uint256 amount);
    event Refunded(address indexed receiver, uint256 amount);
    /**
     * @dev Refunds the specified amount to the given receiver.
     * @param receiver The address of the receiver.
     * @param amount The amount to be refunded.
     */

    function refund(address payable receiver, uint256 amount) public virtual override {
        (bool refundSuccess,) = receiver.call{value: amount}("");
        if (!refundSuccess) {
            revert RefundFailed({recipient: receiver, amount: amount});
        }
        emit Refunded(receiver, amount);
    }

    function applyState(bytes calldata) internal virtual returns (address[] memory);

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
    {
        uint256 gasLeftBefore = gasleft();
        address[] memory addresses = applyState(_state);
        uint256 totalFee = common_part + (gasLeftBefore - gasleft()) * tx.gasprice;
        uint256 addressesLength = addresses.length;
        for (uint256 i = 0; i < addressesLength;) {
            feeToClaim[addresses[i]] += totalFee / addresses.length;
            unchecked {
                ++i;
            }
        }
        refund(refund_receiver, totalFee);
    }
}
