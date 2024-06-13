// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ERC20LockingConnectorLogic} from "./ERC20LockingConnectorLogic.sol";
import {Receiver} from "./Receiver.sol";
import {UpgradeableBase} from "./UpgradeableBase.sol";
import {TokenState} from "./TokenState.sol";
import {BridgeBase} from "../lib/BridgeBase.sol";

contract ERC20LockingConnector is UpgradeableBase, Receiver, ERC20LockingConnectorLogic {
    using SafeERC20 for IERC20;

    function initialize(BridgeBase _bridge, IERC20 tokenAddress, address token_on_other_network)
        public
        payable
        initializer
    {
        require(
            address(_bridge) != address(0) && address(tokenAddress) != address(0) && token_on_other_network != address(0),
            "TokenConnectorBase: invalid bridge, token, or token_on_other_network"
        );
        __BridgeConnectorBase_init(address(_bridge));
        otherNetworkAddress = token_on_other_network;
        token = address(tokenAddress);
        state = new TokenState(0);
        bridge = _bridge;
    }
}
