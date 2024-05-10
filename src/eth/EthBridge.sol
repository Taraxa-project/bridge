// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "../connectors/NativeConnector.sol";
import "../lib/IBridgeLightClient.sol";
import "../connectors/IBridgeConnector.sol";
import "../connectors/ERC20MintingConnector.sol";
import "../lib/TestERC20.sol";
import "../lib/Constants.sol";
import "../lib/BridgeBase.sol";

contract EthBridge is BridgeBase {
    constructor(
        IERC20MintableBurnable tara,
        address eth_address_on_tara,
        IBridgeLightClient light_client,
        uint256 finalizationInterval
    ) payable BridgeBase(light_client, finalizationInterval) {
        registerContract(
            new ERC20MintingConnector{value: msg.value / 2}(address(this), tara, Constants.NATIVE_TOKEN_ADDRESS)
        );

        registerContract(new NativeConnector{value: msg.value / 2}(address(this), eth_address_on_tara));
    }
}
