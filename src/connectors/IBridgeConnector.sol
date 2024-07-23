// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

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
     * @dev Applies the given state to the bridgeable contract.
     * @param _state The state to apply.
     */
    function applyState(bytes calldata _state) external;

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
    function getSourceContract() external view returns (address);

    /**
     * @dev Returns the address of the bridged contract on the other network
     */
    function getDestinationContract() external view returns (address);

    /**
     * @dev Returns the length of the state entries
     */
    function getStateLength() external view returns (uint256);
}
