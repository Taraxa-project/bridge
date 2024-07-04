// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {NativeConnectorLogic} from "../../src/connectors/NativeConnectorLogic.sol";
import {Constants} from "../../src/lib/Constants.sol";
import {TokenState} from "../../src/connectors/TokenState.sol";
import {BridgeBase} from "../../src/lib/BridgeBase.sol";

contract NativeConnectorMock is NativeConnectorLogic, Ownable {
    constructor(BridgeBase _bridge, address token_on_other_network) Ownable(address(_bridge)) {
        otherNetworkAddress = token_on_other_network;
        token = Constants.NATIVE_TOKEN_ADDRESS;
        state = new TokenState(0);
        bridge = _bridge;
    }
}
