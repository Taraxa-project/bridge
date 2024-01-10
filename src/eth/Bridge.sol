// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "../lib/SharedStructs.sol";
import "../lib/IBridgeLightClient.sol";
import "../lib/TestERC20.sol";
import "./BridgeToken.sol";

contract EthBridge {
    mapping(bytes32 => EthBridgeToken) public tokens;
    mapping(bytes32 => address) tokenAddress;
    bytes32[] public token_names;
    IBridgeLightClient light_client;
    IERC20 public tara;

    constructor(IERC20 _tara, IBridgeLightClient _light_client) {
        light_client = _light_client;
        tara = _tara;
        tokens["TARA"] = new EthBridgeToken("TARA", address(tara));
        tokenAddress["TARA"] = address(tara);
        token_names.push("TARA");
    }

    function registerToken(address _token, bytes32 name) public {
        // add some commission for registration here? or should bit be some pool to compensate for processing fees?
        tokenAddress[name] = _token;
        tokens[name] = new EthBridgeToken(name, _token);
    }

    function finalizeEpoch(SharedStructs.StateWithProof calldata state_with_proof) public {
        // get bridge root from light client and compare it (it should be proved there)
        require(
            state_with_proof.proof.root_hash == light_client.getEpochBridgeRoot(state_with_proof.proof.state.epoch),
            "Bridge root hash doesn't match"
        );
        bytes32 state_hash = keccak256(abi.encode(state_with_proof.proof.state));
        require(state_with_proof.proof.root_hash == state_hash, "Invalid root hash in proof");

        for (uint256 i = 0; i < state_with_proof.state.length; i++) {
            EthBridgeToken token = tokens[state_with_proof.proof.token_names[i]];
            token.finalizeState(state_with_proof.state[i], state_with_proof.proof);
        }
    }

    function hashState(SharedStructs.TokenEpochState calldata state) public pure returns (bytes32) {
        return keccak256(abi.encode(state));
    }
}
