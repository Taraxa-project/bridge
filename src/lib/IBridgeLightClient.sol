// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

interface IBridgeLightClient {
    function getFinalizedBridgeRoot() external view returns (bytes32);
}
