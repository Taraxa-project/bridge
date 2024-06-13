// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {UpgradeableBase} from "./UpgradeableBase.sol";

contract Receiver is UpgradeableBase {
    receive() external payable {}
    
}
