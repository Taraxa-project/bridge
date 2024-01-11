// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../src/lib/ILightClient.sol";

contract BridgeLightClientMock is ILightClient {
    bytes32 bridgeRoot;

    function setBridgeRoot(bytes32 _bridgeRoot) public {
        bridgeRoot = _bridgeRoot;
    }

    function getFinalizedBridgeRoot() public view override returns (bytes32) {
        return bridgeRoot;
    }
}
