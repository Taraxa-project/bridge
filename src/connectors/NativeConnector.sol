// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ZeroValueCall} from "../errors/ConnectorErrors.sol";
import "../connectors/TokenConnectorBase.sol";
import "../lib/Constants.sol";

contract NativeConnector is TokenConnectorBase {
    /// Events
    event Locked(address indexed account, uint256 value);

    function initialize(BridgeBase _bridge, address token_on_other_network) public initializer {
        __TokenConnectorBase_init(_bridge, IERC20(Constants.NATIVE_TOKEN_ADDRESS), token_on_other_network);
    }

    /**
     * @dev Applies the given state to the token contract by transfers.
     * @param _state The state to be applied.
     */
    function applyState(bytes calldata _state) external override {
        Transfer[] memory transfers = deserializeTransfers(_state);
        uint256 transfersLength = transfers.length;
        for (uint256 i = 0; i < transfersLength;) {
            (bool success,) = payable(transfers[i].account).call{value: transfers[i].amount}("");
            require(success, "Transfer failed");
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
    function lock(uint256 value) public payable onlySettled(value) {
        uint256 settlementFee = bridge.settlementFee();
        if (msg.value - settlementFee == 0) {
            revert ZeroValueCall();
        }
        state.addAmount(msg.sender, msg.value - settlementFee);
        emit Locked(msg.sender, msg.value - settlementFee);
    }
}
