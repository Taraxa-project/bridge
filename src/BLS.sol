// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "./lib/BLS/BN256G1.sol";
import "./lib/BLS/BN256G2.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract BLS {
    using SafeMath for uint256;

    struct G1Point {
        uint256 x;
        uint256 y;
    }

    struct G2Point {
        uint256[2] x;
        uint256[2] y;
    }

    function getG1Generator() internal pure returns (G1Point memory) {
        return G1Point(BN256G1.GX, BN256G1.GY);
    }

    function getG2Generator() internal pure returns (G2Point memory) {
        return G2Point([BN256G2.G2_NEG_X_RE, BN256G2.G2_NEG_X_IM], [BN256G2.G2_NEG_Y_RE, BN256G2.G2_NEG_Y_IM]);
    }

    function hashToG1(bytes calldata _msg) internal pure returns (G1Point memory) {
        (uint256 x, uint256 y) = BN256G1.hashToTryAndIncrement(_msg);
        return G1Point(x, y);
    }

    function verifyPairing(G1Point memory point1, G2Point memory point2) internal returns (bool) {
        G1Point memory g1Generator = getG1Generator();
        G2Point memory g2Generator = getG2Generator();
        return BN256G1.bn256CheckPairing(
            [
                point1.x,
                point1.y,
                point2.x[0],
                point2.x[1],
                point2.y[0],
                point2.y[1],
                g1Generator.x,
                g1Generator.y,
                g2Generator.x[0],
                g2Generator.x[1],
                g2Generator.y[0],
                g2Generator.y[1]
            ]
        );
    }

    function verifySignature(G2Point calldata publicKey, bytes calldata _message, G1Point calldata signature)
        public
        returns (bool)
    {
        return verifyPairing(hashToG1(_message), publicKey) && verifyPairing(signature, getG2Generator());
    }
}
