// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import {InsufficientFunds, ZeroValueCall} from "../errors/ConnectorErrors.sol";
import {SharedStructs} from "../lib/SharedStructs.sol";
import {TokenConnectorBase} from "./TokenConnectorBase.sol";
import {BridgeBase} from "../lib/BridgeBase.sol";
import {IERC20MintableBurnable} from "./IERC20MintableBurnable.sol";
import {Transfer} from "../connectors/TokenState.sol";

contract ERC20MintingConnector is TokenConnectorBase {
    /// Events
    event Burned(address indexed account, uint256 value);

    function initialize(BridgeBase _bridge, IERC20MintableBurnable _token, address token_on_other_network)
        public
        initializer
    {
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
            IERC20MintableBurnable(address(token)).mintTo(transfers[i].account, transfers[i].amount);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Burns a specified amount of tokens to transfer them to the other network.
     * @notice The amount of tokens to burn must be approved by the sender
     * @param value The amount of tokens to burn.
     */
    function burn(uint256 value) public payable onlySettled(value) {
        if (value == 0) {
            revert ZeroValueCall();
        }
        IERC20MintableBurnable mintableContract = IERC20MintableBurnable(address(token));
        try mintableContract.burnFrom(msg.sender, value) {
            state.addAmount(msg.sender, value);
            emit Burned(msg.sender, value);
        } catch {
            revert InsufficientFunds({expected: value, actual: 0});
        }
    }
}
