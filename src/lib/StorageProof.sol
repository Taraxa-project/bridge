// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "beacon-light-client/src/trie/State.sol";
import "beacon-light-client/src/rlp/RLPDecode.sol";
import "beacon-light-client/src/trie/SecureMerkleTrie.sol";

/**
 * @title StorageProof
 * @dev This library provides functions to verify the proof of an account and the proof of a storage value separately,
 * so it will be cheaper to verify the proofs for the multiple storage values from the same account.
 */
library StorageProof {
    using State for bytes;
    using RLPDecode for bytes;
    using RLPDecode for RLPDecode.RLPItem;

    /**
     * @dev Verifies the proof of an account in a Merkle tree.
     * @param root The root hash of the Merkle tree.
     * @param account The address of the account to verify.
     * @param account_proof The proof data for the account.
     * @return storage_root The storage root hash of the account.
     */
    function verifyAccountProof(bytes32 root, address account, bytes[] memory account_proof)
        internal
        pure
        returns (bytes32 storage_root)
    {
        bytes memory account_hash = abi.encodePacked(account);
        bytes memory data = SecureMerkleTrie.get(account_hash, account_proof, root);
        return data.toEVMAccount().storage_root;
    }

    /**
     * @dev Proves the existence of a storage value in a Merkle Patricia Trie.
     * @param storage_root The storage root hash of the account.
     * @param storage_key The key of the storage value to prove.
     * @param storage_proof The proof data for the storage value.
     * @return value The value of the storage value.
     */
    function proofStorageValue(bytes32 storage_root, bytes32 storage_key, bytes[] memory storage_proof)
        internal
        pure
        returns (bytes32 value)
    {
        bytes memory storage_key_hash = abi.encodePacked(storage_key);
        bytes memory raw = SecureMerkleTrie.get(storage_key_hash, storage_proof, storage_root);
        return raw.toRLPItem().readBytes32();
    }
}
