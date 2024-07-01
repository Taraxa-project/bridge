// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../src/lib/SharedStructs.sol";
import {Constants} from "../../src/lib/Constants.sol";
import {
    InsufficientFunds, TransferFailed, ZeroValueCall
} from "../../src/errors/ConnectorErrors.sol";
import {ERC20LockingConnectorLogic} from "../../src/connectors/ERC20LockingConnectorLogic.sol";
import {TokenState} from "../../src/connectors/TokenState.sol";
import {BridgeBase} from "../../src/lib/BridgeBase.sol";

contract ERC20LockingConnectorMock is ERC20LockingConnectorLogic, Ownable {
    using SafeERC20 for IERC20;

    constructor(BridgeBase _bridge, IERC20 _token, address token_on_other_network) Ownable(msg.sender) {
        otherNetworkAddress = token_on_other_network;
        token = address(_token);
        state = new TokenState(0);
        bridge = _bridge;
    }
}
