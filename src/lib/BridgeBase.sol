// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

import "../lib/SharedStructs.sol";
import "../lib/Constants.sol";
import "../lib/IBridgeLightClient.sol";
import {
    ConnectorAlreadyRegistered,
    StateNotMatchingBridgeRoot,
    NotSuccessiveEpochs,
    NotEnoughBlocksPassed,
    UnmatchingContractAddresses,
    ZeroAddressCannotBeRegistered,
    NotAllStatesApplied,
    NoStateToFinalize
} from "../errors/BridgeBaseErrors.sol";
import {IBridgeConnector} from "../connectors/IBridgeConnector.sol";

abstract contract BridgeBase is OwnableUpgradeable, UUPSUpgradeable {
    mapping(address => IBridgeConnector) public connectors;
    mapping(address => address) public localAddress;
    IBridgeLightClient public lightClient;
    address[] public tokenAddresses;
    uint256 public finalizedEpoch;
    uint256 public appliedEpoch;
    uint256 public finalizationInterval;
    uint256 public lastFinalizedBlock;
    mapping(uint256 => bytes32) public bridgeRoots;

    /// gap for upgrade safety <- can be used to add new storage variables(using up to 49  32 byte slots) in new versions of this contract
    /// If used, decrease the number of slots in the next contract that inherits this one(ex. uint256[48] __gap;)
    uint256[49] __gap;

    /// Events
    event Finalized(uint256 indexed epoch, bytes32 bridgeRoot);
    event ConnectorRegistered(
        address indexed connector, address indexed token_source, address indexed token_destination
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function __BridgeBase_init(IBridgeLightClient light_client, uint256 _finalizationInterval)
        internal
        onlyInitializing
    {
        __BridgeBase_init_unchained(light_client, _finalizationInterval);
    }

    function __BridgeBase_init_unchained(IBridgeLightClient light_client, uint256 _finalizationInterval)
        internal
        onlyInitializing
    {
        __UUPSUpgradeable_init();
        __Ownable_init(msg.sender);
        lightClient = light_client;
        finalizationInterval = _finalizationInterval;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

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
     * @dev Gets the bridge root for the given epoch.
     * @param epoch The epoch for which the bridge root is to be retrieved.
     * @return The bridge root as a bytes32 value.
     */
    function getBridgeRoot(uint256 epoch) public view returns (bytes32) {
        return bridgeRoots[epoch];
    }

    /**
     * @dev Returns the latest bridge root.
     * @dev DO NOT REMOVE! Is used by the node to put it to the pillar block
     * @return The latest bridge root as a bytes32 value.
     */
    function getBridgeRoot() public view returns (bytes32) {
        return bridgeRoots[finalizedEpoch];
    }

    /**
     * @dev Registers a contract with the EthBridge by providing a connector contract.
     * @param connector The address of the connector contract.
     */
    function registerContract(IBridgeConnector connector) public {
        address tokenSrc = connector.getContractSource();
        address tokenDst = connector.getContractDestination();

        if (connectors[address(connector)] != IBridgeConnector(address(0))) {
            return;
        }
        if (tokenSrc == address(0)) {
            revert ZeroAddressCannotBeRegistered();
        }
        if (localAddress[tokenDst] != address(0) || connectors[tokenSrc] != IBridgeConnector(address(0))) {
            revert ConnectorAlreadyRegistered({connector: address(connector), token: tokenSrc});
        }

        connectors[tokenSrc] = connector;
        localAddress[tokenDst] = tokenSrc;
        tokenAddresses.push(tokenSrc);
        emit ConnectorRegistered(address(connector), tokenSrc, tokenDst);
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
                != lightClient.getFinalizedBridgeRoot(state_with_proof.state.epoch)
        ) {
            revert StateNotMatchingBridgeRoot({
                stateRoot: SharedStructs.getBridgeRoot(state_with_proof.state.epoch, state_with_proof.state_hashes),
                bridgeRoot: lightClient.getFinalizedBridgeRoot(state_with_proof.state.epoch)
            });
        }
        if (state_with_proof.state.epoch != appliedEpoch + 1) {
            revert NotSuccessiveEpochs({epoch: appliedEpoch, nextEpoch: state_with_proof.state.epoch});
        }
        uint256 common = (gasleftbefore - gasleft()) * tx.gasprice;
        uint256 statesLength = state_with_proof.state.states.length;
        uint256 stateHashIndex = 0;
        uint256 stateIndex = 0;
        while (stateIndex < statesLength) {
            gasleftbefore = gasleft();
            while (stateHashIndex < state_with_proof.state_hashes.length) {
                SharedStructs.ContractStateHash calldata state_hash = state_with_proof.state_hashes[stateHashIndex];
                SharedStructs.StateWithAddress calldata state = state_with_proof.state.states[stateIndex];
                if (localAddress[state_hash.contractAddress] == address(0)) {
                    unchecked {
                        ++stateHashIndex;
                    }
                    continue;
                }
                if (keccak256(state.state) != state_hash.stateHash) {
                    unchecked {
                        ++stateHashIndex;
                    }
                    continue;
                }
                uint256 used = (gasleftbefore - gasleft()) * tx.gasprice;
                uint256 refund = (used + common / state_with_proof.state_hashes.length);
                connectors[localAddress[state_hash.contractAddress]].applyStateWithRefund(
                    state.state, payable(msg.sender), refund
                );
                unchecked {
                    ++stateHashIndex;
                    ++stateIndex;
                }
            }
        }
        if (stateIndex != statesLength) {
            revert NotAllStatesApplied(stateIndex, statesLength);
        }
        ++appliedEpoch;
    }

    /**
     * @dev Checks whether the current epoch should be finalized.
     * @dev DO NOT REMOVE! Is used by the node to identify if we need to call a finalization
     * @return A boolean value indicating whether the current epoch should be finalized.
     */
    function shouldFinalizeEpoch() public view returns (bool) {
        bool shouldFinalize = false;
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            if (!connectors[tokenAddresses[i]].isStateEmpty()) {
                return true;
            }
        }
        return shouldFinalize;
    }

    /**
     * @dev Finalizes the current epoch.
     */
    function finalizeEpoch() public {
        if (block.number - lastFinalizedBlock < finalizationInterval) {
            revert NotEnoughBlocksPassed({
                lastFinalizedBlock: lastFinalizedBlock,
                currentInterval: block.number - lastFinalizedBlock,
                requiredInterval: finalizationInterval
            });
        }
        SharedStructs.ContractStateHash[] memory hashes = new SharedStructs.ContractStateHash[](tokenAddresses.length);

        uint256 finalizedIndex = 0;
        for (uint256 i = 0; i < tokenAddresses.length;) {
            IBridgeConnector c = connectors[tokenAddresses[i]];
            bool isStateEmpty = c.isStateEmpty();
            bytes32 finalizedHash = c.finalize(finalizedEpoch);
            if (isStateEmpty) {
                ++i;
                continue;
            }
            hashes[finalizedIndex] = SharedStructs.ContractStateHash(tokenAddresses[i], finalizedHash);
            unchecked {
                ++i;
                ++finalizedIndex;
            }
        }

        if (finalizedIndex == 0) {
            revert NoStateToFinalize();
        }

        SharedStructs.ContractStateHash[] memory finalHashes = new SharedStructs.ContractStateHash[](finalizedIndex);
        for (uint256 i = 0; i < finalizedIndex;) {
            finalHashes[i] = hashes[i];
            unchecked {
                ++i;
            }
        }
        lastFinalizedBlock = block.number;
        unchecked {
            ++finalizedEpoch;
        }
        bridgeRoots[finalizedEpoch] = SharedStructs.getBridgeRoot(finalizedEpoch, finalHashes);
        emit Finalized(finalizedEpoch, bridgeRoots[finalizedEpoch]);
    }

    /**
     * @return ret finalized states with proof for all tokens
     */
    function getStateWithProof() public view returns (SharedStructs.StateWithProof memory ret) {
        uint256 proof_idx = 0;
        uint256 tokenAddressesLength = tokenAddresses.length;
        SharedStructs.StateWithAddress[] memory states = new SharedStructs.StateWithAddress[](tokenAddresses.length);
        SharedStructs.ContractStateHash[] memory hashes = new SharedStructs.ContractStateHash[](tokenAddresses.length);
        for (uint256 i = 0; i < tokenAddressesLength;) {
            bytes memory state = connectors[tokenAddresses[i]].getFinalizedState();
            if (state.length == 0) {
                unchecked {
                    ++i;
                }
                continue;
            }
            hashes[proof_idx] = SharedStructs.ContractStateHash(tokenAddresses[i], keccak256(state));
            states[proof_idx] = SharedStructs.StateWithAddress(tokenAddresses[i], state);
            unchecked {
                ++i;
                ++proof_idx;
            }
        }

        ret.state.epoch = finalizedEpoch;
        ret.state.states = new SharedStructs.StateWithAddress[](proof_idx);
        ret.state_hashes = new SharedStructs.ContractStateHash[](proof_idx);
        for (uint256 i = 0; i < proof_idx;) {
            ret.state.states[i] = states[i];
            ret.state_hashes[i] = hashes[i];
            unchecked {
                ++i;
            }
        }
    }
}
