// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../lib/SharedStructs.sol";

contract EthBridgeToken {
    uint256 constant FINALIZATION_DELAY = 10;

    bytes32 name;
    IERC20 token;
    bytes32 finalized_state_hash;
    uint256 epoch;

    SharedStructs.TokenEpochState epoch_state;
    uint256 block_number;
    bool finalized;

    constructor(bytes32 _name, address _token) {
        name = _name;
        token = IERC20(_token);
    }

    function getName() public view returns (bytes32) {
        return name;
    }

    function submitState(SharedStructs.TokenEpochState calldata state) public {
        require(finalized || block_number == 0, "Previous state not finalized");
        epoch_state = state;
        block_number = block.number;
        finalized = false;
    }

    function getStateHash() internal view returns (bytes32) {
        return keccak256(abi.encode(epoch_state));
    }

    function finalize() public {
        require(block.number >= (block_number + FINALIZATION_DELAY), "State isn't finalized yet");
        _finalize(getStateHash());
        epoch++;
    }

    function finalizeStateProof(SharedStructs.TokenEpochState calldata state, SharedStructs.Proof calldata proof)
        public
    {
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

        finalized = true;
        finalized_state_hash = state_hash;
        epoch++;
        for (uint256 i = 0; i < state.transfers.length; i++) {
            require(token.transfer(state.transfers[i].account, state.transfers[i].amount), "Transfer failed");
        }
    }

    function finalizeWithProof(SharedStructs.Proof calldata proof) public {
        require(epoch == proof.state.epoch, "Invalid epoch");
        require(proof.root_hash == keccak256(abi.encode(proof.state)), "Invalid root hash");
        bytes32 state_hash = getStateHash();
        // TODO: check exact position from the proof
        bool found = false;
        for (uint256 i = 0; i < proof.state.hashes.length; i++) {
            if (proof.state.hashes[i] == state_hash) {
                found = true;
                break;
            }
        }
        require(found, "State hash not found in proof");
        _finalize(state_hash);
    }

    function _processState(SharedStructs.TokenEpochState calldata state) internal {
        for (uint256 i = 0; i < state.transfers.length; i++) {
            bool res = token.transfer(state.transfers[i].account, state.transfers[i].amount);
            require(res, "Transfer failed");
        }
    }

    function _processLocalState() internal {
        for (uint256 i = 0; i < epoch_state.transfers.length; i++) {
            bool res = token.transfer(epoch_state.transfers[i].account, epoch_state.transfers[i].amount);
            require(res, "Transfer failed");
        }
    }

    function _finalize(bytes32 state_hash) internal {
        finalized = true;
        finalized_state_hash = state_hash;
        _processLocalState();
    }
}
