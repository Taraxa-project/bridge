// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

library EthDeployConstants {
    uint256 constant PILLAR_BLOCK_INTERVAL = 4000;
    uint256 constant FINALIZATION_INTERVAL = 80;
    uint256 constant FEE_MULTIPLIER_FINALIZE = 105;
    uint256 constant FEE_MULTIPLIER_APPLY = 205;
    uint256 constant REGISTRATION_FEE = 0.5 ether;
    uint256 constant SETTLEMENT_FEE = 5250000 gwei; // $14 worth of ETH
}

library TaraDeployConstants {
    uint256 constant FINALIZATION_INTERVAL = EthDeployConstants.PILLAR_BLOCK_INTERVAL;
    uint256 constant FEE_MULTIPLIER_FINALIZE = 105;
    uint256 constant FEE_MULTIPLIER_APPLY = 205;
    uint256 constant REGISTRATION_FEE = 275000 ether;
    uint256 constant SETTLEMENT_FEE = 5200 ether; // $23 worth of TARA
}
