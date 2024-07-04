// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

error RefundFailed(address recipient, uint256 amount);
error InvalidEpoch(uint256 expected, uint256 actual);
error NotBridge(address sender);
error NoFinalizedState();
error StateIsNotEmpty();
error ZeroValueCall();
