// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

import "../lib/SharedStructs.sol";
import "../lib/Constants.sol";
import "../lib/IBridgeLightClient.sol";
import {
    StateNotMatchingBridgeRoot,
    NotSuccessiveEpochs,
    NotEnoughBlocksPassed,
    UnregisteredContract,
    InvalidStateHash,
    UnmatchingContractAddresses,
    ZeroAddressCannotBeRegistered,
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
    bytes32 public bridgeRoot;

    /// gap for upgrade safety <- can be used to add new storage variables(using up to 49  32 byte slots) in new versions of this contract
    /// If used, decrease the number of slots in the next contract that inherits this one(ex. uint256[48] __gap;)
    uint256[49] __gap;

    /// Events
    event StateApplied(bytes indexed state, address indexed receiver, address indexed connector, uint256 refund);
    event Finalized(uint256 indexed epoch, bytes32 bridgeRoot);
    event ConnectorRegistered(address indexed connector);

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
        address contractAddress = connector.getContractAddress();

        if (connectors[address(connector)] != IBridgeConnector(address(0))) {
            return;
        }
        if (contractAddress == address(0)) {
            revert ZeroAddressCannotBeRegistered();
        }

        connectors[contractAddress] = connector;
        localAddress[connector.getBridgedContractAddress()] = connector.getContractAddress();
        tokenAddresses.push(contractAddress);
        emit ConnectorRegistered(contractAddress);
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
        uint256 stateHashLength = state_with_proof.state_hashes.length;
        for (uint256 i = 0; i < stateHashLength;) {
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
            uint256 refund = (used + common / state_with_proof.state_hashes.length);
            connectors[localAddress[state_with_proof.state_hashes[i].contractAddress]].applyStateWithRefund(
                state_with_proof.state.states[i].state, payable(msg.sender), refund
            );
            emit StateApplied(
                state_with_proof.state.states[i].state,
                msg.sender,
                localAddress[state_with_proof.state_hashes[i].contractAddress],
                refund
            );
            unchecked {
                ++i;
            }
        }
        appliedEpoch++;
    }

    function shouldFinalizeEpoch() public view returns (bool) {
        bool shouldFinalize = false;
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            if (!connectors[tokenAddresses[i]].isStateEmpty()) {
                shouldFinalize = true;
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
                finalizationInterval: finalizationInterval
            });
        }
        SharedStructs.ContractStateHash[] memory hashes = new SharedStructs.ContractStateHash[](tokenAddresses.length);

        if (!shouldFinalizeEpoch()) {
            revert NoStateToFinalize();
        }
        for (uint256 i = 0; i < tokenAddresses.length;) {
            hashes[i] = SharedStructs.ContractStateHash(
                tokenAddresses[i], connectors[tokenAddresses[i]].finalize(finalizedEpoch)
            );
            unchecked {
                ++i;
            }
        }
        lastFinalizedBlock = block.number;
        unchecked {
            ++finalizedEpoch;
        }
        bridgeRoot = SharedStructs.getBridgeRoot(finalizedEpoch, hashes);
        emit Finalized(finalizedEpoch, bridgeRoot);
    }

    /**
     * @return ret finalized states with proof for all tokens
     */
    function getStateWithProof() public view returns (SharedStructs.StateWithProof memory ret) {
        ret.state.epoch = finalizedEpoch;
        ret.state.states = new SharedStructs.StateWithAddress[](tokenAddresses.length);
        ret.state_hashes = new SharedStructs.ContractStateHash[](tokenAddresses.length);
        uint256 tokenAddressesLength = tokenAddresses.length;
        for (uint256 i = 0; i < tokenAddressesLength;) {
            bytes memory state = connectors[tokenAddresses[i]].getFinalizedState();
            ret.state_hashes[i] = SharedStructs.ContractStateHash(tokenAddresses[i], keccak256(state));
            ret.state.states[i] = SharedStructs.StateWithAddress(tokenAddresses[i], state);
            unchecked {
                ++i;
            }
        }
    }
}
