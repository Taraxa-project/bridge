// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "beacon-light-client/src/BeaconLightClient.sol";
import "../lib/StorageProof.sol";

import {InvalidBridgeRoot, NotSuccessiveEpochs} from "../errors/BridgeBaseErrors.sol";
import {IBridgeLightClient} from "../lib/IBridgeLightClient.sol";

contract EthClient is IBridgeLightClient, OwnableUpgradeable {
    BeaconLightClient public client;
    address public ethBridgeAddress;
    uint256 public lastEpoch;
    mapping(uint256 => bytes32) bridgeRoots;

    bytes32 public constant epochKey = 0x0000000000000000000000000000000000000000000000000000000000000004;
    bytes32 public constant bridgeRootKey = 0x0000000000000000000000000000000000000000000000000000000000000008;
    uint256 refund;

    /// gap for upgrade safety <- can be used to add new storage variables(using up to 49  32 byte slots) in new versions of this contract
    /// If used, decrease the number of slots in the next contract that inherits this one(ex. uint256[48] __gap;)
    uint256[49] __gap;

    /// Events
    event BridgeRootProcessed(uint256 indexed epoch, bytes32 indexed bridgeRoot);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(BeaconLightClient _client, address _eth_bridge_address) public initializer {
        require(_eth_bridge_address != address(0), "TaraClient: eth bridge is the zero address");
        require(address(_client) != address(0), "TaraClient: BLC address is the zero address");
        ethBridgeAddress = _eth_bridge_address;
        client = _client;
    }

    /**
     * @dev Implements the IBridgeLightClient interface method
     * @return The finalized bridge root as a bytes32 value.
     */
    function getFinalizedBridgeRoot(uint256 epoch) external view returns (bytes32) {
        return bridgeRoots[epoch];
    }

    /**
     * @dev Processes the bridge root by verifying account and storage proofs against state root from the light client.
     * @param block_number The account proofs for the bridge root.
     * @param account_proof The account proofs for the bridge root.
     * @param epoch_proof The storage proofs for the bridge epoch.
     * @param root_proof The storage proofs for the bridge root.
     */
    function processBridgeRoot(
        uint256 block_number,
        bytes[] memory account_proof,
        bytes[] memory epoch_proof,
        bytes[] memory root_proof
    ) external {
        // add check that the previous root was exactly the one before this
        bytes32 stateRoot = client.merkle_root(block_number);
        bytes32 storageRoot = StorageProof.verifyAccountProof(stateRoot, ethBridgeAddress, account_proof);

        uint256 epoch = uint256(StorageProof.proofStorageValue(storageRoot, epochKey, epoch_proof));
        if (epoch != lastEpoch + 1) {
            revert NotSuccessiveEpochs({epoch: lastEpoch, nextEpoch: epoch});
        }

        bridgeRoots[epoch] = StorageProof.proofStorageValue(storageRoot, bridgeRootKey, root_proof);
        emit BridgeRootProcessed(epoch, bridgeRoots[epoch]);
    }

    /**
     * @dev Returns the Merkle root from the light client.
     * @return The Merkle root as a bytes32 value.
     */
    function getMerkleRoot() external view returns (bytes32) {
        return client.merkle_root();
    }
}
