// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../../src/lib/SharedStructs.sol";
import {
    InsufficientFunds, TransferFailed, ZeroValueCall
} from "../../src/errors/ConnectorErrors.sol";
import "../../src/connectors/IERC20MintableBurnable.sol";
import "../../src/connectors/ERC20MintingConnectorLogic.sol";
import {TokenConnectorLogic} from "../../src/connectors/TokenConnectorLogic.sol";
import {BridgeBase} from "../../src/lib/BridgeBase.sol";

contract ERC20MintingConnectorMock is ERC20MintingConnectorLogic, Ownable {
    constructor(BridgeBase _bridge, IERC20 _token, address token_on_other_network) Ownable(msg.sender) {
        otherNetworkAddress = token_on_other_network;
        token = address(_token);
        state = new TokenState(0);
        bridge = _bridge;
    }
}
