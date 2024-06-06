// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "../../src/connectors/IBridgeConnector.sol";
import {InsufficientFunds, RefundFailed} from "../../src/errors/ConnectorErrors.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../src/lib/Constants.sol";

abstract contract BridgeConnectorBaseMock is IBridgeConnector, Ownable {
    mapping(address => uint256) public feeToClaim;

    /// Events
    event Funded(address indexed sender, address indexed connectorBase, uint256 amount);
    event Refunded(address indexed receiver, uint256 amount);

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
    function refund(address payable receiver, uint256 amount) public override onlyOwner {
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
        override
        onlyOwner
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
