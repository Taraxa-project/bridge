// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./TokenConnectorBase.sol";
import "../lib/SharedStructs.sol";
import {InsufficientFunds, ZeroValueCall} from "../errors/ConnectorErrors.sol";

contract ERC20LockingConnector is TokenConnectorBase {
    using SafeERC20 for IERC20;
    /// Events

    event Locked(address indexed account, uint256 value);

    function initialize(BridgeBase _bridge, IERC20 _token, address token_on_other_network) public initializer {
        TokenConnectorBase_init(_bridge, _token, token_on_other_network);
    }

    /**
     * @dev Applies the given state to the token contract by transfers.
     * @param _state The state to be applied.
     */
    function applyState(bytes calldata _state) external override {
        Transfer[] memory transfers = deserializeTransfers(_state);
        uint256 transfersLength = transfers.length;
        for (uint256 i = 0; i < transfersLength;) {
            IERC20(token).transfer(transfers[i].account, transfers[i].amount);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Locks the specified amount of tokens to transfer them to the other network.
     * @notice The amount of tokens to burn must be approved by the sender
     * @param value The amount of tokens to lock.
     */
    function lock(uint256 value) public payable onlySettled(value) {
        if (value == 0) {
            revert ZeroValueCall();
        }
        IERC20(token).safeTransferFrom(msg.sender, address(this), value);
        state.addAmount(msg.sender, value);
        emit Locked(msg.sender, value);
    }
}
