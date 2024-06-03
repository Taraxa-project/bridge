// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SharedStructs} from "./SharedStructs.sol";

contract RelayerWhitelist is Ownable {
    mapping(address => bool) public registeredTokensToRelay;

    constructor(address[] memory tokenAddresses) Ownable(msg.sender) {
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            registeredTokensToRelay[tokenAddresses[i]] = true;
        }
    }

    function setAddress(address _tokenAddress) public onlyOwner {
        registeredTokensToRelay[_tokenAddress] = true;
    }

    function contains(address _tokenAddress) public view returns (bool) {
        return registeredTokensToRelay[_tokenAddress];
    }
}
