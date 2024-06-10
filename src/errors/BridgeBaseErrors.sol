// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

error StateNotMatchingBridgeRoot(bytes32 stateRoot, bytes32 bridgeRoot);
error ConnectorAlreadyRegistered(address connector, address token);
error NotSuccessiveEpochs(uint256 epoch, uint256 nextEpoch);
error NotEnoughBlocksPassed(uint256 lastFinalizedBlock, uint256 currentInterval, uint256 requiredInterval);
error UnregisteredContract(address contractAddress);
error InvalidStateHash(bytes32 stateHash, bytes32 expectedStateHash);
error UnmatchingContractAddresses(address contractAddress, address expectedContractAddress);
error TransferFailed(address target, uint256 amount);
error InvalidBridgeRoot(bytes32 bridgeRoot);
error OwnershipOfConnectorNotPassed(address owner);
error ZeroAddressCannotBeRegistered();
error NoStateToFinalize();
