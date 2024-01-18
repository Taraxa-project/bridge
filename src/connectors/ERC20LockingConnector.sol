// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "../lib/SharedStructs.sol";
import "./TokenConnectorBase.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC20LockingConnector is TokenConnectorBase {
    constructor(IERC20 token, address tara_addresss_on_eth) TokenConnectorBase(address(token), tara_addresss_on_eth) {}

    function applyState(bytes calldata _state) public override {
        ERC20State memory s = abi.decode(_state, (ERC20State));
        for (uint256 i = 0; i < s.transfers.length; i++) {
            IERC20(token).transfer(s.transfers[i].account, s.transfers[i].amount);
        }
    }

    function lock(uint256 value) public {
        IERC20(token).transferFrom(msg.sender, address(this), value);
        state.addAmount(msg.sender, value);
    }
}
