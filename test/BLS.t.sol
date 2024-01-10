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
        bytes32 hash = hex"0bc3e989259b75e028b4c1f48869d7df5b895498833055e4712ceb47456e657f";
        uint256 hashA = 5321588316419718329528322900916096709899487454011325194376680874808217331072;
        uint256 hashB = 20651074700241861469236277140614500065048395638626907548294273274972651589218 ;

        // Points you want to test
        Fp2Operations.Fp2Point memory signautre;
        signautre.a = 8248417894161021935012097021863777075505700175036216735484436411859234969386;
        signautre.b = 21244817207967291487820952277580076377055637124701322503036420133524225205523;

        Fp2Operations.G2Point memory pubkey;
        pubkey.x.a = 6437837561756823614678220339003463576238583078419747363903462377522243403622;
        pubkey.x.b = 6798911965122574721594521011503543069893846335413250190506430524184995923991;
        pubkey.y.a = 13567361429375291212448717756378794180355136834025428198612769202597387823263;
        pubkey.y.b = 16073204127664466360426584734663944904786068079319357289600591751615588940088;

        bool result = bls.verify(signautre, hash, 1, hashA, hashB, pubkey);
        assertEq(result, true);
    }
}
