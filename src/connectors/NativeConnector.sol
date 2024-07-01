// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {InsufficientFunds, RefundFailed, ZeroValueCall} from "../errors/ConnectorErrors.sol";
import {SharedStructs} from "../lib/SharedStructs.sol";
import {UpgradeableBase} from "./UpgradeableBase.sol";
import {Receiver} from "./Receiver.sol";
import {NativeConnectorLogic} from "../connectors/NativeConnectorLogic.sol";
import {Constants} from "../lib/Constants.sol";
import {TokenState} from "./TokenState.sol";
import {BridgeBase} from "../lib/BridgeBase.sol";

contract NativeConnector is UpgradeableBase, Receiver, NativeConnectorLogic {
    function initialize(BridgeBase _bridge, address token_on_other_network) public initializer {
        require(
            address(_bridge) != address(0) && address(Constants.NATIVE_TOKEN_ADDRESS) != address(0)
                && token_on_other_network != address(0),
            "TokenConnectorBase: invalid bridge, token, or token_on_other_network"
        );
        __BridgeConnectorBase_init(address(_bridge));
        otherNetworkAddress = token_on_other_network;
        token = address(Constants.NATIVE_TOKEN_ADDRESS);
        state = new TokenState(0);
        bridge = _bridge;
    }

}
