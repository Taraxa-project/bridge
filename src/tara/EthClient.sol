// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "beacon-light-client/src/BeaconLightClient.sol";
import "../lib/StorageProof.sol";

import {InvalidBridgeRoot, NotSuccessiveEpochs} from "../errors/BridgeBaseErrors.sol";
import {IBridgeLightClient} from "../lib/IBridgeLightClient.sol";

contract EthClient is IBridgeLightClient, OwnableUpgradeable {
    BeaconLightClient public beaconClient;
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
        beaconClient = _client;
    }

    /**
     * @dev Implements the IBridgeLightClient interface method
     * @return The finalized bridge root as a bytes32 value.
     */
    function getFinalizedBridgeRoot(uint256 epoch) external view returns (bytes32) {
        return bridgeRoots[epoch];
    }

    /**
     * @dev Upgrades the beacon client to a new instance.
     * @param _client The new beacon client instance.
     * @notice Only the contract owner can call this function.
     */
    function upgradeBeaconClient(BeaconLightClient _client) external onlyOwner {
        beaconClient = _client;
    }

    /**
     * @dev Processes the bridge root by verifying account and storage proofs against state root from the light client.
     * @param account_proof The account proofs for the bridge root.
     * @param epoch_proof The storage proofs for the bridge epoch.
     * @param root_proof The storage proofs for the bridge root.
     */
    function processBridgeRoot(bytes[] memory account_proof, bytes[] memory epoch_proof, bytes[] memory root_proof)
        internal
    {
        // add check that the previous root was exactly the one before this
        bytes32 stateRoot = beaconClient.merkle_root();
        bytes32 storageRoot = StorageProof.verifyAccountProof(stateRoot, ethBridgeAddress, account_proof);

        uint256 epoch = uint256(StorageProof.proveStorageValue(storageRoot, epochKey, epoch_proof));
        // Allow the same epoch to be processed multiple times, so we can update just a header
        if (epoch == lastEpoch) {
            return;
        } else if (epoch != lastEpoch + 1) {
            revert NotSuccessiveEpochs({epoch: lastEpoch, nextEpoch: epoch});
        }

        bridgeRoots[epoch] = StorageProof.proveStorageValue(storageRoot, bridgeRootKey, root_proof);
        emit BridgeRootProcessed(epoch, bridgeRoots[epoch]);
    }

    /**
     * @dev Processes the header with proofs by importing the header and processing the bridge root and epoch.
     * @param header The header to be imported.
     * @param account_proof The account proofs for the bridge root.
     * @param epoch_proof The storage proofs for the bridge epoch.
     * @param root_proof The storage proofs for the bridge root.
     */
    function processHeaderWithProofs(
        BeaconLightClient.FinalizedHeaderUpdate calldata header,
        bytes[] memory account_proof,
        bytes[] memory epoch_proof,
        bytes[] memory root_proof
    ) external {
        beaconClient.import_finalized_header(header);
        processBridgeRoot(account_proof, epoch_proof, root_proof);
    }

    /**
     * @dev Returns the Merkle root from the light client.
     * @return The Merkle root as a bytes32 value.
     */
    function getMerkleRoot() external view returns (bytes32) {
        return beaconClient.merkle_root();
    }

    function import_next_sync_committee(
        BeaconLightClient.FinalizedHeaderUpdate calldata header,
        BeaconLightClient.SyncCommitteePeriodUpdate calldata sc_update
    ) external {
        beaconClient.import_next_sync_committee(header, sc_update);
    }

    function slot() public view returns (uint64) {
        return beaconClient.slot();
    }

    function sync_committee_roots(uint64 period) public view returns (bytes32) {
        return beaconClient.sync_committee_roots(period);
    }
}
