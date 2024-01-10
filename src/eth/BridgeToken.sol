// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../lib/SharedStructs.sol";

contract EthBridgeToken {
    bytes32 name;
    IERC20 token;
    bytes32 finalized_state_hash;
    uint256 epoch;

    constructor(bytes32 _name, address _token) {
        name = _name;
        token = IERC20(_token);
    }

    function getName() public view returns (bytes32) {
        return name;
    }

    function finalizeState(SharedStructs.TokenEpochState calldata state, SharedStructs.Proof calldata proof) public {
        require(proof.state.epoch == proof.state.epoch, "Invalid epoch");
        require(proof.root_hash == keccak256(abi.encode(proof.state)), "Invalid root hash");
        bytes32 state_hash = keccak256(abi.encode(state));
        // TODO: check exact position from the proof
        bool found = false;
        for (uint256 i = 0; i < proof.state.hashes.length; i++) {
            if (proof.state.hashes[i] == state_hash) {
                found = true;
                break;
            }
        }
        require(found, "State hash not found in proof");

        _finalizeState(state, state_hash);
    }

    function _finalizeState(SharedStructs.TokenEpochState calldata state, bytes32 state_hash) internal {
        finalized_state_hash = state_hash;
        epoch++;
        for (uint256 i = 0; i < state.transfers.length; i++) {
            require(token.transfer(state.transfers[i].account, state.transfers[i].amount), "Transfer failed");
        }
    }
}
