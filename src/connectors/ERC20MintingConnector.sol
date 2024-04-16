// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "../lib/SharedStructs.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TokenConnectorBase.sol";
import "./IERC20MintableBurnable.sol";

contract ERC20MintingConnector is TokenConnectorBase {
    constructor(address bridge, IERC20MintableBurnable token, address token_on_other_network)
        payable
        TokenConnectorBase(bridge, address(token), token_on_other_network)
    {}

    /**
     * @dev Applies the given state to the token contract by transfers.
     * @param _state The state to be applied.
     * @return accounts Affected accounts that we should split fee between
     */
    function applyState(bytes calldata _state) internal override returns (address[] memory accounts) {
        Transfer[] memory transfers = deserializeTransfers(_state);
        accounts = new address[](transfers.length);
        for (uint256 i = 0; i < transfers.length; i++) {
            toClaim[transfers[i].account] += transfers[i].amount;
            accounts[i] = transfers[i].account;
        }
    }

    /**
     * @dev Burns a specified amount of tokens to transfer them to the other network.
     * @notice The amount of tokens to burn must be approved by the sender
     * @param amount The amount of tokens to burn.
     */
    function burn(uint256 amount) public payable {
        IERC20MintableBurnable(token).burnFrom(msg.sender, amount);
        state.addAmount(msg.sender, amount);
    }

    /**
     * @dev Allows the caller to claim tokens
     * @notice The caller must send enough Ether to cover the fees.
     */
    function claim() public payable override {
        require(msg.value >= feeToClaim[msg.sender], "ERC20MintingConnector: insufficient funds to pay fee");
        uint256 amount = toClaim[msg.sender];
        toClaim[msg.sender] = 0;
        IERC20MintableBurnable(token).mintTo(msg.sender, amount);
    }
}
