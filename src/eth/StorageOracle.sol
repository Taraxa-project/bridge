// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../lib/TrieProofs.sol";

contract StorageOracle {
    using TrieProofs for bytes;
    using RLP for RLP.RLPItem;
    using RLP for bytes;

    uint8 private constant ACCOUNT_STORAGE_ROOT_INDEX = 2;

    string private constant ERROR_BLOCKHASH_NOT_AVAILABLE = "BLOCKHASH_NOT_AVAILABLE";
    string private constant ERROR_INVALID_BLOCK_HEADER = "INVALID_BLOCK_HEADER";
    string private constant ERROR_UNPROCESSED_STORAGE_ROOT = "UNPROCESSED_STORAGE_ROOT";

    // Proven storage root for account at block number
    mapping(address => bytes32) public storageRoot;

    event ProcessStorageRoot(address indexed account, bytes32 storageRoot);

    function processStorageRoot(address account, bytes32 stateRoot, bytes calldata accountStateProof) external {
        // The path for an account in the state trie is the hash of its address
        bytes32 proofPath = keccak256(abi.encodePacked(account));

        // Get the account state from a merkle proof in the state trie. Returns an RLP encoded bytes array
        bytes memory accountRLP = accountStateProof.verify(stateRoot, proofPath); // reverts if proof is invalid
        // Extract the storage root from the account node and convert to bytes32
        bytes32 accountStorageRoot = bytes32(accountRLP.toRlpItem().toList()[ACCOUNT_STORAGE_ROOT_INDEX].toUint());

        storageRoot[account] = accountStorageRoot; // Cache the storage root in storage as processing is expensive

        emit ProcessStorageRoot(account, accountStorageRoot);
    }

    function getStorageValue(address account, uint256 slot, bytes calldata storageProof)
        external
        view
        returns (bytes32)
    {
        bytes32 root = storageRoot[account];
        require(root != bytes32(0), ERROR_UNPROCESSED_STORAGE_ROOT);

        // The path for a storage value is the hash of its slot
        bytes32 proofPath = keccak256(abi.encodePacked(slot));
        return bytes32(storageProof.verify(root, proofPath).toRlpItem().toUintStrict());
    }

    function verifySlot(
        address account,
        bytes calldata accountStateProof,
        bytes32 stateRoot,
        uint256 slot,
        bytes calldata storageProof
    ) external pure returns (bytes32) {
        bytes32 accountProofPath = keccak256(abi.encodePacked(account));

        // Get the account state from a merkle proof in the state trie. Returns an RLP encoded bytes array
        bytes memory accountRLP = accountStateProof.verify(stateRoot, accountProofPath); // reverts if proof is invalid

        // Extract the storage root from the account node and convert to bytes32
        bytes32 root = bytes32(accountRLP.toRlpItem().toList()[ACCOUNT_STORAGE_ROOT_INDEX].toUint());

        require(root != bytes32(0), ERROR_UNPROCESSED_STORAGE_ROOT);

        // The path for a storage value is the hash of its slot
        bytes32 proofPath = keccak256(abi.encodePacked(slot));
        return bytes32(storageProof.verify(root, proofPath).toRlpItem().toUintStrict());
    }

    /**
     * @dev Extract state root from block header, verifying block hash
     */
    function getStateRoot(bytes memory blockHeaderRLP, bytes32 blockHash) external pure returns (bytes32 stateRoot) {
        require(blockHeaderRLP.length > 123, ERROR_INVALID_BLOCK_HEADER); // prevent from reading invalid memory
        require(keccak256(blockHeaderRLP) == blockHash, ERROR_INVALID_BLOCK_HEADER);
        // 0x7b = 0x20 (length) + 0x5b (position of state root in header, [91, 123])
        assembly {
            stateRoot := mload(add(blockHeaderRLP, 0x7b))
        }
    }

    function verifyMultiproof(address account, bytes calldata multiProof, bytes calldata values)
        external
        view
        returns (bool)
    {
        return multiProof.verifyMultiproof(values, storageRoot[account]);
    }
}
