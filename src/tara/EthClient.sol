// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

import "../lib/ILightClient.sol";
import {InvalidBridgeRoot} from "../errors/BridgeBaseErrors.sol";
import "beacon-light-client/src/BeaconLightClient.sol";
import "beacon-light-client/src/trie/StorageProof.sol";

contract EthClient is IBridgeLightClient, OwnableUpgradeable {
    BeaconLightClient public client;
    address public ethBridgeAddress;
    bytes32 public bridgeRootKey;

    bytes32 bridgeRoot;

    uint256 refund;

    /// gap for upgrade safety <- can be used to add new storage variables(using up to 49  32 byte slots) in new versions of this contract
    /// If used, decrease the number of slots in the next contract that inherits this one(ex. uint256[48] __gap;)
    uint256[49] __gap;

    /// Events
    event Initialized(address indexed client, address indexed ethBridgeAddress);
    event BridgeRootProcessed(bytes32 indexed bridgeRoot);

    function initialize(BeaconLightClient _client, address _eth_bridge_address) public initializer {
        bridgeRootKey = 0x0000000000000000000000000000000000000000000000000000000000000006;
        ethBridgeAddress = _eth_bridge_address;
        client = _client;
        emit Initialized(address(_client), _eth_bridge_address);
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
        if (bridgeRoot.length != 32) {
            revert InvalidBridgeRoot(bridgeRoot);
        }
        bytes32 stateRoot = client.merkle_root();
        bytes memory br = StorageProof.verify(stateRoot, ethBridgeAddress, account_proof, bridgeRootKey, storage_proof);
        bridgeRoot = bytes32(br);
        emit BridgeRootProcessed(bridgeRoot);
    }

    /**
     * @dev Returns the Merkle root from the light client.
     * @return The Merkle root as a bytes32 value.
     */
    function getMerkleRoot() external view returns (bytes32) {
        return client.merkle_root();
    }
}
