// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error HashesNotMatching(bytes32 expected, bytes32 actual);
error InvalidBlockInterval(uint256 expected, uint256 actual);
error InvalidEpoch(uint256 expected, uint256 actual);
error ThresholdNotMet(uint256 threshold, uint256 weight);
error DuplicateSignatures(address author);
error SignaturesNotSorted();
