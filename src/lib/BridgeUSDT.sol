// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BridgeUSDT is ERC20 {
    constructor() ERC20("BridgeUSDT", "USDT") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}
