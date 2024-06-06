// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {InvalidEpoch, NoFinalizedState} from "../../src/errors/ConnectorErrors.sol";
import "../../src/lib/SharedStructs.sol";
import "../../src/lib/Constants.sol";
import "./BridgeConnectorBaseMock.sol";
import "../../src/connectors/TokenState.sol";

abstract contract TokenConnectorBaseMock is BridgeConnectorBaseMock {
    address public immutable token;
    address public immutable otherNetworkAddress;
    TokenState state;
    TokenState finalizedState;
    mapping(address => uint256) public toClaim;

    /// Events
    event Finalized(uint256 indexed epoch);
    event ClaimAccrued(address indexed account, uint256 value);
    event Claimed(address indexed account, uint256 value);

    constructor(address bridge, address _token, address token_on_other_network)
        payable
        BridgeConnectorBaseMock(bridge)
    {
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

        // increase epoch if there are no pending transfers
        if (state.empty() && address(finalizedState) != address(0) && finalizedState.empty()) {
            state.increaseEpoch();
            finalizedState.increaseEpoch();
        } else {
            finalizedState = state;
            state = new TokenState(epoch_to_finalize + 1);
        }
        emit Finalized(epoch_to_finalize);
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

        if (finalizedState.empty()) {
            return new bytes(0);
        }
        return finalizedSerializedTransfers();
    }

    /**
     * @dev Returns the address of the underlying contract in this network
     */
    function getContractSource() public view returns (address) {
        return address(token);
    }

    /**
     * @dev Returns the address of the bridged contract on the other network
     */
    function getContractDestination() external view returns (address) {
        return otherNetworkAddress;
    }

    /**
     * @dev Allows the caller to claim tokens by sending Ether to this function to cover fees.
     * This function is virtual and must be implemented by derived contracts.
     */
    function claim() public payable virtual;
}
