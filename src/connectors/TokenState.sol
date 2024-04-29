// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../lib/SharedStructs.sol";

struct Transfer {
    address account;
    uint256 amount;
}

/// @notice This contract cannot be upgraded because it is not using OpenZeppelin's upgradeable contracts.
/// @dev It is created multiple times in the Logic of the TokenConnectorBase contract, therefore it is redundant to be implemented as an upgradeable contract.
contract TokenState {
    uint256 public immutable epoch;
    address[] accounts;
    mapping(address => uint256) balances; // position = 2

    /// Events
    event TransferAdded(address indexed account, address indexed tokenState, uint256 indexed amount);
    event Initialized(uint256 indexed epoch);

    constructor(uint256 _epoch) {
        epoch = _epoch;
        emit Initialized(_epoch);
    }

    function addAmount(address account, uint256 amount) public {
        if (balances[account] == 0) {
            accounts.push(account);
        }
        balances[account] += amount;
        emit TransferAdded(account, address(this), amount);
    }

    function getTransfers() public view returns (Transfer[] memory) {
        uint256 accountsLength = accounts.length;
        Transfer[] memory transfers = new Transfer[](accountsLength);
        for (uint256 i = 0; i < accountsLength; i++) {
            Transfer memory transfer = Transfer(accounts[i], uint96(balances[accounts[i]]));
            transfers[i] = transfer;
        }
        return transfers;
    }
}
