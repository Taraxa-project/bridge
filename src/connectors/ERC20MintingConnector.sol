// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import {InsufficientFunds} from "../errors/ConnectorErrors.sol";
import "../lib/SharedStructs.sol";
import "./TokenConnectorBase.sol";
import "./IERC20MintableBurnable.sol";

contract ERC20MintingConnector is TokenConnectorBase {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// Events
    event Burned(address indexed account, uint256 value);

    function initialize(address bridge, IERC20MintableBurnable tokenAddress, address token_on_other_network)
        public
        initializer
    {
        TokenConnectorBase_init(bridge, address(tokenAddress), token_on_other_network);
        emit Initialized(bridge, address(tokenAddress), token_on_other_network);
    }

    /**
     * @dev Applies the given state to the token contract by transfers.
     * @param _state The state to be applied.
     * @return accounts Affected accounts that we should split fee between
     */
    function applyState(bytes calldata _state) internal override returns (address[] memory accounts) {
        Transfer[] memory transfers = deserializeTransfers(_state);
        accounts = new address[](transfers.length);
        uint256 transfersLength = transfers.length;
        for (uint256 i = 0; i < transfersLength;) {
            toClaim[transfers[i].account] += transfers[i].amount;
            accounts[i] = transfers[i].account;
            emit ClaimAccrued(transfers[i].account, transfers[i].amount);
            unchecked {
                ++i;
            }
        }
        emit StateApplied(_state);
    }

    /**
     * @dev Burns a specified amount of tokens to transfer them to the other network.
     * @notice The amount of tokens to burn must be approved by the sender
     * @param amount The amount of tokens to burn.
     */
    function burn(uint256 amount) public payable {
        IERC20MintableBurnable(token).burnFrom(msg.sender, amount);
        state.addAmount(msg.sender, amount);
        emit Burned(msg.sender, amount);
    }

    /**
     * @dev Allows the caller to claim tokens
     * @notice The caller must send enough Ether to cover the fees.
     */
    function claim() public payable override {
        if (msg.value < feeToClaim[msg.sender]) {
            revert InsufficientFunds({expected: feeToClaim[msg.sender], actual: msg.value});
        }
        uint256 amount = toClaim[msg.sender];
        toClaim[msg.sender] = 0;
        IERC20MintableBurnable(token).mintTo(msg.sender, amount);
        emit Claimed(msg.sender, amount);
    }
}
