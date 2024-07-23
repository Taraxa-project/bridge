// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ZeroValueCall} from "../errors/ConnectorErrors.sol";
import {TransferFailed, InsufficientFunds} from "../errors/CommonErrors.sol";
import {TokenConnectorLogic} from "./TokenConnectorLogic.sol";
import {Transfer} from "../connectors/TokenState.sol";

abstract contract NativeConnectorLogic is TokenConnectorLogic {
    /// Events
    event Locked(address indexed account, uint256 value);

    /**
     * @dev Applies the given state to the token contract by transfers.
     * @param _state The state to be applied.
     */
    function applyState(bytes calldata _state) public virtual override onlyBridge {
        Transfer[] memory transfers = decodeTransfers(_state);
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
     */
    function lock(uint256 amount) public payable {
        uint256 fee = bridge.settlementFee();
        uint256 lockingValue = msg.value;

        // Charge the fee only if the user has no balance in current state
        if (!state.hasBalance(msg.sender)) {
            if (lockingValue < fee) {
                revert InsufficientFunds(fee, lockingValue);
            }
            lockingValue -= fee;
        }

        if (lockingValue == 0) {
            revert ZeroValueCall();
        }

        state.addAmount(msg.sender, amount);

        if (lockingValue < amount) {
            revert InsufficientFunds(amount, lockingValue);
        } else if (lockingValue > amount) {
            (bool success,) = msg.sender.call{value: lockingValue - amount}("");
            // shouldn't really fail, but just in case
            if (!success) {
                revert TransferFailed(msg.sender, lockingValue - amount);
            }
        }
        emit Locked(msg.sender, amount);
    }
}
