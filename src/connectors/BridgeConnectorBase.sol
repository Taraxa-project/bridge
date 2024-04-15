// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "./IBridgeConnector.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";

abstract contract BridgeConnectorBase is IBridgeConnector, Ownable {
    mapping(address => uint256) public feeToClaim;

    constructor(address bridge) payable Ownable() {
        require(msg.value >= 2 ether, "BridgeConnectorBase: insufficient funds");
        _transferOwnership(bridge);
    }

    /**
     * @dev Refunds the specified amount to the given receiver.
     * @param receiver The address of the receiver.
     * @param amount The amount to be refunded.
     */
    function refund(address payable receiver, uint256 amount) public override onlyOwner {
        receiver.transfer(amount);
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
        uint256 gasleftbefore = gasleft();
        address[] memory addresses = applyState(_state);
        uint256 total_fee = common_part + (gasleftbefore - gasleft()) * tx.gasprice;

        for (uint256 i = 0; i < addresses.length; i++) {
            feeToClaim[addresses[i]] += total_fee / addresses.length;
        }
        refund(refund_receiver, total_fee);
    }
}
