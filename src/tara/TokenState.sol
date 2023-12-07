// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../lib/SharedStructs.sol";

contract TaraBridgeState {
    uint256 public epoch;
    address[] accounts;
    mapping(address => uint256) balances; // position = 2

    constructor(uint256 _epoch) {
        epoch = _epoch;
    }

    function getBalance(address account) public view returns (uint256) {
        return balances[account];
    }

    function addAmount(address account, uint256 amount) public {
        if (balances[account] == 0) {
            accounts.push(account);
        }
        balances[account] += amount;
    }

    function getTransfers() public view returns (SharedStructs.Transfer[] memory) {
        SharedStructs.Transfer[] memory transfers = new SharedStructs.Transfer[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            SharedStructs.Transfer memory transfer = SharedStructs.Transfer(accounts[i], uint96(balances[accounts[i]]));
            transfers[i] = transfer;
        }
        return transfers;
    }

    function getState() public view returns (SharedStructs.TokenEpochState memory ret) {
        ret.epoch = epoch;
        ret.transfers = getTransfers();
        return ret;
    }
}
