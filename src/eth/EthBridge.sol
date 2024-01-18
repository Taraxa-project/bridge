// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "../lib/SharedStructs.sol";
import "../lib/ILightClient.sol";
import "../connectors/IBridgeConnector.sol";
import "../connectors/ERC20MintingConnector.sol";
import "../lib/TestERC20.sol";

contract EthBridge {
    IBridgeLightClient public lightClient;

    address[] public tokenAddresses;
    mapping(address => IBridgeConnector) public contracts;
    mapping(address => address) public taraEth;
    bytes32 finalized_state_hash;

    constructor(IERC20MintableBurnable tara, IBridgeLightClient light_client) {
        lightClient = light_client;
        contracts[address(tara)] = new ERC20MintingConnector(tara, address(tara));
        taraEth[address(1)] = address(tara);
        tokenAddresses.push(address(tara));
    }

    function registerContract(IBridgeConnector connector) public {
        contracts[connector.getContractAddress()] = connector;
        taraEth[connector.getBridgedContractAddress()] = connector.getContractAddress();
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
                taraEth[state_with_proof.state_hashes[i].contractAddress] != address(0), "Contract is not registered"
            );
            require(
                keccak256(state_with_proof.state.states[i].state) == state_with_proof.state_hashes[i].stateHash,
                "Invalid state hash"
            );
            require(
                state_with_proof.state.states[i].contractAddress == state_with_proof.state_hashes[i].contractAddress,
                "Contract addresses are not matching"
            );
            contracts[taraEth[state_with_proof.state_hashes[i].contractAddress]].applyState(
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
        finalized_state_hash = keccak256(abi.encode(hashes));
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
