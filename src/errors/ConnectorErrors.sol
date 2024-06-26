// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

error InsufficientFunds(uint256 expected, uint256 actual);
error TransferFailed(address recipient, uint256 amount);
error RefundFailed(address recipient, uint256 amount);
error InvalidEpoch(uint256 expected, uint256 actual);
error NoClaimAvailable();
error NoFinalizedState();
error StateIsNotEmpty();
error ZeroValueCall();
