// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {InsufficientFunds, RefundFailed} from "../../src/errors/ConnectorErrors.sol";
import {Transfer} from "../../src/connectors/TokenState.sol";
import {SharedStructs} from "../../src/lib/SharedStructs.sol";
import {NativeConnectorLogic} from "../../src/connectors/NativeConnectorLogic.sol";
import {TokenConnectorLogic} from "../../src/connectors/TokenConnectorLogic.sol";
import {Constants} from "../../src/lib/Constants.sol";
import {TokenState} from "../../src/connectors/TokenState.sol";

contract NativeConnectorMock is NativeConnectorLogic, Ownable {
    constructor(address _bridge, address token_on_other_network) Ownable(msg.sender) {
        otherNetworkAddress = token_on_other_network;
        token = Constants.NATIVE_TOKEN_ADDRESS;
        state = new TokenState(0);
    }
}
