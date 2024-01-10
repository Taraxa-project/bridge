pragma solidity ^0.8.17;

import {Precompiled} from "./lib/BLS/Precompiled.sol";
import {Fp2Operations} from "./lib/BLS/fieldOperations/Fp2Operations.sol";
import {G1Operations} from "./lib/BLS/fieldOperations/G1Operations.sol";
import {G2Operations} from "./lib/BLS/fieldOperations/G2Operations.sol";

/**
 * @title BLSVerifier
 * @dev Contains verify function to perform BLS signature verification.
 */
contract BLSVerifier {
    using Fp2Operations for Fp2Operations.Fp2Point;
    using G2Operations for Fp2Operations.G2Point;

    /**
     * @dev Verifies a BLS signature.
     *
     * Requirements:
     *
     * - Signature is in G1.
     * - Hash is in G1.
     * - G2.one in G2.
     * - Public Key in G2.
     */
    function verify(
        Fp2Operations.Fp2Point calldata signature,
        bytes32 hash,
        uint256 counter,
        uint256 hashA,
        uint256 hashB,
        Fp2Operations.G2Point calldata publicKey
    ) external view returns (bool valid) {
        require(G1Operations.checkRange(signature), "Signature is not valid");
        if (!_checkHashToGroupWithHelper(hash, counter, hashA, hashB)) {
            return false;
        }

        uint256 newSignB = G1Operations.negate(signature.b);
        require(
            G1Operations.isG1Point(signature.a, newSignB),
            "Sign not in G1"
        );
        require(G1Operations.isG1Point(hashA, hashB), "Hash not in G1");

        Fp2Operations.G2Point memory g2 = G2Operations.getG2Generator();
        require(G2Operations.isG2(publicKey), "Public Key not in G2");

        return
            Precompiled.bn256Pairing({
                x1: signature.a,
                y1: newSignB,
                a1: g2.x.b,
                b1: g2.x.a,
                c1: g2.y.b,
                d1: g2.y.a,
                x2: hashA,
                y2: hashB,
                a2: publicKey.x.b,
                b2: publicKey.x.a,
                c2: publicKey.y.b,
                d2: publicKey.y.a
            });
    }

    function _checkHashToGroupWithHelper(
        bytes32 hash,
        uint256 counter,
        uint256 hashA,
        uint256 hashB
    ) private pure returns (bool valid) {
        if (counter > 100) {
            return false;
        }
        uint256 xCoord = uint(hash) % Fp2Operations.P;
        xCoord = (xCoord + counter) % Fp2Operations.P;

        uint256 ySquared = addmod(
            mulmod(
                mulmod(xCoord, xCoord, Fp2Operations.P),
                xCoord,
                Fp2Operations.P
            ),
            3,
            Fp2Operations.P
        );
        if (
            hashB < Fp2Operations.P / 2 ||
            mulmod(hashB, hashB, Fp2Operations.P) != ySquared ||
            xCoord != hashA
        ) {
            return false;
        }

        return true;
    }

    function aggregatePublicKey(
        Fp2Operations.G2Point[] memory publicKeys
    ) public returns (Fp2Operations.G2Point memory) {
        Fp2Operations.G2Point memory aggpk;
        for (uint256 i = 0; i < publicKeys.length; i++) {
            aggpk.addG2(publicKeys[i]);
        }
        return aggpk;
    }
}
