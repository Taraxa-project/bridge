// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import {InsufficientFunds, ZeroValueCall, NoClaimAvailable} from "../errors/ConnectorErrors.sol";
import "../lib/SharedStructs.sol";
import "./TokenConnectorBase.sol";
import "./IERC20MintableBurnable.sol";

contract ERC20MintingConnector is TokenConnectorBase {
    /// Events
    event Burned(address indexed account, uint256 value);

    function initialize(BridgeBase _bridge, IERC20MintableBurnable _token, address token_on_other_network)
        public
        initializer
    {
        try _token.mintTo(address(this), 0) {
            // If the call succeeds, proceed with initialization
            TokenConnectorBase_init(_bridge, _token, token_on_other_network);
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
     * @dev Burns a specified amount of tokens to transfer them to the other network.
     * @notice The amount of tokens to burn must be approved by the sender
     * @param amount The amount of tokens to burn.
     */
    function burn(uint256 amount) public payable onlySettled {
        if (amount == 0) {
            revert ZeroValueCall();
        }
        IERC20MintableBurnable mintableContract = IERC20MintableBurnable(address(token));
        try mintableContract.burnFrom(msg.sender, amount) {
            state.addAmount(msg.sender, amount);
            emit Burned(msg.sender, amount);
        } catch {
            revert InsufficientFunds({expected: amount, actual: 0});
        }
    }
}
