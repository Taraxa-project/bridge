// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

import {SharedStructs} from "../lib/SharedStructs.sol";
import {Constants} from "../lib/Constants.sol";
import {IBridgeLightClient} from "../lib/IBridgeLightClient.sol";
import {
    ConnectorAlreadyRegistered,
    StateNotMatchingBridgeRoot,
    NotSuccessiveEpochs,
    NotEnoughBlocksPassed,
    ZeroAddressCannotBeRegistered,
    NoStateToFinalize,
    TransferFailed,
    NotAllStatesApplied
} from "../errors/BridgeBaseErrors.sol";
import {InsufficientFunds} from "../errors/ConnectorErrors.sol";
import {IBridgeConnector} from "../connectors/IBridgeConnector.sol";
import {Receiver} from "../connectors/Receiver.sol";

abstract contract BridgeBase is Receiver, OwnableUpgradeable, UUPSUpgradeable {
    /// Mapping of connectors to their source and destination addresses
    mapping(address => IBridgeConnector) public connectors;
    /// Mapping of source and destination addresses to the connector address
    mapping(address => address) public localAddress;
    /// The light client used to get the finalized bridge root
    IBridgeLightClient public lightClient;
    /// The addresses of the registered tokens
    address[] public tokenAddresses;
    /// The epoch of the last finalized epoch
    uint256 public finalizedEpoch;
    /// The epoch of the last applied epoch
    uint256 public appliedEpoch;
    /// The interval between epoch finalizations
    uint256 public finalizationInterval;
    /// The block number of the last finalized epoch
    uint256 public lastFinalizedBlock;
    /// This multiplier is used to calculate the proper part of the relaying cost for bridging actions(state finalization vs aplying state)
    uint256 public feeMultiplier;
    /// Global connector registration fee. Connectors must pay this fee to register
    uint256 public registrationFee;
    /// Global transaction settlement fee. Connector must pay `settlementFee * numberOfTransactions` to settle the transaction
    uint256 public settlementFee;
    /// The bridge root of the last finalized epoch
    bytes32 public bridgeRoot;

    /// gap for upgrade safety <- can be used to add new storage variables(using up to 49  32 byte slots) in new versions of this contract
    /// If used, decrease the number of slots in the next contract that inherits this one(ex. uint256[48] __gap;)
    uint256[49] __gap;

    /// Events
    event Finalized(uint256 indexed epoch, bytes32 bridgeRoot);
    event ConnectorRegistered(
        address indexed connector, address indexed token_source, address indexed token_destination
    );
    event ConnectorDelisted(address indexed connector, uint256 indexed epoch);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function __BridgeBase_init(
        IBridgeLightClient _lightClient,
        uint256 _finalizationInterval,
        uint256 _feeMultiplier,
        uint256 _registrationFee,
        uint256 _settlementFee
    ) internal onlyInitializing {
        __BridgeBase_init_unchained(
            _lightClient, _finalizationInterval, _feeMultiplier, _registrationFee, _settlementFee
        );
    }

    function __BridgeBase_init_unchained(
        IBridgeLightClient _lightClient,
        uint256 _finalizationInterval,
        uint256 _feeMultiplier,
        uint256 _registrationFee,
        uint256 _settlementFee
    ) internal onlyInitializing {
        __UUPSUpgradeable_init();
        __Ownable_init(msg.sender);
        lightClient = _lightClient;
        finalizationInterval = _finalizationInterval;
        feeMultiplier = _feeMultiplier;
        registrationFee = _registrationFee;
        settlementFee = _settlementFee;
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


    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    /**
     * @dev Registers a contract with the EthBridge by providing a connector contract.
     * @param connector The address of the connector contract.
     */
    function registerContract(IBridgeConnector connector) public payable {
        if (msg.value < registrationFee) {
            revert InsufficientFunds(registrationFee, msg.value);
        }

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
        uint256 statesLength = state_with_proof.state.states.length;
        uint256 stateHashIndex = 0;
        uint256 stateIndex = 0;
        while (stateIndex < statesLength) {
            while (stateHashIndex < state_with_proof.state_hashes.length) {
                SharedStructs.ContractStateHash calldata state_hash = state_with_proof.state_hashes[stateHashIndex];
                SharedStructs.StateWithAddress calldata state = state_with_proof.state.states[stateIndex];
                if (localAddress[state_hash.contractAddress] == address(0)) {
                    unchecked {
                        ++stateHashIndex;
                        ++stateIndex;
                    }
                    continue;
                }
                if (keccak256(state.state) != state_hash.stateHash) {
                    unchecked {
                        ++stateHashIndex;
                        ++stateIndex;
                    }
                    continue;
                }
                if (isContract(address(connectors[localAddress[state_hash.contractAddress]]))) {
                    try connectors[localAddress[state_hash.contractAddress]].applyState(state.state) {} catch {}
                } else {}
                unchecked {
                    ++stateHashIndex;
                    ++stateIndex;
                }
            }
        }
        if (stateIndex != statesLength) {
            revert NotAllStatesApplied(stateIndex, statesLength);
        }
        uint256 used = (gasleftbefore - gasleft()) * tx.gasprice;
        uint256 payout = used * feeMultiplier / 100;
        if (address(this).balance >= payout) {
            (bool success,) = payable(msg.sender).call{value: payout}("");
            if (!success) {
                revert TransferFailed(msg.sender, payout);
            }
        } 
        ++appliedEpoch;
    }

    /**
     * @dev Finalizes the current epoch.
     */
    function finalizeEpoch() public {
        uint256 gasleftbefore = gasleft();

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
            uint256 stateLength = c.getStateLength();
            // check if the connector has settlement fee * stateLength
            if (address(c).balance < settlementFee * stateLength) {
                delete connectors[tokenAddresses[i]];
                emit ConnectorDelisted(address(c), finalizedEpoch);
                unchecked {
                    ++i;
                }
                continue;
            }
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
            return;
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
        bridgeRoot = SharedStructs.getBridgeRoot(finalizedEpoch, hashes);

        uint256 used = (gasleftbefore - gasleft()) * tx.gasprice;
        uint256 payout = used * feeMultiplier / 100;
        if (address(this).balance > payout) {
            (bool success,) = payable(msg.sender).call{value: payout}("");
            if (!success) {
                revert TransferFailed(msg.sender, payout);
            }
        } 
        emit Finalized(finalizedEpoch, bridgeRoot);
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
