// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../src/lib/ILightClient.sol";
import "../src/lib/SharedStructs.sol";

contract BridgeLightClientMock is IBridgeLightClient {
    bytes32 bridgeRoot;

    function setBridgeRoot(
        SharedStructs.StateWithProof memory state_with_proof
    ) public {
        bridgeRoot = SharedStructs.getBridgeRoot(
            state_with_proof.state.epoch,
            state_with_proof.state_hashes
        );
    }

    function getFinalizedBridgeRoot() public view override returns (bytes32) {
        return bridgeRoot;
    }

    function refundAmount() external pure returns (uint256) {
        return 1 gwei;
    }
}
