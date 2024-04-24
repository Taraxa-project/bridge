// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "../lib/SharedStructs.sol";
import "../lib/ILightClient.sol";
import "../connectors/IBridgeConnector.sol";
import "forge-std/console.sol";

abstract contract BridgeBase {
    IBridgeLightClient public lightClient;

    address[] public tokenAddresses;
    mapping(address => IBridgeConnector) public connectors;
    mapping(address => address) public localAddress;
    uint256 finalizedEpoch;
    uint256 appliedEpoch;
    bytes32 bridgeRoot;

    constructor(IBridgeLightClient light_client) {
        lightClient = light_client;
    }

    /**
     * @dev Registers a contract with the EthBridge by providing a connector contract.
     * @param connector The address of the connector contract.
     */
    function registerContract(IBridgeConnector connector) public {
        connectors[connector.getContractAddress()] = connector;
        localAddress[connector.getBridgedContractAddress()] = connector.getContractAddress();
        tokenAddresses.push(connector.getContractAddress());
    }

    /**
     * @dev Applies the given state with proof to the contracts.
     * @param state_with_proof The state with proof to be applied.
     */

    function applyState(SharedStructs.StateWithProof calldata state_with_proof) public {
        uint256 gasleftbefore = gasleft();
        // get bridge root from light client and compare it (it should be proved there)
        require(
            SharedStructs.getBridgeRoot(state_with_proof.state.epoch, state_with_proof.state_hashes)
                == lightClient.getFinalizedBridgeRoot(),
            "State does not match bridge root"
        );
        require(state_with_proof.state.epoch == appliedEpoch + 1, "Epochs should be processed sequentially");
        uint256 common = (gasleftbefore - gasleft()) * tx.gasprice;

        for (uint256 i = 0; i < state_with_proof.state_hashes.length; i++) {
            gasleftbefore = gasleft();
            require(
                localAddress[state_with_proof.state_hashes[i].contractAddress] != address(0),
                "Contract is not registered"
            );
            require(
                keccak256(state_with_proof.state.states[i].state) == state_with_proof.state_hashes[i].stateHash,
                "Invalid state hash"
            );
            require(
                state_with_proof.state.states[i].contractAddress == state_with_proof.state_hashes[i].contractAddress,
                "Contract addresses are not matching"
            );
            uint256 used = (gasleftbefore - gasleft()) * tx.gasprice;
            connectors[localAddress[state_with_proof.state_hashes[i].contractAddress]].applyStateWithRefund(
                state_with_proof.state.states[i].state,
                payable(msg.sender),
                (used + common / state_with_proof.state_hashes.length)
            );
        }
        appliedEpoch++;
    }

    /**
     * @dev Finalizes the current epoch.
     */

    function finalizeEpoch() public {
        // TODO: should be called at least every N blocks?
        unchecked {
            finalizedEpoch++;
        }
        SharedStructs.ContractStateHash[] memory hashes = new SharedStructs.ContractStateHash[](
                tokenAddresses.length
            );
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            hashes[i] = SharedStructs.ContractStateHash(
                tokenAddresses[i], connectors[tokenAddresses[i]].finalize(finalizedEpoch)
            );
        }
        bridgeRoot = SharedStructs.getBridgeRoot(finalizedEpoch, hashes);
    }

    /**
     * @return ret finalized states with proof for all tokens
     */
    function getStateWithProof() public view returns (SharedStructs.StateWithProof memory ret) {
        ret.state.epoch = finalizedEpoch;
        ret.state.states = new SharedStructs.StateWithAddress[](
            tokenAddresses.length
        );
        ret.state_hashes = new SharedStructs.ContractStateHash[](
            tokenAddresses.length
        );
        unchecked {
            for (uint256 i = 0; i < tokenAddresses.length; i++) {
                bytes memory state = connectors[tokenAddresses[i]].getFinalizedState();
                ret.state_hashes[i] = SharedStructs.ContractStateHash(tokenAddresses[i], keccak256(state));
                ret.state.states[i] = SharedStructs.StateWithAddress(tokenAddresses[i], state);
            }
        }
    }
}
