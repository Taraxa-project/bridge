// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import "../src/eth/TaraClient.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Utils.sol";

/**
 * @title Taraxa Client-side test contract
 * @author @kstdl
 * @notice Tests all relevant units of the TaraClient.sol contract
 * Invariants:
 *  - at any given time the total weight should be the sum of all individual pillar block  vote weights
 *  - once a block is finalized, regardless of what method is called, it should stay finalized
 *  - the finalizedBlock should always be registered before the next pending block
 */
contract TaraClientTest is Test {
    TaraClient client;
    PillarBlock.WithChanges currentBlock;

    function setUp() public {
        PillarBlock.WeightChange[]
            memory initial = new PillarBlock.WeightChange[](10);
        for (uint256 i = 0; i < initial.length; i++) {
            bytes32 pk = keccak256(abi.encodePacked(i));
            initial[i] = PillarBlock.WeightChange(vm.addr(uint256(pk)), 20);
        }
        client = new TaraClient(initial, 100, 10);
        currentBlock = PillarBlock.WithChanges(
            PillarBlock.FinalizationData(1, bytes32(0), bytes32(0), bytes32(0)),
            new PillarBlock.WeightChange[](0)
        );
    }

    function getCompactSig(
        bytes32 pk,
        bytes32 h
    ) public pure returns (CompactSignature memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(uint256(pk), h);
        if (v >= 27) {
            v -= 27;
        }

        return CompactSignature(r, (bytes32(uint256(v)) << 255) | s);
    }

    function getSignatures(
        uint32 count
    ) public view returns (CompactSignature[] memory signatures) {
        signatures = new CompactSignature[](count);
        for (uint32 i = 0; i < count; i++) {
            bytes32 pk = keccak256(abi.encodePacked(uint256(i)));
            CompactSignature memory sig = getCompactSig(
                pk,
                PillarBlock.getVoteHash(currentBlock)
            );
            signatures[uint256(i)] = sig;
        }
    }

    function getTotalWeight(
        PillarBlock.WithChanges memory validatorBlock
    ) public returns (int256 totalWeight) {
        totalWeight = 0;
        for (uint256 i = 0; i < validatorBlock.validatorChanges.length; i++) {
            totalWeight += validatorBlock.validatorChanges[i].change;
        }
        return totalWeight;
    }

    function test_signatures() public {
        uint32 signatures_count = 200;
        int256 weight = client.getSignaturesWeight(
            PillarBlock.getVoteHash(currentBlock),
            getSignatures(signatures_count)
        );
        assertEq(weight, int256(uint256(signatures_count)));
    }

    function test_blockAccept() public {
        client.finalizeBlock(abi.encode(currentBlock), getSignatures(200));
        (bytes32 blockHash, , uint256 finalizedAt) = client.finalized();
        assertEq(blockHash, PillarBlock.getHash(currentBlock));
        assertEq(finalizedAt, block.number);
    }

    function test_weightChanges() public {
        PillarBlock.WeightChange[]
            memory changes = new PillarBlock.WeightChange[](20);
        for (uint256 i = 0; i < changes.length; i++) {
            bytes32 pk = keccak256(abi.encodePacked(i));
            changes[i] = PillarBlock.WeightChange(vm.addr(uint256(pk)), 10);
        }
        client.setThreshold(1);
        client.processValidatorChanges(changes);
    }

    function invariant_optimisticAccept() public {
        vm.roll(100);
        currentBlock.block.prevHash = PillarBlock.getHash(client.getPending());
        client.addPendingBlock(abi.encode(currentBlock));

        // invariant tests - the finalized block should always be registered before the next pending block
        bytes32 firstPendingBlockHash = client.pendingHash();
        assertEq(
            firstPendingBlockHash,
            PillarBlock.getHash(currentBlock),
            "Finalized block should always be registered before the next pending block"
        );
        assertEq(
            client.pendingFinalized(),
            false,
            "Pending block should not be finalized"
        );

        vm.roll(110);
        PillarBlock.WithChanges memory b2 = PillarBlock.WithChanges(
            PillarBlock.FinalizationData(
                2,
                bytes32(0),
                bytes32(0),
                PillarBlock.getHash(currentBlock)
            ),
            new PillarBlock.WeightChange[](0)
        );
        int256 totalWeightBefore = client.totalWeight();
        int256 blockWeight = getTotalWeight(b2);
        client.addPendingBlock(abi.encode(b2));

        (
            bytes32 blockHash,
            PillarBlock.FinalizationData memory b,
            uint256 finalizedAt
        ) = client.finalized();
        assertEq(b.period, 1);
        assertEq(blockHash, PillarBlock.getHash(currentBlock));
        assertEq(finalizedAt, block.number);

        // // Invariant tests - total weight should still be 200 + 0 + 0 + 0 = 200
        assertEq(
            client.totalWeight(),
            totalWeightBefore + blockWeight,
            "total weight should still be weight before + block weight"
        );
        console.log("total weight:", uint256(client.totalWeight()));
        // Invariant tests - finalized block should stay finalized
        (
            bytes32 finalizedBlockHash,
            PillarBlock.FinalizationData memory b2Block,
            uint256 lastFinalizedAt
        ) = client.finalized();
        assertEq(
            finalizedBlockHash,
            PillarBlock.getHash(currentBlock),
            "Finalized block should stay finalized"
        );
        assertEq(
            lastFinalizedAt,
            block.number,
            "Finalized block should stay finalized"
        );
        assertEq(b2Block.period, 1, "Finalized block should stay finalized");
    }

    function test_blockEncodeDecode() public {
        PillarBlock.WeightChange[]
            memory changes = new PillarBlock.WeightChange[](10);
        changes[0] = PillarBlock.WeightChange(address(uint160(1)), -1);
        changes[1] = PillarBlock.WeightChange(address(uint160(2)), 2);
        changes[2] = PillarBlock.WeightChange(address(uint160(3)), -3);
        changes[3] = PillarBlock.WeightChange(address(uint160(4)), 4);
        changes[4] = PillarBlock.WeightChange(address(uint160(5)), -5);
        changes[5] = PillarBlock.WeightChange(
            address(0x290DEcD9548b62A8D60345A988386Fc84Ba6BC95),
            12151343246432
        );
        changes[6] = PillarBlock.WeightChange(
            address(0xB10e2D527612073B26EeCDFD717e6a320cF44B4A),
            -112321
        );
        changes[7] = PillarBlock.WeightChange(
            address(0x405787FA12A823e0F2b7631cc41B3bA8828b3321),
            -13534685468457923145
        );
        changes[8] = PillarBlock.WeightChange(
            address(0xc2575a0E9E593c00f959F8C92f12dB2869C3395a),
            9976987696
        );
        changes[9] = PillarBlock.WeightChange(
            address(0x8a35AcfbC15Ff81A39Ae7d344fD709f28e8600B4),
            465876798678065667
        );

        for (uint256 i = 0; i < changes.length; i++) {
            console.log(utils.bytesToHex(keccak256(abi.encodePacked(i))));
        }

        PillarBlock.WithChanges memory b = PillarBlock.WithChanges(
            PillarBlock.FinalizationData(
                11,
                bytes32(uint256(22)),
                bytes32(uint256(33)),
                bytes32(uint256(44))
            ),
            changes
        );

        bytes memory bb = abi.encode(b);
        console.log("hex encoded ", utils.bytesToHex(bb));
        console.log(
            "hello: ",
            utils.bytesToHex(
                abi.encode(
                    hex"f9aad20feab5c2c3f0d9655fe22e65288d04b8faa925db55dc2d6b0390e8d1192ff5b95dcc5dad1ea0e0e3e96af4c569a76aad5b083dc91e53f4874ee5170d861c"
                )
            )
        );
        PillarBlock.WithChanges memory bcb = PillarBlock.fromBytes(bb);
        bytes memory bb2 = abi.encode(bcb);
        assertEq(bb, bb2);
        assertEq(PillarBlock.getHash(bb), PillarBlock.getHash(bcb));
    }

    function test_voteHash() public {
        PillarBlock.Vote memory vote = PillarBlock.Vote(1, bytes32(0));
        bytes32 hash = PillarBlock.getHash(vote);
        assertEq(hash, keccak256(abi.encodePacked(uint256(1), bytes32(0))));
    }

    function test_decodeRecover() public {
        // signer: 3eea25034397b249a3ed8614bb4d0533e5b03594
        // signed: full: bee528553ef2594e5643179d30ea8e0f1c1cdc2ceaf559f7f739d7ba21e1f7772d41a09821dc4eba64811327013062e9c71d97383211b43bc5e82773f93ecb3700 sig: bee528553ef2594e5643179d30ea8e0f1c1cdc2ceaf559f7f739d7ba21e1f7772d41a09821dc4eba64811327013062e9c71d97383211b43bc5e82773f93ecb37
        //
        address signer = 0x3Eea25034397B249a3eD8614BB4d0533e5b03594;
        bytes
            memory vote = hex"0000000000000000000000000000000000000000000000000000000000000001405787fa12a823e0f2b7631cc41b3ba8828b3321ca811111fa75cd3aa3bb5acebee528553ef2594e5643179d30ea8e0f1c1cdc2ceaf559f7f739d7ba21e1f7772d41a09821dc4eba64811327013062e9c71d97383211b43bc5e82773f93ecb37";
        PillarBlock.SignedVote memory decoded = abi.decode(
            vote,
            (PillarBlock.SignedVote)
        );
        // verify signature
        assertEq(
            decoded.signature.r,
            0xbee528553ef2594e5643179d30ea8e0f1c1cdc2ceaf559f7f739d7ba21e1f777
        );
        assertEq(
            decoded.signature.vs,
            0x2d41a09821dc4eba64811327013062e9c71d97383211b43bc5e82773f93ecb37
        );

        address recovered_signer = ECDSA.recover(
            PillarBlock.getHash(decoded.vote),
            decoded.signature.r,
            decoded.signature.vs
        );
        assertEq(recovered_signer, signer);
    }
}
