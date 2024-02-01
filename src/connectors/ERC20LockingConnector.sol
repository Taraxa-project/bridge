// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "../lib/SharedStructs.sol";
import "./TokenConnectorBase.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC20LockingConnector is TokenConnectorBase {
    constructor(IERC20 token, address tara_addresss_on_eth) TokenConnectorBase(address(token), tara_addresss_on_eth) {}

    /**
     * @dev Applies the given state to the token contract by transfers.
     * @param _state The state to be applied.
     */
    function applyState(bytes calldata _state) public override {
        Transfer[] memory transfers = deserializeTransfers(_state);
        for (uint256 i = 0; i < transfers.length; i++) {
            IERC20(token).transfer(transfers[i].account, transfers[i].amount);
        }
    }

    /**
     * @dev Locks the specified amount of tokens to transfer them to the other network.
     * @notice The amount of tokens to burn must be approved by the sender
     * @param value The amount of tokens to lock.
     */
    function lock(uint256 value) public {
        IERC20(token).transferFrom(msg.sender, address(this), value);
        state.addAmount(msg.sender, value);
    }
}
