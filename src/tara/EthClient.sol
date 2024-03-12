// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../lib/ILightClient.sol";
import "beacon-light-client/src/BeaconLightClient.sol";
import "beacon-light-client/src/trie/StorageProof.sol";

contract EthClientWrapper is IBridgeLightClient {
    BeaconLightClient public client;
    address ethBridgeAddress;
    bytes32 bridgeRootKey;

    bytes32 bridgeRoot;

    uint256 refund;

    constructor(BeaconLightClient _client, address _eth_bridge_address, bytes32 _bridge_root_key) {
        ethBridgeAddress = _eth_bridge_address;
        bridgeRootKey = _bridge_root_key;
        client = _client;
    }

    /**
     * @dev Implements the IBridgeLightClient interface method
     * @return The finalized bridge root as a bytes32 value.
     */
    function getFinalizedBridgeRoot() external view returns (bytes32) {
        return bridgeRoot;
    }

    function refundAmount() external view returns (uint256) {
        return refund;
    }

    /**
     * @dev Processes the bridge root by verifying account and storage proofs against state root from the light client.
     * @param account_proof The account proofs for the bridge root.
     * @param storage_proof The storage proofs for the bridge root.
     */
    function processBridgeRoot(bytes[] memory account_proof, bytes[] memory storage_proof) external {
        bytes32 stateRoot = client.merkle_root();
        bytes memory br = StorageProof.verify(stateRoot, ethBridgeAddress, account_proof, bridgeRootKey, storage_proof);
        require(bridgeRoot.length == 32, "invalid bridge root(length)");
        bridgeRoot = bytes32(br);
    }

    /**
     * @dev Returns the Merkle root from the light client.
     * @return The Merkle root as a bytes32 value.
     */
    function getMerkleRoot() external view returns (bytes32) {
        return client.merkle_root();
    }
}
