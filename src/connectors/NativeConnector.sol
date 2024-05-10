// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {InsufficientFunds, NoClaimAvailable, RefundFailed} from "../errors/ConnectorErrors.sol";
import "../connectors/TokenState.sol";
import "../lib/SharedStructs.sol";
import "../connectors/TokenConnectorBase.sol";

contract NativeConnector is TokenConnectorBase {
    constructor(address bridge, address token_on_other_network)
        payable
        TokenConnectorBase(bridge, Constants.NATIVE_TOKEN_ADDRESS, token_on_other_network)
    {}

    /**
     * @dev Applies the given state transferring TARA to the specified accounts
     * @param _state The state to be applied.
     * @return accounts Affected accounts that we should split fee between
     */
    function applyState(bytes calldata _state) internal override returns (address[] memory accounts) {
        Transfer[] memory transfers = deserializeTransfers(_state);
        accounts = new address[](transfers.length);
        uint256 transfersLength = transfers.length;
        for (uint256 i = 0; i < transfersLength; i++) {
            toClaim[transfers[i].account] += transfers[i].amount;
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

    /**
     * @dev Allows the caller to claim tokens
     * @notice The caller must send enough Ether to cover the fees.
     */
    function claim() public payable override {
        if (msg.value > feeToClaim[msg.sender]) {
            revert InsufficientFunds({expected: feeToClaim[msg.sender], actual: msg.value});
        }
        if (toClaim[msg.sender] == 0) {
            revert NoClaimAvailable();
        }
        uint256 fee = toClaim[msg.sender];
        toClaim[msg.sender] = 0;
        (bool success,) = payable(msg.sender).call{value: fee}("");
        if (!success) {
            revert RefundFailed({recipient: msg.sender, amount: fee});
        }
    }
}
