// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

error StateNotMatchingBridgeRoot(bytes32 stateRoot, bytes32 bridgeRoot);
error ConnectorAlreadyRegistered(address connector, address token);
error NotSuccessiveEpochs(uint256 epoch, uint256 nextEpoch);
error NotEnoughBlocksPassed(uint256 lastFinalizedBlock, uint256 currentInterval, uint256 requiredInterval);
error UnmatchingContractAddresses(address contractAddress, address expectedContractAddress);
error InvalidBridgeRoot(bytes32 bridgeRoot);
error ZeroAddressCannotBeRegistered();
error NoStateToFinalize();
error NotAllStatesApplied(uint256 processed, uint256 total);
