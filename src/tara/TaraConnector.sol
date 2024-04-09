// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../connectors/TokenState.sol";
import "../lib/SharedStructs.sol";
import "../connectors/TokenConnectorBase.sol";

contract TaraConnector is TokenConnectorBase {
    constructor(
        address bridge,
        address tara_addresss_on_eth
    ) payable TokenConnectorBase(bridge, address(0), tara_addresss_on_eth) {}

    /**
     * @dev Applies the given state transferring TARA to the specified accounts
     * @param _state The state to be applied.
     * @return accounts Affected accounts that we should split fee between
     */
    function applyState(
        bytes calldata _state
    ) internal override returns (address[] memory accounts) {
        Transfer[] memory transfers = deserializeTransfers(_state);
        accounts = new address[](transfers.length);
        for (uint256 i = 0; i < transfers.length; i++) {
            toClaim[transfers[i].account] += transfers[i].amount;
            // payable(transfers[i].account).transfer(transfers[i].amount);
            accounts[i] = transfers[i].account;
        }
    }

    /**
     * @dev Locks the specified amount of tokens to transfer them to the other network.
     * @notice This function is payable, meaning it can receive TARA.
     */
    function lock() public payable {
        state.addAmount(msg.sender, msg.value);
    }

    function claim() public payable override {
        require(
            msg.value >= feeToClaim[msg.sender],
            "ERC20LockingConnector: insufficient funds to pay fee"
        );
        require(
            toClaim[msg.sender] > 0,
            "ERC20LockingConnector: nothing to claim"
        );
        payable(msg.sender).transfer(toClaim[msg.sender]);
        toClaim[msg.sender] = 0;
    }
}
