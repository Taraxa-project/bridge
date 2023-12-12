// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../src/lib/IBridgeLightClient.sol";

contract BridgeLightClientMock is IBridgeLightClient {
    mapping(uint256 => bytes32) epochBridgeRoot;

    function setEpochBridgeRoot(uint256 _epoch, bytes32 _epochBridgeRoot) public {
        epochBridgeRoot[_epoch] = _epochBridgeRoot;
    }

    function getEpochBridgeRoot(uint256 _epoch) public view override returns (bytes32) {
        return epochBridgeRoot[_epoch];
    }
}
