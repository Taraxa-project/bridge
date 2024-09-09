// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import {IERC20MintableBurnable} from "./IERC20MintableBurnable.sol";
import {USDTMintingConnectorLogic} from "./USDTMintingConnectorLogic.sol";

import {Receiver} from "../lib/Receiver.sol";
import {ConnectorUpgradeableBase} from "./ConnectorUpgradeableBase.sol";
import {TokenState} from "../connectors/TokenState.sol";
import {BridgeBase} from "../lib/BridgeBase.sol";

contract USDTMintingConnector is ConnectorUpgradeableBase, Receiver, USDTMintingConnectorLogic {
    function initialize(BridgeBase _bridge, IERC20MintableBurnable _token, address token_on_other_network)
        public
        initializer
    {
        require(
            address(_bridge) != address(0) && address(_token) != address(0) && token_on_other_network != address(0),
            "TokenConnectorBase: invalid bridge, token, or token_on_other_network"
        );
        __ConnectorUpgradeableBase_init(address(_bridge));
        otherNetworkAddress = token_on_other_network;
        token = address(_token);
        state = new TokenState(0);
        bridge = _bridge;
    }
}
