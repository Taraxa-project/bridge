// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../connectors/TokenState.sol";
import "../lib/SharedStructs.sol";
import "../connectors/TokenConnectorBase.sol";

contract TaraConnector is TokenConnectorBase {
    constructor(address tara_addresss_on_eth) TokenConnectorBase(address(0), tara_addresss_on_eth) {}

    /**
     * @dev Applies the given state transferring TARA to the specified accounts
     * @param _state The state to be applied.
     */
    function applyState(bytes calldata _state) public override {
        Transfer[] memory transfers = deserializeTransfers(_state);
        for (uint256 i = 0; i < transfers.length; i++) {
            payable(transfers[i].account).transfer(transfers[i].amount);
        }
    }

    /**
     * @dev Locks the specified amount of tokens to transfer them to the other network.
     * @notice This function is payable, meaning it can receive TARA.
     */
    function lock() public payable {
        state.addAmount(msg.sender, msg.value);
    }
}
