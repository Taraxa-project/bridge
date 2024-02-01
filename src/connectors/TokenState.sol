// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../lib/SharedStructs.sol";

struct Transfer {
    address account;
    uint256 amount;
}

struct ERC20State {
    Transfer[] transfers;
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
        Transfer[] memory transfers = new Transfer[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            Transfer memory transfer = Transfer(accounts[i], uint96(balances[accounts[i]]));
            transfers[i] = transfer;
        }
        return transfers;
    }

    function getState() public view returns (ERC20State memory ret) {
        ret.transfers = getTransfers();
        return ret;
    }
}
