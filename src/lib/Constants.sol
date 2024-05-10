// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

library Constants {
    address public constant NATIVE_TOKEN_ADDRESS = address(1);
    bytes public constant EMPTY_BYTES = "";
    bytes32 public constant EMPTY_HASH = keccak256(EMPTY_BYTES);
    uint256 public constant MINIMUM_CONNECTOR_DEPOSIT = 0.001 ether;
}
