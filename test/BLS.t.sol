// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import "../src/BLS.sol";

contract BLSTest is Test {
    BLS bls;

    function setUp() public {
        bls = new BLS();
    }

    function test_BLS() public {
        bytes memory message = hex"4f96e754efe40192b5313b31be527bcf";

        // Points you want to test
        BLS.G1Point memory g1Point;
        g1Point.x = 0x2d0b647a8c86c59b0f302d5ba26ed72306ff7e6f9812f1bad8fa76e62cc96f0;
        g1Point.y = 0x3045868176ea5f8458b7895a09fa78898d6f883e7a80a5ddac793eda3c076480;

        BLS.G2Point memory g2Point;
        g2Point.x[0] = 0x1d1efa58cc19e3fbd797f314fe9a08feab808245f5160559babcf54865ef7f12;
        g2Point.x[1] = 0x13752489f4873c6aaa5aed99fdf0c25aa25b84ad5c8bde740e54ce80aa77c62a;
        g2Point.y[0] = 0x27311d649a07365fc1d376d96dd63ab1b0c30d3b72d9d93cb35e8032a7fe8b7;
        g2Point.y[1] = 0x8b87cb47bb620ce543a00c7ba6bf14049855bc9cadfbb1b4a856ee2e1377c74;

        bool result = bls.verifySignature(g2Point, message, g1Point);
        assertEq(result, true);
    }
}
