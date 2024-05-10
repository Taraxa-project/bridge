// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../connectors/NativeConnector.sol";
import "../lib/IBridgeLightClient.sol";
import "../lib/Constants.sol";
import "../lib/BridgeBase.sol";
import "../connectors/ERC20MintingConnector.sol";

contract TaraBridge is BridgeBase {
    constructor(
        IERC20MintableBurnable eth,
        address tara_address_on_eth,
        IBridgeLightClient light_client,
        uint256 finalizationInterval
    ) payable BridgeBase(light_client, finalizationInterval) {
        registerContract(new NativeConnector{value: msg.value / 2}(address(this), tara_address_on_eth));

        registerContract(
            new ERC20MintingConnector{value: msg.value / 2}(address(this), eth, Constants.NATIVE_TOKEN_ADDRESS)
        );
    }
}
