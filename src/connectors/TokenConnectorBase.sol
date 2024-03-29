// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../lib/SharedStructs.sol";
import "../lib/Constants.sol";
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
        state = new TokenState(1);
    }

    function epoch() public view returns (uint256) {
        return state.epoch();
    }

    function deserializeTransfers(bytes memory data) internal pure returns (Transfer[] memory) {
        return abi.decode(data, (Transfer[]));
    }

    function finalizedSerializedTransfers() internal view returns (bytes memory) {
        Transfer[] memory transfers = finalizedState.getTransfers();
        return abi.encode(transfers);
    }

    function finalize(uint256 epoch_to_finalize) public override returns (bytes32) {
        require(epoch_to_finalize == state.epoch(), "Cannot finalize different epoch");
        // TODO: destruct the state before overwriting it?
        finalizedState = state;
        state = new TokenState(epoch_to_finalize + 1);
        return keccak256(finalizedSerializedTransfers());
    }

    /**
     * @dev Retrieves the finalized state of the bridgeable contract.
     * @return A bytes serialized finalized state
     */
    function getFinalizedState() public view override returns (bytes memory) {
        if (address(finalizedState) == address(0)) {
            revert("No finalized state");
        }

        return finalizedSerializedTransfers();
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
