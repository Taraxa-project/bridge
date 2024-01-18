// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./TrieProofs.sol";

contract StorageOracle {
    using TrieProofs for bytes;
    using RLP for RLP.RLPItem;
    using RLP for bytes;

    uint8 private constant ACCOUNT_STORAGE_ROOT_INDEX = 2;
    string private constant ERROR_UNPROCESSED_STORAGE_ROOT = "UNPROCESSED_STORAGE_ROOT";

    function verifySlot(
        address account,
        bytes32 stateRoot,
        bytes calldata accountStateProof,
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
        return bytes32(storageProof.verify(root, proofPath).toRlpItem().toUint());
    }
}
