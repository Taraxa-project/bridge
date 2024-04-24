// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./TokenConnectorBase.sol";
import "../lib/SharedStructs.sol";
import {InsufficientFunds, NoClaimAvailable, TransferFailed} from "../errors/ConnectorErrors.sol";

contract ERC20LockingConnector is TokenConnectorBase {
    constructor(address bridge, IERC20 token, address token_on_other_network)
        payable
        TokenConnectorBase(bridge, address(token), token_on_other_network)
    {}

    /**
     * @dev Applies the given state to the token contract by transfers.
     * @param _state The state to be applied.
     * @return accounts Affected accounts that we should split fee between
     */
    function applyState(bytes calldata _state) internal override returns (address[] memory accounts) {
        Transfer[] memory transfers = deserializeTransfers(_state);
        accounts = new address[](transfers.length);
        unchecked {
            uint256 transfersLength = transfers.length;
            for (uint256 i = 0; i < transfersLength; i++) {
                toClaim[transfers[i].account] += transfers[i].amount;
                accounts[i] = transfers[i].account;
            }
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

    /**
     * @dev Allows the caller to claim tokens
     * @notice The caller must send enough Ether to cover the fees.
     */
    function claim() public payable override {
        if (msg.value < feeToClaim[msg.sender]) {
            revert InsufficientFunds({expected: feeToClaim[msg.sender], actual: msg.value});
        }
        if (toClaim[msg.sender] == 0) {
            revert NoClaimAvailable();
        }
        (bool transferSuccess) = IERC20(token).transfer(msg.sender, toClaim[msg.sender]);
        if (!transferSuccess) {
            revert TransferFailed({recipient: msg.sender, amount: toClaim[msg.sender]});
        }
        toClaim[msg.sender] = 0;
    }
}
