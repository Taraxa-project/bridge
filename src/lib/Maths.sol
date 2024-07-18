// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Maths {
    function add(uint256 a, int256 b) internal pure returns (uint256) {
        if (b < 0) {
            if (b == type(int256).min) {
                return a - uint256(b);
            }
            return a - uint256(-b);
        }
        return a + uint256(b);
    }
}
