// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ZeroValueCall, TransferFailed} from "../errors/ConnectorErrors.sol";
import {SharedStructs} from "../lib/SharedStructs.sol";
import {TokenConnectorLogic} from "./TokenConnectorLogic.sol";
import {Constants} from "../lib/Constants.sol";
import {Transfer} from "../connectors/TokenState.sol";

abstract contract NativeConnectorLogic is TokenConnectorLogic {
    /// Events
    event Locked(address indexed account, uint256 value);

    /**
     * @dev Applies the given state to the token contract by transfers.
     * @param _state The state to be applied.
     */
    function applyState(bytes calldata _state) public virtual override onlyBridge {
        Transfer[] memory transfers = deserializeTransfers(_state);
        uint256 transfersLength = transfers.length;
        for (uint256 i = 0; i < transfersLength;) {
            (bool success,) = payable(transfers[i].account).call{value: transfers[i].amount}("");
            if (!success) {
                revert TransferFailed(transfers[i].account, transfers[i].amount);
            }
            unchecked {
                ++i;
            }
        }
    }
    
    /**
     * @dev Locks the specified amount of tokens to transfer them to the other network.
     * @notice This function is payable, meaning it can receive TARA.
     * @param value The amount of tokens to lock.
     */
    function lock(uint256 value) public payable onlySettled(value, true) {
        uint256 settlementFee = bridge.settlementFee();
        bool alreadyHasBalance = state.hasBalance(msg.sender);
        uint256 lockedValue;
        lockedValue = alreadyHasBalance ? msg.value : msg.value - settlementFee;

        if (lockedValue == 0 || value == 0) {
            revert ZeroValueCall();
        }
        state.addAmount(msg.sender, lockedValue);
        emit Locked(msg.sender, lockedValue);
    }
}
