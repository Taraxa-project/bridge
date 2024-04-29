// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {InsufficientFunds, NoClaimAvailable, RefundFailed} from "../errors/ConnectorErrors.sol";
import "../connectors/TokenState.sol";
import "../lib/SharedStructs.sol";
import "../connectors/TokenConnectorBase.sol";

contract TaraConnector is TokenConnectorBase {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// Events
    event Locked(address indexed account, uint256 value);
    event AppliedState(bytes state);

    function initialize(address bridge, address tara_addresss_on_eth) public payable initializer {
        __TokenConnectorBase_init(bridge, address(0), tara_addresss_on_eth);
    }

    /**
     * @dev Applies the given state transferring TARA to the specified accounts
     * @param _state The state to be applied.
     * @return accounts Affected accounts that we should split fee between
     */
    function applyState(bytes calldata _state) internal override returns (address[] memory accounts) {
        Transfer[] memory transfers = deserializeTransfers(_state);
        accounts = new address[](transfers.length);
        uint256 transfersLength = transfers.length;
        for (uint256 i = 0; i < transfersLength; i++) {
            toClaim[transfers[i].account] += transfers[i].amount;
            // payable(transfers[i].account).transfer(transfers[i].amount);
            accounts[i] = transfers[i].account;
            emit ClaimAccrued(transfers[i].account, transfers[i].amount);
        }
        emit AppliedState(_state);
    }

    /**
     * @dev Locks the specified amount of tokens to transfer them to the other network.
     * @notice This function is payable, meaning it can receive TARA.
     */
    function lock() public payable {
        state.addAmount(msg.sender, msg.value);
        emit Locked(msg.sender, msg.value);
    }

    /**
     * @dev Allows the caller to claim tokens
     * @notice The caller must send enough Ether to cover the fees.
     */
    function claim() public payable override {
        if (msg.value > feeToClaim[msg.sender]) {
            revert InsufficientFunds({expected: feeToClaim[msg.sender], actual: msg.value});
        }
        if (toClaim[msg.sender] == 0) {
            revert NoClaimAvailable();
        }
        uint256 fee = toClaim[msg.sender];
        toClaim[msg.sender] = 0;
        (bool success,) = payable(msg.sender).call{value: fee}("");
        if (!success) {
            revert RefundFailed({recipient: msg.sender, amount: fee});
        }
        emit Claimed(msg.sender, fee);
    }
}
