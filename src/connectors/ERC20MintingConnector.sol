// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "../lib/SharedStructs.sol";
import "./TokenConnectorBase.sol";
import "./IERC20MintableBurnable.sol";

contract ERC20MintingConnector is TokenConnectorBase {
    constructor(IERC20MintableBurnable token, address other_network_address)
        TokenConnectorBase(address(token), other_network_address)
    {}

    function applyState(bytes calldata _state) public override {
        ERC20State memory s = abi.decode(_state, (ERC20State));
        for (uint256 i = 0; i < s.transfers.length; i++) {
            IERC20MintableBurnable(token).mintTo(s.transfers[i].account, s.transfers[i].amount);
        }
    }

    function burn(uint256 amount) public payable {
        require(
            IERC20MintableBurnable(token).allowance(msg.sender, address(this)) == amount,
            "allowance not equal to amount"
        );
        IERC20MintableBurnable(token).burnFrom(msg.sender, amount);
        state.addAmount(msg.sender, amount);
    }
}
