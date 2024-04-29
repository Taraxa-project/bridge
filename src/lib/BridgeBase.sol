// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../lib/SharedStructs.sol";
import "../lib/ILightClient.sol";
import {
    StateNotMatchingBridgeRoot,
    NotSuccessiveEpochs,
    NotEnoughBlocksPassed,
    UnregisteredContract,
    InvalidStateHash,
    UnmatchingContractAddresses
} from "../errors/BridgeBaseErrors.sol";
import "../connectors/IBridgeConnector.sol";
import "forge-std/console.sol";

abstract contract BridgeBase is Ownable {
    IBridgeLightClient public immutable lightClient;

    address[] public tokenAddresses;
    mapping(address => IBridgeConnector) public connectors;
    mapping(address => address) public localAddress;
    uint256 public finalizedEpoch;
    uint256 public appliedEpoch;
    uint256 public finalizationInterval;
    uint256 public lastFinalizedBlock;
    bytes32 public bridgeRoot;

    constructor(IBridgeLightClient light_client, uint256 _finalizationInterval) Ownable() {
        lightClient = light_client;
        finalizationInterval = _finalizationInterval;
    }

    /**
     * @dev Sets the finalization interval.
     * @param _finalizationInterval The finalization interval to be set.
     * @notice Only the owner can call this function.
     */
    function setFinalizationInterval(uint256 _finalizationInterval) public onlyOwner {
        finalizationInterval = _finalizationInterval;
    }

    /**
     * @return An array of addresses of the registered tokens.
     */
    function registeredTokens() public view returns (address[] memory) {
        return tokenAddresses;
    }

    /**
     * @return The bridge root as a bytes32 value.
     */
    function getBridgeRoot() public view returns (bytes32) {
        return bridgeRoot;
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
        if (
            SharedStructs.getBridgeRoot(state_with_proof.state.epoch, state_with_proof.state_hashes)
                != lightClient.getFinalizedBridgeRoot()
        ) {
            revert StateNotMatchingBridgeRoot({
                stateRoot: SharedStructs.getBridgeRoot(state_with_proof.state.epoch, state_with_proof.state_hashes),
                bridgeRoot: lightClient.getFinalizedBridgeRoot()
            });
        }
        if (state_with_proof.state.epoch != appliedEpoch + 1) {
            revert NotSuccessiveEpochs({epoch: appliedEpoch, nextEpoch: state_with_proof.state.epoch});
        }
        uint256 common = (gasleftbefore - gasleft()) * tx.gasprice;
        uint256 stateHashLength = state_with_proof.state_hashes.length;
        for (uint256 i = 0; i < stateHashLength; i++) {
            gasleftbefore = gasleft();
            if (localAddress[state_with_proof.state_hashes[i].contractAddress] == address(0)) {
                revert UnregisteredContract({contractAddress: state_with_proof.state_hashes[i].contractAddress});
            }
            if (keccak256(state_with_proof.state.states[i].state) != state_with_proof.state_hashes[i].stateHash) {
                revert InvalidStateHash({
                    stateHash: keccak256(state_with_proof.state.states[i].state),
                    expectedStateHash: state_with_proof.state_hashes[i].stateHash
                });
            }
            if (state_with_proof.state.states[i].contractAddress != state_with_proof.state_hashes[i].contractAddress) {
                revert UnmatchingContractAddresses({
                    contractAddress: state_with_proof.state.states[i].contractAddress,
                    expectedContractAddress: state_with_proof.state_hashes[i].contractAddress
                });
            }
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
        if (block.number - lastFinalizedBlock < finalizationInterval) {
            revert NotEnoughBlocksPassed({
                lastFinalizedBlock: lastFinalizedBlock,
                finalizationInterval: finalizationInterval
            });
        }
        lastFinalizedBlock = block.number;
        unchecked {
            finalizedEpoch++;
        }
        SharedStructs.ContractStateHash[] memory hashes = new SharedStructs.ContractStateHash[](
                tokenAddresses.length
            );

        uint256 tokenAddressesLength = tokenAddresses.length;
        for (uint256 i = 0; i < tokenAddressesLength; i++) {
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
            uint256 tokenAddressesLength = tokenAddresses.length;
            for (uint256 i = 0; i < tokenAddressesLength; i++) {
                bytes memory state = connectors[tokenAddresses[i]].getFinalizedState();
                ret.state_hashes[i] = SharedStructs.ContractStateHash(tokenAddresses[i], keccak256(state));
                ret.state.states[i] = SharedStructs.StateWithAddress(tokenAddresses[i], state);
            }
        }
    }
}
