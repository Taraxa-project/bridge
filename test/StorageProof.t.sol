// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import "beacon-light-client/src/trie/StorageProof.sol";

contract StorageOracleTest is Test {
    function test_verifyStorageProof() public pure {
        address account = 0xdB7d6AB1f17c6b31909aE466702703dAEf9269Cf;
        bytes32 stateRoot = 0x328a4bffe51a6928b12fb0336a8aa64c534aa7331fc59bcbe304b4472ca02398;
        bytes[] memory accountProof = new bytes[](2);
        accountProof[0] =
            hex"f8f1a0be4ffbff395be3f4bdab74fd7a725a903de036aac389cece64120ec0833922e1a09c30d8ff4300b132816e3fd00c81566f786d4e0f89210b98e0bed9fbceea3409a0d235f1cc8bef5e72a917432a09eaa01b155e90569ffd974de79edd63a3c9d8b38080a0a1840bf42c0dd67845195ef8d703229e61e412f61d4a423c097a2584b7770dc280a0265e21b4f091be24eed388d2d95faf81e61c6d6f01a24fdc9533052f34c50c5580a0c3692590e118c8fb5392261db94cc3ddcb4213306fd614e9d1ec26bf92778b66808080a08ab034387e108fb576ec8deaedf083652b28026063a2e2a1e0a34977005cc8a1808080";
        accountProof[1] =
            hex"f869a038f0847834712d0d4a56cc9fd09ca7a91cd58d022e0f3790ef365ae82a471419b846f8440180a001122bba60ba8b736f28e7cb8ccd02a57b8262339fead30a3286c9c0bed346c8a03bb6c927aa8d73f4be3c479e49a5357adc0ff448b5bfea109aaa067d29d6403b";

        uint256 key = 0x7673bcbb3401a7cbae68f81d40eea2cf35afdaf7ecd016ebf3f02857fcc1260a;
        bytes memory v = abi.encodePacked(bytes1(0xc8));
        bytes[] memory storageProof = new bytes[](4);
        storageProof[0] =
            hex"f90211a0143fe733da764456df4e8156a29b342f0395cedebe6f90c9b97d3f47b330a07da0b6d9676841aecaf0140e64259abfe8f5c121fffb86c830d779a22445e20d5ddfa080fc9a9eb4df721c0a96fab15863936757eca601a6ffb6d613402f76523b80f3a0d2aac18e7ac07c668352efe46766207b97c11d4099640758b8602386e4d13a7da0e69ee300db64a6b0ddcaa137e20d22cde7699905b1eae6aaba07cf8438bd4f97a0b0fb54cb13ffb4641f8a442c020915d5bba6eb202af300a2a9b5752a93528d2da0474f0b6e1d71205a9fec7e912e0cf4f08a061c4cbee108e870a29c8118f7c0dfa06a4b3bd73e38d5df04916bb246d49ba04daaba2171ed534fadd75d0a29dd6798a0228c73aa594adbeede620329ee8cf48a37746645a784ed42566f5d0d8b525f3ca04fc19ec51f658891a94397efb32125b96196fd075dfd7c455a09d7dab0bd5bc5a0b5e66510ad58275a346354792c9edf47ec73c27042899905adf6534309335348a00aa9c67929df55ddb8edfc9476f6b3d29cb2e9a8930790b2c62b68f62becc8ffa0dc5c6aca57894e7c5c94142d4e461c9f9cb8fa214453597622689d7382f6f994a09d1a1b48475cf893c14100047779a04f3f4362b2152565f2fcd8c080696f8cb8a0eca6729a44aa835548bcb8412b18ece4a66c4ea6017765a6a4cdd63ab9648da2a07e5ffb40099efbafd3b94a89ac0d89988798c766231bb7b47bdfecf4a011aacf80";
        storageProof[1] =
            hex"f8f18080a0be6aba9ac1c6352f17e80656c7f0b3953ec8ce0e1f2cfb05ef769bfc37d1d77580a0b7b49995dce6c474becec567a6c96c93da7e0990598ac4dc1affbcd3ad452453a0694a30d09362cc00878eaeb2db522beb8d7c2e48a7e9732960f96d8778589e4780a09e9e038f1f2f81d0bb0e1f416f50de622e9fcecadb4197c5c2bdce5088c7aa2380a07100485452d5c384307581a6945a3fa16ffd690725485a5f9bc8aac1c7cac9fda0b07d81107063377c1c211957301caf7fa17445dcf151837d49ecc9bc64e7ff5980a0fb21b3c21a8b1068229c1e1380f327c83bffd17a6036c867839c6eb6552248b880808080";
        storageProof[2] =
            hex"f85180808080808080a0170d5e33d3b82bf6d5bf48a7894af46fcb1db73bd4c4a95016f368c5f3a96b93a092b46918d999f4142ff51b7b92831c3792050c9e7ead05742e798f42056730378080808080808080";
        storageProof[3] = hex"e39f34b3ead87fa915dbd1c2960185919de53b3c7f874e595264e401dc59d23ac08281c8";

        bytes memory value = StorageProof.verify(stateRoot, account, accountProof, bytes32(key), storageProof);
        assertEq(value, v);
    }
}