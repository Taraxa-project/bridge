// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "../lib/SharedStructs.sol";

interface IBridgeLightClient {
    function getEpochBridgeRoot(uint256 epoch) external view returns (bytes32);
}
