// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {BeaconLightClient} from "beacon-light-client/src/BeaconLightClient.sol";
import {StorageProof} from "beacon-light-client/src/trie/StorageProof.sol";

import {InvalidBridgeRoot, ZeroAddress} from "../errors/BridgeBaseErrors.sol";
import {IBridgeLightClient} from "../lib/IBridgeLightClient.sol";

/// @custom:oz-upgrades-from EthClient
contract EthClientV2 is IBridgeLightClient, OwnableUpgradeable, UUPSUpgradeable {
    BeaconLightClient public client;
    address public ethBridgeAddress;
    bytes32 public bridgeRootsMappingPosition;

    uint256 public lastEpoch;
    mapping(uint256 => bytes32) bridgeRoots;

    /// gap for upgrade safety <- can be used to add new storage variables(using up to 49  32 byte slots) in new versions of this contract
    /// If used, decrease the number of slots in the next contract that inherits this one(ex. uint256[48] __gap;)
    uint256[49] __gap;

    /// Events
    event BridgeRootProcessed(bytes32 indexed bridgeRoot);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(BeaconLightClient _client, address _eth_bridge_address) public initializer {
        if (_eth_bridge_address == address(0)) {
            revert ZeroAddress("EthBridge");
        }
        if (address(_client) == address(0)) {
            revert ZeroAddress("BeaconLightClient");
        }
        __UUPSUpgradeable_init();
        bridgeRootsMappingPosition = 0x0000000000000000000000000000000000000000000000000000000000000002;
        ethBridgeAddress = _eth_bridge_address;
        client = _client;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @dev Implements the IBridgeLightClient interface method
     * @return The finalized bridge root as a bytes32 value.
     */
    function getFinalizedBridgeRoot(uint256 epoch) external view returns (bytes32) {
        return bridgeRoots[epoch];
    }

    function bridgeRootKeyByEpoch(uint256 epoch) public view returns (bytes32) {
        bytes32 paddedEpoch = bytes32(epoch);
        return keccak256(abi.encodePacked(paddedEpoch, bridgeRootsMappingPosition));
    }

    function setBeaconLightClient(BeaconLightClient _client) external onlyOwner {
        client = _client;
    }

    /**
     * @dev Processes the bridge root by verifying account and storage proofs against state root from the light client.
     * @param account_proof The account proofs for the bridge root.
     * @param storage_proof The storage proofs for the bridge root.
     */
    function processBridgeRoot(bytes[] memory account_proof, bytes[] memory storage_proof) external {
        bytes32 stateRoot = client.merkle_root();
        uint256 epoch = lastEpoch + 1;
        bytes32 bridgeRootKey = bridgeRootKeyByEpoch(epoch);
        bytes memory br = StorageProof.verify(stateRoot, ethBridgeAddress, account_proof, bridgeRootKey, storage_proof);
        bytes32 br32 = bytes32(br);
        if (br.length != 32) {
            revert InvalidBridgeRoot(br32);
        }

        lastEpoch = epoch;
        bridgeRoots[epoch] = br32;
        emit BridgeRootProcessed(bridgeRoots[epoch]);
    }

    /**
     * @dev Returns the Merkle root from the light client.
     * @return The Merkle root as a bytes32 value.
     */
    function getMerkleRoot() external view returns (bytes32) {
        return client.merkle_root();
    }
}
