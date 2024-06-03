// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../lib/SharedStructs.sol";
import {StateIsNotEmpty} from "../errors/ConnectorErrors.sol";

struct Transfer {
    address account;
    uint256 amount;
}

contract TokenState is Ownable {
    uint256 public epoch;
    address[] accounts;
    mapping(address => uint256) balances;

    /// Events
    event TransferAdded(address indexed account, uint256 amount);

    constructor(uint256 _epoch) Ownable(msg.sender) {
        epoch = _epoch;
    }

    function empty() public view returns (bool) {
        return accounts.length == 0;
    }

    function increaseEpoch() public onlyOwner {
        if (!empty()) {
            revert StateIsNotEmpty();
        }
        epoch = epoch + 1;
    }

    function addAmount(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "TokenState: add amount to the zero address");
        if (balances[account] == 0) {
            accounts.push(account);
        }
        balances[account] += amount;
        emit TransferAdded(account, amount);
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
