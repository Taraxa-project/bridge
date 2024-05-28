// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BridgeDoge is ERC20 {
    constructor() ERC20("BridgeDoge", "DOGE") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}
