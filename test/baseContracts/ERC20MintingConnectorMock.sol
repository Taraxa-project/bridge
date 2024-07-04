// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {ERC20MintingConnectorLogic} from "../../src/connectors/ERC20MintingConnectorLogic.sol";
import {BridgeBase} from "../../src/lib/BridgeBase.sol";
import {TokenState} from "../../src/connectors/TokenState.sol";

contract ERC20MintingConnectorMock is ERC20MintingConnectorLogic, Ownable {
    constructor(BridgeBase _bridge, IERC20 _token, address token_on_other_network) Ownable(address(_bridge)) {
        otherNetworkAddress = token_on_other_network;
        token = address(_token);
        state = new TokenState(0);
        bridge = _bridge;
    }
}
