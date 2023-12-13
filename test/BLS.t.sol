// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import { Fp2Operations } from "../src/lib/BLS/fieldOperations/Fp2Operations.sol";
import "../src/BLS.sol";

contract BLSTest is Test {
    SkaleVerifier bls;

    function setUp() public {
        bls = new SkaleVerifier();
    }

    function test_BLS() public {
        bytes32 hash = hex"bcf1bd8b9c273ed797fce99a752f5e7500000000000000000000000000000000";
        uint256 hashA = 918916142008305393327773832817831383916152978314328130130108677793087321243;
        uint256 hashB = 21809021644037900222689279028539685247496835628196906206528993340415255015494 ;

        // Points you want to test
        Fp2Operations.Fp2Point memory signautre;
        signautre.a = 918916142008305393327773832817831383916152978314328130130108677793087321243;
        signautre.b = 21809021644037900222689279028539685247496835628196906206528993340415255015494;

        Fp2Operations.G2Point memory pubkey;
        pubkey.x.a = 11218328751625157287863817574590189054334568585975547743864638913823919155255;
        pubkey.x.b = 18894555884098518668786997936466905087956530132081164710470802187182565676706;
        pubkey.y.a = 21568485053578729080095085561978429492969221482760786953308000752088444293112;
        pubkey.y.b = 3719702853114006559820004608959189052483185874675416334311449109155345327093;

        bool result = bls.verify(signautre, hash, 1, hashA, hashB, pubkey);
        assertEq(result, true);
    }
}
