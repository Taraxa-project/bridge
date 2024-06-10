// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {InsufficientFunds, NoClaimAvailable, RefundFailed, ZeroValueCall} from "../errors/ConnectorErrors.sol";
import "../lib/SharedStructs.sol";
import "../connectors/TokenConnectorBase.sol";
import "../lib/Constants.sol";
import "./IERC20MintableBurnable.sol";

contract NativeConnector is TokenConnectorBase {
    /// Events
    event Locked(address indexed account, uint256 value);

    function initialize(BridgeBase _bridge, address token_on_other_network) public initializer {
        try IERC20MintableBurnable(Constants.NATIVE_TOKEN_ADDRESS).mintTo(address(this), 0) {
            // If the call succeeds, proceed with initialization
            __TokenConnectorBase_init(_bridge, IERC20(Constants.NATIVE_TOKEN_ADDRESS), token_on_other_network);
        } catch {
            revert("Provided token does not implement IERC20MintableBurnable");
        }
    }

    /**
     * @dev Applies the given state to the token contract by transfers.
     * @param _state The state to be applied.
     */
    function applyState(bytes calldata _state) external override {
        Transfer[] memory transfers = deserializeTransfers(_state);
        uint256 transfersLength = transfers.length;
        for (uint256 i = 0; i < transfersLength;) {
            IERC20MintableBurnable(address(token)).mintTo(transfers[i].account, transfers[i].amount);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Locks the specified amount of tokens to transfer them to the other network.
     * @notice This function is payable, meaning it can receive TARA.
     */
    function lock() public payable onlySettled {
        if (msg.value == 0) {
            revert ZeroValueCall();
        }
        state.addAmount(msg.sender, msg.value);
        emit Locked(msg.sender, msg.value);
    }
}
