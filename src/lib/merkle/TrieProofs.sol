// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./RLP.sol";

/*
Forked from: https://github.com/lorenzb/proveth/blob/master/onchain/ProvethVerifier.sol
*/

library TrieProofs {
    using RLP for RLP.RLPItem;
    using RLP for bytes;

    bytes32 internal constant EMPTY_TRIE_ROOT_HASH = 0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421;

    function verify(
        bytes calldata proofRLP, //multiproof map
        bytes32 rootHash,
        bytes32 path32
    ) internal pure returns (bytes memory value) {
        // TODO: Optimize by using word-size paths instead of byte arrays
        bytes memory path = new bytes(32);
        assembly {
            mstore(add(path, 0x20), path32)
        } // careful as path may need to be 64
        path = decodeNibbles(path, 0); // lol, so efficient

        RLP.RLPItem[] memory proof = proofRLP.toRlpItem().toList();

        uint8 nodeChildren;
        RLP.RLPItem memory children;

        uint256 pathOffset = 0; // Offset of the proof
        bytes32 nextHash; // Required hash for the next node

        if (proof.length == 0) {
            // Root hash of empty tx trie
            require(rootHash == EMPTY_TRIE_ROOT_HASH, "Bad empty proof");
            return new bytes(0);
        }
        for (uint256 i = 0; i < proof.length; i++) {
            // We use the fact that an rlp encoded list consists of some
            // encoding of its length plus the concatenation of its
            // *rlp-encoded* items.
            if (i == 0) {
                require(rootHash == proof[i].payloadKeccak256(), "Bad first proof part");
            } else {
                require(nextHash == proof[i].payloadKeccak256(), "Bad hash");
            }

            RLP.RLPItem[] memory node = proof[i].payloadRlpItem().toList();

            // Extension or Leaf node
            if (node.length == 2) {
                /*
                // TODO: wtf is a divergent node
                // proof claims divergent extension or leaf
                if (proofIndexes[i] == 0xff) {
                    require(i >= proof.length - 1); // divergent node must come last in proof
                    require(prefixLength != nodePath.length); // node isn't divergent
                    require(pathOffset == path.length); // didn't consume entire path

                    return new bytes(0);
                }

                require(proofIndexes[i] == 1); // an extension/leaf node only has two fields.
                require(prefixLength == nodePath.length); // node is divergent
                */

                bytes memory nodePath = merklePatriciaCompactDecode(node[0].toBytes());
                pathOffset += sharedPrefixLength(pathOffset, path, nodePath);

                // last proof item
                if (i == proof.length - 1) {
                    require(pathOffset == path.length, "Unexpected end of proof (leaf)");
                    return node[1].toBytes(); // Data is the second item in a leaf node
                } else {
                    // not last proof item
                    children = node[1];
                    if (!children.isList()) {
                        nextHash = getNextHash(children);
                    } else {
                        nextHash = children.rlpBytesKeccak256();
                    }
                }
            } else {
                // Must be a branch node at this point
                require(node.length == 17, "Invalid node length");

                if (i == proof.length - 1) {
                    // Proof ends in a branch node, exclusion proof in most cases
                    if (pathOffset + 1 == path.length) {
                        return node[16].toBytes();
                    } else {
                        nodeChildren = extractNibble(path32, pathOffset);
                        children = node[nodeChildren];

                        // Ensure that the next path item is empty, end of exclusion proof
                        require(children.payloadLen() == 0, "Invalid exclusion proof");
                        return new bytes(0);
                    }
                } else {
                    require(pathOffset < path.length, "Continuing branch has depleted path");

                    nodeChildren = extractNibble(path32, pathOffset);
                    children = node[nodeChildren];

                    pathOffset += 1; // advance by one

                    // not last level
                    if (!children.isList()) {
                        nextHash = getNextHash(children);
                    } else {
                        nextHash = children.rlpBytesKeccak256();
                    }
                }
            }
        }

        // no invalid proof should ever reach this point
        assert(false);
    }

    function verifyMultiproof(
        bytes calldata proofRLP, //multiproof map
        bytes calldata accounts,
        bytes32 rootHash
    ) internal pure returns (bool) {
        RLP.RLPItem[] memory trieRlp = proofRLP.toRlpItem().toList();
        RLP.RLPItem[] memory accountsRLP = accounts.toRlpItem().toList();

        if (trieRlp.length == 0) {
            // Root hash of empty tx trie
            require(rootHash == EMPTY_TRIE_ROOT_HASH, "Bad empty proof");
            return true;
        }
        require(accountsRLP.length > 0, "verifyMultiproof: Accounts data cannot be empty");
        require(rootHash == trieRlp[0].payloadKeccak256(), "Bad first proof part");

        /// just logs
        // for (uint256 i = 0; i < accountsRLP.length; i++) {
        //     RLP.RLPItem[] memory acc = accountsRLP[i].toList();
        //     console.log("acc.key");
        //     console.logBytes(acc[0].toBytes());
        //     console.log("acc.value", acc[1].toUint());
        //     RLP.RLPItem[] memory index = acc[2].toList();
        //     for (uint256 j = 0; j < index.length; j++) {
        //         console.log("acc.index", index[j].toUint());
        //     }
        // }

        // console.log("proofRLP.length", trieRlp.length);
        // for (uint256 i = 0; i < trieRlp.length; i++) {
        //     console.log("proofRLP.length", trieRlp[i].isList());
        //     if (trieRlp[i].isList()) {
        //         RLP.RLPItem[] memory level = trieRlp[i].toList();
        //         for (uint256 j = 0; j < level.length; j++) {
        //             console.log("trie.level.index", i, j, level[j].isList());
        //             if (!level[j].isList()) {
        //                 console.logBytes(level[j].toBytes());
        //             }
        //         }
        //     } else {
        //         console.logBytes(trieRlp[i].toBytes());
        //     }
        // }
        ////
        RLP.RLPItem[] memory node = trieRlp[0].payloadRlpItem().toList();

        for (uint256 i = 0; i < accountsRLP.length; i++) {
            RLP.RLPItem[] memory acc = accountsRLP[i].toList();
            RLP.RLPItem[] memory index = acc[2].toList();
            bytes memory path = new bytes(32);
            bytes32 path32 = keccak256(abi.encodePacked(acc[0].toBytes()));
            uint256 pathOffset = 0; // Offset of the proof
            bytes32 nextHash;
            assembly {
                mstore(add(path, 0x20), path32)
            } // careful as path may need to be 64
            path = decodeNibbles(path, 0); // lol, so efficient
            (nextHash, pathOffset) = validateNode(node, pathOffset, path, path32);
            RLP.RLPItem[] memory sub_list = trieRlp[1].toList();
            RLP.RLPItem[] memory sub_node;

            for (uint256 j = 0; j < index.length; j++) {
                sub_node = sub_list[index[j].toUint()].toList();
                sub_list = sub_node[1].toList();
                require(nextHash == sub_node[0].payloadKeccak256(), "Bad hash");
                sub_node = sub_node[0].payloadRlpItem().toList();

                //Last element validate value
                if (j == index.length - 1) {
                    require(
                        validateValue(sub_node, pathOffset, path, path32).toRlpItem().toUint() == acc[1].toUint(),
                        "Wrong state proof"
                    );
                } else {
                    (nextHash, pathOffset) = validateNode(sub_node, pathOffset, path, path32);
                }
            }
        }

        return true;
    }

    function validateNode(RLP.RLPItem[] memory node, uint256 pathOffset, bytes memory path, bytes32 path32)
        internal
        pure
        returns (bytes32, uint256)
    {
        uint8 nodeChildren;
        RLP.RLPItem memory children;
        if (node.length == 2) {
            bytes memory nodePath = merklePatriciaCompactDecode(node[0].toBytes());
            pathOffset += sharedPrefixLength(pathOffset, path, nodePath);
            // not last proof item
            children = node[1];
            if (!children.isList()) {
                return (getNextHash(children), pathOffset);
            } else {
                return (children.rlpBytesKeccak256(), pathOffset);
            }
        } else {
            // Must be a branch node at this point
            require(node.length == 17, "Invalid node length");
            require(pathOffset < path.length, "Continuing branch has depleted path");

            nodeChildren = extractNibble(path32, pathOffset);
            children = node[nodeChildren];

            pathOffset += 1; // advance by one

            // not last level
            if (!children.isList()) {
                return (getNextHash(children), pathOffset);
            } else {
                return (children.rlpBytesKeccak256(), pathOffset);
            }
        }
    }

    function validateValue(RLP.RLPItem[] memory node, uint256 pathOffset, bytes memory path, bytes32 path32)
        internal
        pure
        returns (bytes memory)
    {
        uint8 nodeChildren;
        RLP.RLPItem memory children;
        if (node.length == 2) {
            bytes memory nodePath = merklePatriciaCompactDecode(node[0].toBytes());
            pathOffset += sharedPrefixLength(pathOffset, path, nodePath);

            require(pathOffset == path.length, "Unexpected end of proof (leaf)");
            return node[1].toBytes(); // Data is the second item in a leaf node
        } else {
            // Must be a branch node at this point
            require(node.length == 17, "Invalid node length");
            // Proof ends in a branch node, exclusion proof in most cases
            if (pathOffset + 1 == path.length) {
                return node[16].toBytes();
            } else {
                nodeChildren = extractNibble(path32, pathOffset);
                children = node[nodeChildren];

                // Ensure that the next path item is empty, end of exclusion proof
                require(children.payloadLen() == 0, "Invalid exclusion proof");
                return new bytes(0);
            }
        }
    }

    function getNextHash(RLP.RLPItem memory node) internal pure returns (bytes32 nextHash) {
        (uint256 memPtr, uint256 len) = node.payloadLocation();
        require(len == 32, "Invalid node");

        assembly {
            nextHash := mload(memPtr)
        }
    }

    /*
     * Nibble is extracted as the least significant nibble in the returned byte
     */
    function extractNibble(bytes32 path, uint256 position) internal pure returns (uint8 nibble) {
        require(position < 64, "Invalid nibble position");
        uint8 shifted = position == 0 ? uint8((path >> 4)[0]) : uint8((path << ((position - 1) * 4))[0]);
        return shifted & 0xF;
    }

    function decodeNibbles(bytes memory compact, uint256 skipNibbles) internal pure returns (bytes memory nibbles) {
        require(compact.length > 0, "Empty bytes array");

        uint256 length = compact.length * 2;
        require(skipNibbles <= length, "Skip nibbles amount too large");
        length -= skipNibbles;

        nibbles = new bytes(length);
        uint256 nibblesLength = 0;

        for (uint256 i = skipNibbles; i < skipNibbles + length; i += 1) {
            if (i % 2 == 0) {
                nibbles[nibblesLength] = bytes1((uint8(compact[i / 2]) >> 4) & 0xF);
            } else {
                nibbles[nibblesLength] = bytes1((uint8(compact[i / 2]) >> 0) & 0xF);
            }
            nibblesLength += 1;
        }

        assert(nibblesLength == nibbles.length);
    }

    function merklePatriciaCompactDecode(bytes memory compact) internal pure returns (bytes memory nibbles) {
        require(compact.length > 0, "Empty bytes array");
        uint256 first_nibble = (uint8(compact[0]) >> 4) & 0xF;
        uint256 skipNibbles;
        if (first_nibble == 0) {
            skipNibbles = 2;
        } else if (first_nibble == 1) {
            skipNibbles = 1;
        } else if (first_nibble == 2) {
            skipNibbles = 2;
        } else if (first_nibble == 3) {
            skipNibbles = 1;
        } else {
            // Not supposed to happen!
            revert();
        }
        return decodeNibbles(compact, skipNibbles);
    }

    function sharedPrefixLength(uint256 xsOffset, bytes memory xs, bytes memory ys) internal pure returns (uint256) {
        uint256 i = 0;
        for (i = 0; i + xsOffset < xs.length && i < ys.length; i++) {
            if (xs[i + xsOffset] != ys[i]) {
                return i;
            }
        }
        return i;
    }
}
