// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TokenState.sol";
import "../lib/SharedStructs.sol";

contract TaraBridgeToken {
    IERC20 token;
    TaraBridgeState state;
    TaraBridgeState finalized_state;
    bytes32 finalized_state_hash;

    constructor(address _token, uint256 _epoch) {
        token = IERC20(_token);
        state = new TaraBridgeState(_epoch);
    }

    function epoch() public view returns (uint256) {
        return state.epoch();
    }

    function addAmount(address account, uint256 amount) public {
        state.addAmount(account, amount);
    }

    function finalize() public returns (bytes32) {
        finalized_state = state;
        finalized_state_hash = keccak256(abi.encode(finalized_state.getState()));
        state = new TaraBridgeState(finalized_state.epoch() + 1);
        return finalized_state_hash;
    }

    function getFinalizedState() public view returns (bytes32, SharedStructs.TokenEpochState memory) {
        if (address(finalized_state) == address(0)) {
            revert("No finalized state");
        }

        return (finalized_state_hash, finalized_state.getState());
    }
}
