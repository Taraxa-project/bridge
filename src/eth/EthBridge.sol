// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "../lib/SharedStructs.sol";
import "../lib/ILightClient.sol";
import "../connectors/IBridgeConnector.sol";
import "../connectors/ERC20MintingConnector.sol";
import "../lib/TestERC20.sol";
import "../lib/Constants.sol";
import "../lib/BridgeBase.sol";

contract EthBridge is BridgeBase {
    constructor(IERC20MintableBurnable tara, IBridgeLightClient light_client, uint256 finalizationInterval)
        payable
        BridgeBase(light_client, finalizationInterval)
    {
        connectors[address(tara)] = new ERC20MintingConnector{value: msg.value}(
            address(this),
            tara,
            address(tara)
        );
        localAddress[Constants.TARA_PLACEHOLDER] = address(tara);
        tokenAddresses.push(address(tara));
    }
}
