// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../src/lib/SharedStructs.sol";
import {
    InsufficientFunds, NoClaimAvailable, TransferFailed, ZeroValueCall
} from "../../src/errors/ConnectorErrors.sol";
import "../../src/connectors/IERC20MintableBurnable.sol";
import "../../src/connectors/ERC20MintingConnectorLogic.sol";
import {TokenConnectorLogic} from "../../src/connectors/TokenConnectorLogic.sol";

contract ERC20MintingConnectorMock is ERC20MintingConnectorLogic, Ownable {
    constructor(address _bridge, IERC20 _token, address token_on_other_network) payable Ownable(msg.sender) {
        if (msg.value < Constants.MINIMUM_CONNECTOR_DEPOSIT) {
            revert InsufficientFunds({expected: Constants.MINIMUM_CONNECTOR_DEPOSIT, actual: msg.value});
        }
        _transferOwnership(_bridge);
        otherNetworkAddress = token_on_other_network;
        token = address(_token);
        state = new TokenState(0);
    }
}
