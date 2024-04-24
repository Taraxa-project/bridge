// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../lib/SharedStructs.sol";

struct Transfer {
    address account;
    uint256 amount;
}

contract TokenState {
    uint256 public epoch;
    address[] accounts;
    mapping(address => uint256) balances; // position = 2

    constructor(uint256 _epoch) {
        epoch = _epoch;
    }

    function addAmount(address account, uint256 amount) public {
        if (balances[account] == 0) {
            accounts.push(account);
        }
        balances[account] += amount;
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
