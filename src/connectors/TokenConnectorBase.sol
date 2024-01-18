// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../lib/SharedStructs.sol";
import "./IBridgeConnector.sol";
import "./TokenState.sol";

abstract contract TokenConnectorBase is IBridgeConnector {
    address token;
    address otherNetworkAddress;
    TokenState state;
    TokenState finalizedState;

    constructor(address _token, address other_network_address) {
        otherNetworkAddress = other_network_address;
        token = _token;
        state = new TokenState(0);
    }

    function epoch() public view returns (uint256) {
        return state.epoch();
    }

    function finalize() public override returns (bytes32) {
        // TODO: destruct the state before overwriting it?
        finalizedState = state;
        state = new TokenState(finalizedState.epoch() + 1);
        return keccak256(abi.encode(finalizedState.getState()));
    }

    /**
     * @dev Retrieves the finalized state of the bridgeable contract.
     * @return A bytes serialized finalized state
     */
    function getFinalizedState() public view override returns (bytes memory) {
        if (address(finalizedState) == address(0)) {
            revert("No finalized state");
        }

        return abi.encode(finalizedState.getState());
    }

    /**
     * @dev Returns the address of the underlying contract in this network
     */
    function getContractAddress() public view returns (address) {
        return address(token);
    }

    /**
     * @dev Returns the address of the bridged contract in the other network
     */
    function getBridgedContractAddress() external view returns (address) {
        return otherNetworkAddress;
    }
}
