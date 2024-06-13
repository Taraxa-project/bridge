// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

import {InvalidEpoch, NoFinalizedState, RefundFailed} from "../errors/ConnectorErrors.sol";
import "../lib/SharedStructs.sol";
import "../lib/Constants.sol";
import "./TokenState.sol";
import "./IBridgeConnector.sol";

abstract contract TokenConnectorLogic is IBridgeConnector {
    address public token; // slot 1 as slot 0 is used by BridgeConnectorBase
    address public otherNetworkAddress; // slot 2
    TokenState public state; // slot 3
    TokenState public finalizedState; // slot 4
    mapping(address => uint256) public toClaim; // slot 5
    mapping(address => uint256) public feeToClaim; // will always be in slot 6

    /// Events
    event Funded(address indexed sender, address indexed connectorBase, uint256 amount);
    event Refunded(address indexed receiver, uint256 amount);
    event Finalized(uint256 indexed epoch);
    event ClaimAccrued(address indexed account, uint256 value);
    event Claimed(address indexed account, uint256 value);

    /**
     * @dev Refunds the specified amount to the given receiver.
     * @param receiver The address of the receiver.
     * @param amount The amount to be refunded.
     */
    function refund(address payable receiver, uint256 amount) public override {
        (bool refundSuccess,) = receiver.call{value: amount}("");
        if (!refundSuccess) {
            revert RefundFailed({recipient: receiver, amount: amount});
        }
        emit Refunded(receiver, amount);
    }

    /**
     * @dev Applies the given state with a refund to the specified receiver.
     * @param _state The state to apply.
     * @param refund_receiver The address of the refund_receiver.
     * @param common_part The common part of the refund.
     */
    function applyStateWithRefund(bytes calldata _state, address payable refund_receiver, uint256 common_part)
        public
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

    function epoch() public view returns (uint256) {
        return state.epoch();
    }

    function deserializeTransfers(bytes memory data) internal pure returns (Transfer[] memory) {
        return abi.decode(data, (Transfer[]));
    }

    function finalizedSerializedTransfers() internal view returns (bytes memory) {
        return abi.encode(finalizedState.getTransfers());
    }

    function isStateEmpty() external view override returns (bool) {
        return state.empty();
    }

    function finalize(uint256 epoch_to_finalize) public virtual override returns (bytes32) {
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
     * @dev Retrieves the finalized state of the bridgeable contract.
     * @return A bytes serialized finalized state
     */
    function getFinalizedState() public view override returns (bytes memory) {
        if (address(finalizedState) == address(0)) {
            revert NoFinalizedState();
        }

        if (finalizedState.empty()) {
            return new bytes(0);
        }
        return finalizedSerializedTransfers();
    }

    /**
     * @dev Returns the address of the underlying contract in this network
     */
    function getContractSource() public view returns (address) {
        return address(token);
    }

    /**
     * @dev Returns the address of the bridged contract on the other network
     */
    function getContractDestination() external view returns (address) {
        return otherNetworkAddress;
    }

    /**
     * @dev Allows the caller to claim tokens by sending Ether to this function to cover fees.
     * This function is virtual and must be implemented by derived contracts.
     */
    function claim() public payable virtual;

    function applyState(bytes calldata) internal virtual returns (address[] memory);
}
