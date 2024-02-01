// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "../lib/SharedStructs.sol";

/**
 * @title IBridgeConnector
 * @dev Interface for bridgeable contracts.
 */
interface IBridgeConnector {
    /**
     * @dev Finalizes the bridge operation and returns a bytes32 value hash
     * @param epoch The epoch to be finalized
     * @return hash of the finalized state
     */
    function finalize(uint256 epoch) external returns (bytes32);

    /**
     * @dev Retrieves the finalized state of the bridgeable contract.
     * @return A bytes serialized finalized state
     */
    function getFinalizedState() external view returns (bytes memory);

    /**
     * @dev Applies the given state to the contract.
     * @param state The state to be applied.
     */
    function applyState(bytes calldata state) external;

    /**
     * @dev Returns the address of the underlying contract in this network
     */
    function getContractAddress() external view returns (address);

    /**
     * @dev Returns the address of the bridged contract in the other network
     */
    function getBridgedContractAddress() external view returns (address);
}
