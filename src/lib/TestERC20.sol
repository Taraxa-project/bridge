// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/console.sol";

contract TestERC20 is ERC20 {
    constructor(string memory symbol) ERC20(symbol, symbol) {}

    function mintTo(address receiver, uint256 amount) public {
        _mint(receiver, amount);
    }
}
