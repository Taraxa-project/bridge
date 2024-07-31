// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Maths} from "src/lib/Maths.sol";
import {Test, console} from "forge-std/Test.sol";

contract MathsTest is Test {
    function test_basicMaths() public pure {
        vm.assertEq(Maths.add(1, 2), 1 + 2);
        vm.assertEq(Maths.add(10, 2), 10 + 2);
        vm.assertEq(Maths.add(10, -2), 10 - 2);
        vm.assertEq(Maths.add(10, -10), 10 - 10);
        vm.assertEq(Maths.add(10, -8), 10 - 8);
        vm.assertEq(Maths.add(10000, -1500), 10000 - 1500);
        vm.assertEq(Maths.add(10000, 66666), 10000 + 66666);
    }

    function test_failOnOverflow() public {
        vm.expectRevert();
        vm.assertEq(Maths.add(type(uint256).max, 1), 0);
    }

    function test_failOnUnderflow() public {
        vm.expectRevert();
        vm.assertEq(Maths.add(0, -1), 0);
    }

    function test_minMax() public pure {
        vm.assertEq(type(uint256).min, 0);
        vm.assertEq(Maths.add(type(uint256).max, type(int256).min), uint256(type(int256).max));
        vm.assertEq(Maths.add(type(uint256).max, -type(int256).max), uint256(type(int256).max) + 1);
    }
}
