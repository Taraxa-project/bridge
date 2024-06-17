// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {EthClient} from "../../src/tara/EthClient.sol";
import {PillarBlock} from "../../src/lib/PillarBlock.sol";
import {BeaconLightClient} from "beacon-light-client/src/BeaconLightClient.sol";

contract EthClientHarness is EthClient {
    function processBridgeRootPublic(
        bytes[] memory account_proof,
        bytes[] memory epoch_proof,
        bytes[] memory root_proof
    ) public {
        super.processBridgeRoot(account_proof, epoch_proof, root_proof);
    }

    function initializeIt(BeaconLightClient _client, address _eth_bridge_address) public initializer {
        super.initialize(_client, _eth_bridge_address);
    }
}
