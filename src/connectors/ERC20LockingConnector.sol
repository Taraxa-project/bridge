// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./TokenConnectorBase.sol";
import "../lib/SharedStructs.sol";
import {InsufficientFunds, NoClaimAvailable, TransferFailed} from "../errors/ConnectorErrors.sol";

contract ERC20LockingConnector is TokenConnectorBase {
    /// Events
    event Locked(address indexed account, uint256 value);

    function initialize(address bridge, IERC20 tokenAddress, address token_on_other_network)
        public
        payable
        initializer
    {
        TokenConnectorBase_init(bridge, address(tokenAddress), token_on_other_network);
        emit Initialized(bridge, address(tokenAddress), token_on_other_network);
    }

    /**
     * @dev Applies the given state to the token contract by transfers.
     * @param _state The state to be applied.
     * @return accounts Affected accounts that we should split fee between
     */
    function applyState(bytes calldata _state) internal override returns (address[] memory accounts) {
        Transfer[] memory transfers = deserializeTransfers(_state);
        accounts = new address[](transfers.length);
        uint256 transfersLength = transfers.length;
        for (uint256 i = 0; i < transfersLength;) {
            toClaim[transfers[i].account] += transfers[i].amount;
            accounts[i] = transfers[i].account;
            emit ClaimAccrued(transfers[i].account, transfers[i].amount);
            unchecked {
                ++i;
            }
        }
        emit StateApplied(_state);
    }

    /**
     * @dev Locks the specified amount of tokens to transfer them to the other network.
     * @notice The amount of tokens to burn must be approved by the sender
     * @param value The amount of tokens to lock.
     */
    function lock(uint256 value) public {
        IERC20(token).transferFrom(msg.sender, address(this), value);
        state.addAmount(msg.sender, value);
        emit Locked(msg.sender, value);
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
        emit Claimed(msg.sender, toClaim[msg.sender]);
    }
}
