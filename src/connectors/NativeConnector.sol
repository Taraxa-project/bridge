// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ConnectorUpgradeableBase} from "./ConnectorUpgradeableBase.sol";
import {Receiver} from "../lib/Receiver.sol";
import {NativeConnectorLogic} from "../connectors/NativeConnectorLogic.sol";
import {Constants} from "../lib/Constants.sol";
import {TokenState} from "./TokenState.sol";
import {BridgeBase} from "../lib/BridgeBase.sol";

contract NativeConnector is ConnectorUpgradeableBase, Receiver, NativeConnectorLogic {
    function initialize(BridgeBase _bridge, address token_on_other_network) public initializer {
        require(
            address(_bridge) != address(0) && address(Constants.NATIVE_TOKEN_ADDRESS) != address(0)
                && token_on_other_network != address(0),
            "TokenConnectorBase: invalid bridge, token, or token_on_other_network"
        );
        __ConnectorUpgradeableBase_init(address(_bridge));
        otherNetworkAddress = token_on_other_network;
        token = address(Constants.NATIVE_TOKEN_ADDRESS);
        state = new TokenState(0);
        bridge = _bridge;
    }
}
