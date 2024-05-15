// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

interface IBridgeLightClient {
    function getFinalizedBridgeRoot(uint256 epoch) external view returns (bytes32);
}
