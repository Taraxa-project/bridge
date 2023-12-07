// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "../lib/SharedStructs.sol";
import "../lib/ILightClient.sol";
import "../lib/TestERC20.sol";
import "./BridgeToken.sol";

contract EthBridge {
    mapping(bytes32 => EthBridgeToken) tokens;
    mapping(bytes32 => address) tokenAddress;
    BridgeLightClient light_client;
    TestERC20 public tara;

    constructor() {
        light_client = BridgeLightClient(address(0));
        tara = new TestERC20();
        tara.mint(1000000000000000000000000000);
        tokens["TARA"] = new EthBridgeToken("TARA", address(tara));
        tokenAddress["TARA"] = address(tara);
    }

    function registerToken(address _token, bytes32 name) public {
        // add some commission for registration here? or should bit be some pool to compensate for processing fees?
        tokenAddress[name] = _token;
        tokens[name] = new EthBridgeToken(name, _token);
    }

    function submitTokenState(bytes32 name, SharedStructs.TokenEpochState calldata state) public {
        require(tokens[name] != EthBridgeToken(address(0)), "Token with specified name isn't registered");
        tokens[name].submitState(state);
    }

    function submitStates(bytes32[] calldata token_names, SharedStructs.TokenEpochState[] calldata states) public {
        require(token_names.length == states.length, "Lengths of token_names and states arrays don't match");
        for (uint256 i = 0; i < states.length; i++) {
            submitTokenState(token_names[i], states[i]);
        }
    }

    function finalizeEpoch(SharedStructs.StateWithProof calldata state_with_proof) public {
        // get bridge root from light client and compare it (it should be proved there)
        // require(
        //     state_with_proof.proof.root_hash == light_client.getEpochBridgeRoot(state_with_proof.proof.state.epoch),
        //     "Bridge root hash doesn't match"
        // );
        // bytes32 state_hash = keccak256(abi.encode(state_with_proof.proof.state));
        // require(state_with_proof.proof.root_hash == state_hash, "Invalid root hash in proof");

        for (uint256 i = 0; i < state_with_proof.state.length; i++) {
            EthBridgeToken token = tokens[state_with_proof.proof.token_names[i]];
            token.finalizeStateProof(state_with_proof.state[i], state_with_proof.proof);
        }
    }

    function hashState(SharedStructs.TokenEpochState calldata state) public pure returns (bytes32) {
        return keccak256(abi.encode(state));
    }

    function finalizeTokenWithProof(bytes32 name, SharedStructs.Proof calldata proof) public {
        require(tokens[name] != EthBridgeToken(address(0)), "Token with specified name isn't registered");
        tokens[name].finalizeWithProof(proof);
    }
}
