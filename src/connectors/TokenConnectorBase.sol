// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {InvalidEpoch, NoFinalizedState} from "../errors/ConnectorErrors.sol";
import "../lib/SharedStructs.sol";
import "../lib/Constants.sol";
import "./BridgeConnectorBase.sol";
import "./TokenState.sol";

abstract contract TokenConnectorBase is BridgeConnectorBase {
    address public immutable token;
    address public immutable otherNetworkAddress;
    TokenState state;
    TokenState finalizedState;
    mapping(address => uint256) public toClaim;

    constructor(address bridge, address _token, address token_on_other_network) payable BridgeConnectorBase(bridge) {
        otherNetworkAddress = token_on_other_network;
        token = _token;
        state = new TokenState(0);
    }

    function epoch() public view returns (uint256) {
        return state.epoch();
    }

    function deserializeTransfers(bytes memory data) internal pure returns (Transfer[] memory) {
        return abi.decode(data, (Transfer[]));
    }

    function finalizedSerializedTransfers() internal view returns (bytes memory) {
        return abi.encode(finalizedState.getTransfers());
    }

    function isStateEmpty() external view override returns (bool) {
        return state.empty();
    }

    function finalize(uint256 epoch_to_finalize) public override onlyOwner returns (bytes32) {
        if (epoch_to_finalize != state.epoch()) {
            revert InvalidEpoch({expected: state.epoch(), actual: epoch_to_finalize});
        }

        if (state.empty() && address(finalizedState) != address(0) && finalizedState.empty()) {
            state.increaseEpoch();
            finalizedState.increaseEpoch();
            return Constants.EMPTY_HASH;
        }
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
            revert NoFinalizedState();
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

    /**
     * @dev Allows the caller to claim tokens by sending Ether to this function to cover fees.
     * This function is virtual and must be implemented by derived contracts.
     */
    function claim() public payable virtual;
}
