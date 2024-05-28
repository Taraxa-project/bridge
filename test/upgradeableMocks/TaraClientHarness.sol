// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {TaraClient} from "../../src/eth/TaraClient.sol";
import {PillarBlock} from "../../src/lib/PillarBlock.sol";

contract TaraClientHarness is TaraClient {
    function processValidatorChangesPublic(PillarBlock.VoteCountChange[] memory validatorChanges) public {
        super.processValidatorChanges(validatorChanges);
    }

    function initializeIt(uint256 _threshold, uint256 _pillarBlockInterval) public initializer {
        super.initialize(_threshold, _pillarBlockInterval);
    }
}
