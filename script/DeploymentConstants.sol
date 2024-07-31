// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

library EthDeployConstants {
    uint256 constant PILLAR_BLOCK_INTERVAL = 4000;
    uint256 constant FINALIZATION_INTERVAL = 80;
    uint256 constant FEE_MULTIPLIER_FINALIZE = 101;
    uint256 constant FEE_MULTIPLIER_APPLY = 201;
    uint256 constant REGISTRATION_FEE = 0.5 ether;
    uint256 constant SETTLEMENT_FEE = 5 gwei;
}

library TaraDeployConstants {
    uint256 constant FINALIZATION_INTERVAL = EthDeployConstants.PILLAR_BLOCK_INTERVAL;
    uint256 constant FEE_MULTIPLIER_FINALIZE = 105;
    uint256 constant FEE_MULTIPLIER_APPLY = 205;
    uint256 constant REGISTRATION_FEE = 0.5 ether;
    uint256 constant SETTLEMENT_FEE = 500 gwei;
}
