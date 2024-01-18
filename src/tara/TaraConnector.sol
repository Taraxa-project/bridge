// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../connectors/TokenState.sol";
import "../lib/SharedStructs.sol";
import "../connectors/TokenConnectorBase.sol";
import "forge-std/console.sol";

contract TaraConnector is TokenConnectorBase {
    constructor(address tara_addresss_on_eth) TokenConnectorBase(address(0), tara_addresss_on_eth) {}

    function applyState(bytes calldata _state) public override {
        ERC20State memory s = abi.decode(_state, (ERC20State));
        console.log("Applying state", s.transfers.length);
        for (uint256 i = 0; i < s.transfers.length; i++) {
            console.log("Applying", s.transfers[i].account, s.transfers[i].amount);
            payable(s.transfers[i].account).transfer(s.transfers[i].amount);
        }
    }

    function lock() public payable {
        state.addAmount(msg.sender, msg.value);
    }
}
