// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./TaraConnector.sol";
// import "../connectors/ERC20Connector.sol";
import {console} from "forge-std/console.sol";
import "../lib/ILightClient.sol";

contract TaraBridge {
    IBridgeLightClient public lightClient;

    address[] tokenAddresses;
    mapping(address => IBridgeConnector) public contracts;
    mapping(address => address) public ethTara;
    bytes32 finalizedStateHash;

    constructor(address tara_addresss_on_eth, IBridgeLightClient light_client) {
        lightClient = light_client;
        console.log("TaraBridge constructor", tara_addresss_on_eth);
        contracts[address(1)] = new TaraConnector(tara_addresss_on_eth);
        ethTara[tara_addresss_on_eth] = address(1);
        tokenAddresses.push(address(1));
    }

    /**
     * @dev Registers a contract to be bridged
     * @param connector The IBridgeConnector contract to be registered.
     */
    function registerContract(IBridgeConnector connector) public {
        contracts[connector.getContractAddress()] = connector;
        ethTara[connector.getBridgedContractAddress()] = connector.getContractAddress();
        tokenAddresses.push(connector.getContractAddress());
    }

    /**
     * @dev Applies the given state with proof to the contracts.
     * @param state_with_proof The state with proof to be applied.
     */
    function applyState(SharedStructs.StateWithProof calldata state_with_proof) public {
        // get bridge root from light client and compare it (it should be proved there)
        require(
            keccak256(abi.encode(state_with_proof.state_hashes)) == lightClient.getFinalizedBridgeRoot(),
            "State isn't matching bridge root"
        );

        for (uint256 i = 0; i < state_with_proof.state_hashes.length; i++) {
            require(
                ethTara[state_with_proof.state_hashes[i].contractAddress] != address(0), "Contract is not registered"
            );
            require(
                keccak256(state_with_proof.state.states[i].state) == state_with_proof.state_hashes[i].stateHash,
                "Invalid state hash"
            );
            require(
                state_with_proof.state.states[i].contractAddress == state_with_proof.state_hashes[i].contractAddress,
                "Contract addresses are not matching"
            );
            contracts[ethTara[state_with_proof.state_hashes[i].contractAddress]].applyState(
                state_with_proof.state.states[i].state
            );
        }
    }

    /**
     * @dev Finalizes the current epoch.
     */

    function finalizeEpoch() public {
        SharedStructs.ContractStateHash[] memory hashes = new SharedStructs.ContractStateHash[](tokenAddresses.length);
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            hashes[i] = SharedStructs.ContractStateHash(tokenAddresses[i], contracts[tokenAddresses[i]].finalize());
        }
        finalizedStateHash = keccak256(abi.encode(hashes));
    }

    /**
     * @return ret finalized states with proof for all tokens
     */
    function getStateWithProof() public view returns (SharedStructs.StateWithProof memory ret) {
        ret.state.states = new SharedStructs.StateWithAddress[](tokenAddresses.length);
        ret.state_hashes = new SharedStructs.ContractStateHash[](tokenAddresses.length);
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            bytes memory state = contracts[tokenAddresses[i]].getFinalizedState();
            ret.state_hashes[i] = SharedStructs.ContractStateHash(tokenAddresses[i], keccak256(state));
            ret.state.states[i] = SharedStructs.StateWithAddress(tokenAddresses[i], state);
        }
        return ret;
    }
}
