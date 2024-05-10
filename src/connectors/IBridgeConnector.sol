// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "../lib/SharedStructs.sol";

/**
 * @title IBridgeConnector
 * @dev Interface for bridgeable contracts.
 */
interface IBridgeConnector {
    /**
     * @dev Finalizes the bridge operation and returns a bytes32 value hash.
     * @param epoch The epoch to be finalized
     * @return finalizedHash of the finalized state
     */
    function finalize(uint256 epoch) external returns (bytes32 finalizedHash);

    /**
     * @dev Checks if the state is empty.
     * @return true if the state is empty, false otherwise
     */
    function isStateEmpty() external view returns (bool);
    /**
     * @dev Retrieves the finalized state of the bridgeable contract.
     * @return A bytes serialized finalized state
     */
    function getFinalizedState() external view returns (bytes memory);

    /**
     * @dev Returns the address of the underlying contract in this network
     */
    function getContractAddress() external view returns (address);

    /**
     * @dev Returns the address of the bridged contract in the other network
     */
    function getBridgedContractAddress() external view returns (address);

    /**
     * @dev Applies the given state with a refund to the specified receiver.
     * @param _state The state to apply.
     * @param receiver The address of the receiver.
     * @param amount The amount of refund to send.
     */
    function applyStateWithRefund(bytes calldata _state, address payable receiver, uint256 amount) external;

    /**
     * @dev Refunds the given amount to the receiver
     * @param receiver The receiver of the refund
     * @param amount The amount to be refunded
     */
    function refund(address payable receiver, uint256 amount) external;
}
