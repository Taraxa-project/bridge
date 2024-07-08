// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IBridgeLightClient} from "../../src/lib/IBridgeLightClient.sol";
import {SharedStructs} from "../../src/lib/SharedStructs.sol";

contract BridgeLightClientMock is IBridgeLightClient {
    bytes32 bridgeRoot;

    function setBridgeRoot(SharedStructs.StateWithProof memory state_with_proof) public {
        bridgeRoot = SharedStructs.getBridgeRoot(state_with_proof.state.epoch, state_with_proof.state_hashes);
    }

    function getFinalizedBridgeRoot(uint256) public view override returns (bytes32) {
        return bridgeRoot;
    }

    function refundAmount() external pure returns (uint256) {
        return 1 gwei;
    }
}

contract BeaconClientMock {
    bytes32 merkleRoot;

    function set_merkle_root(bytes32 root) external {
        merkleRoot = root;
    }

    function merkle_root(uint256) external view returns (bytes32) {
        return merkleRoot;
    }

    function merkle_root() external view returns (bytes32) {
        return merkleRoot;
    }
}
