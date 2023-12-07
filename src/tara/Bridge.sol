// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./BridgeToken.sol";

contract TaraBridge {
    // IERC20 token;
    mapping(bytes32 => TaraBridgeToken) tokens;
    mapping(bytes32 => address) tokenAddress;
    bytes32[] tokens_names;
    address constant tara = address(0);
    mapping(uint256 => bytes32) finalized_state_hash;
    uint256 current_epoch;

    constructor() {
        current_epoch = 0;
        bytes32 name = "TARA";
        tokens[name] = new TaraBridgeToken(address(0), current_epoch);
        tokenAddress[name] = address(0);
        tokens_names.push(name);
    }

    /**
     * @dev Registers a token with the bridge.
     * @param _token The address of the token contract.
     * @param name The name of the token.
     */
    function registerToken(address _token, bytes32 name) public {
        // add some commission for registration here? or should bit be some pool to compensate for processing fees?
        tokenAddress[name] = _token;
        tokens[name] = new TaraBridgeToken(_token, current_epoch);
        tokens_names.push(name);
    }

    /**
     * @dev Transfers a specified amount of tokens.
     * @param name The name of the token.
     * @param amount The amount of tokens to transfer.
     */
    function transferToken(bytes32 name, uint256 amount) public payable {
        IERC20 token = IERC20(tokenAddress[name]);
        if (token.transferFrom(msg.sender, address(this), amount)) {
            tokens[name].addAmount(msg.sender, amount);
        }
        // emit
    }

    /**
     * @dev Transfers Tara tokens.
     * @notice This function allows users to transfer Tara to the contract.
     */
    function transferTara() public payable {
        tokens["TARA"].addAmount(msg.sender, msg.value);
    }

    /**
     * @dev Finalizes the current epoch.
     */
    function finalizeEpoch() public {
        bytes32[] memory hashes = new bytes32[](tokens_names.length);
        for (uint256 i = 0; i < tokens_names.length; i++) {
            hashes[i] = tokens[tokens_names[i]].finalize();
        }
        finalized_state_hash[current_epoch] = keccak256(abi.encode(hashes));
        current_epoch++;
    }

    /**
     * @dev get finalized state of a token.
     * @param name The name of the token.
     * @return The finalized state of the token.
     */
    function getFinalizedState(bytes32 name) public view returns (bytes32, SharedStructs.TokenEpochState memory) {
        return tokens[name].getFinalizedState();
    }

    /**
     * @dev Returns finalized state of all tokens.
     * @return The finalized state of all tokens.
     */
    function getFinalizedStates() public view returns (bytes32[] memory, SharedStructs.TokenEpochState[] memory) {
        bytes32[] memory hashes = new bytes32[](tokens_names.length);
        SharedStructs.TokenEpochState[] memory states = new SharedStructs.TokenEpochState[](tokens_names.length);
        for (uint256 i = 0; i < tokens_names.length; i++) {
            (bytes32 hash, SharedStructs.TokenEpochState memory state) = tokens[tokens_names[i]].getFinalizedState();
            hashes[i] = hash;
            states[i] = state;
        }
        return (hashes, states);
    }

    /**
     * @return ret finalized states with proof for all tokens
     */
    function getStateWithProof() public view returns (SharedStructs.StateWithProof memory ret) {
        ret.proof.token_names = tokens_names;
        ret.proof.state.epoch = current_epoch - 1;
        ret.proof.root_hash = finalized_state_hash[ret.proof.state.epoch];
        (ret.proof.state.hashes, ret.state) = getFinalizedStates();
        return ret;
    }
}
