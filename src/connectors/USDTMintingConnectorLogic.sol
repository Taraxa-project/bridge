// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import {InsufficientFunds} from "../errors/CommonErrors.sol";
import {ZeroValueCall} from "../errors/ConnectorErrors.sol";

import {Transfer} from "./TokenState.sol";
import {TokenConnectorLogic} from "./TokenConnectorLogic.sol";
import {IERC20MintableBurnable} from "./IERC20MintableBurnable.sol";

abstract contract USDTMintingConnectorLogic is TokenConnectorLogic {
    /// Events
    event Burned(address indexed account, uint256 value);

    /**
     * @dev Applies the given state to the token contract by transfers.
     * @param _state The state to be applied.
     */
    function applyState(bytes calldata _state) public virtual override onlyBridge {
        Transfer[] memory transfers = decodeTransfers(_state);
        uint256 transfersLength = transfers.length;
        for (uint256 i = 0; i < transfersLength; ) {
            uint256 value = transfers[i].amount * 10 ** 12;
            IERC20MintableBurnable(token).mintTo(transfers[i].account, value);
            emit AssetBridged(
                address(this),
                transfers[i].account,
                value
            );
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Burns a specified amount of tokens to transfer them to the other network.
     * @notice The amount of tokens to burn must be approved by the sender
     * @param value The amount of tokens to burn
     */
    function burn(uint256 value) public payable onlySettled {
        if (value == 0) {
            revert ZeroValueCall();
        }
        IERC20MintableBurnable mintableContract = IERC20MintableBurnable(token);
        try mintableContract.burnFrom(msg.sender, value) {
            state.addAmount(msg.sender, value / 10 ** 12);
            emit Burned(msg.sender, value);
        } catch {
            revert InsufficientFunds({expected: value, actual: 0});
        }
    }
}
