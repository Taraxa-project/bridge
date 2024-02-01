// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

library Constants {
    address public constant TARA_PLACEHOLDER = address(1);
    bytes public constant EMPTY_BYTES = "";
    bytes32 public constant EMPTY_HASH = keccak256(EMPTY_BYTES);
}
