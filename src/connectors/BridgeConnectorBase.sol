// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

import "./IBridgeConnector.sol";
import {InsufficientFunds, RefundFailed} from "../errors/ConnectorErrors.sol";
import "forge-std/console.sol";

abstract contract BridgeConnectorBase is IBridgeConnector, OwnableUpgradeable {
    mapping(address => uint256) public feeToClaim; // will always be in slot 0

    /// gap for upgrade safety <- can be used to add new storage variables(using up to 49  32 byte slots) in new versions of this contract
    /// If used, decrease the number of slots in the next contract that inherits this one(ex. uint256[48] __gap;)
    uint256[49] __gap;

    /// Events
    event Funded(address indexed sender, address indexed connectorBase, uint256 amount);
    event Refunded(address indexed receiver, uint256 amount);
    event StateApplied(bytes indexed state, address indexed receiver, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function __BridgeConnectorBase_init(address bridge) public payable onlyInitializing {
        __BridgeConnectorBase_init_unchained(bridge);
    }

    function __BridgeConnectorBase_init_unchained(address bridge) internal onlyInitializing {
        __Ownable_init(msg.sender);
        if (msg.value < 2 ether) {
            revert InsufficientFunds({expected: 2 ether, actual: msg.value});
        }
        _transferOwnership(bridge);
        emit Funded(msg.sender, address(this), msg.value);
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
        uint256 gasleftbefore = gasleft();
        address[] memory addresses = applyState(_state);
        uint256 total_fee = common_part + (gasleftbefore - gasleft()) * tx.gasprice;

        unchecked {
            uint256 addressesLength = addresses.length;
            for (uint256 i = 0; i < addressesLength; i++) {
                feeToClaim[addresses[i]] += total_fee / addresses.length;
            }
        }
        refund(refund_receiver, total_fee);
        emit StateApplied(_state, refund_receiver, total_fee);
    }
}
