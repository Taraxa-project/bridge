// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import {PillarBlock} from "../src/lib/PillarBlock.sol";
import {TaraClientHarness} from "./utils/TaraClientHarness.sol";
import {CompactSignature} from "../src/lib/PillarBlock.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

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
    TaraClientHarness client;
    PillarBlock.WithChanges currentBlock;
    uint256 constant PILLAR_BLOCK_INTERVAL = 100;
    uint32 constant PILLAR_BLOCK_THRESHOLD = 50;

    address caller = address(bytes20(sha256(hex"1234")));

    function updateCurrentBlock(PillarBlock.WithChanges memory newBlock) public {
        currentBlock.block.period = newBlock.block.period;
        currentBlock.block.stateRoot = newBlock.block.stateRoot;
        currentBlock.block.bridgeRoot = newBlock.block.bridgeRoot;
        currentBlock.block.prevHash = newBlock.block.prevHash;
        delete currentBlock.validatorChanges;
        for (uint256 i = 0; i < newBlock.validatorChanges.length; i++) {
            currentBlock.validatorChanges.push(newBlock.validatorChanges[i]);
        }
    }

    function setUp() public {
        vm.startBroadcast(caller);
        PillarBlock.VoteCountChange[] memory initial = new PillarBlock.VoteCountChange[](10);
        for (uint256 i = 0; i < initial.length; i++) {
            bytes32 pk = keccak256(abi.encodePacked(i));
            initial[i] = PillarBlock.VoteCountChange(vm.addr(uint256(pk)), 20);
        }

        updateCurrentBlock(
            PillarBlock.WithChanges(PillarBlock.FinalizationData(1, bytes32(0), bytes32(0), bytes32(0), 0), initial)
        );

        address taraClientProxy = Upgrades.deployUUPSProxy(
            "TaraClientHarness.sol", abi.encodeCall(TaraClientHarness.initializeIt, (PILLAR_BLOCK_INTERVAL))
        );
        client = TaraClientHarness(taraClientProxy);
        PillarBlock.WithChanges[] memory blocks = new PillarBlock.WithChanges[](1);
        blocks[0] = currentBlock;
        client.finalizeBlocks(blocks, getSignatures(PILLAR_BLOCK_THRESHOLD));
        currentBlock.block.period += PILLAR_BLOCK_INTERVAL;
        currentBlock.block.prevHash = client.getFinalized().blockHash;

        // this should not revert
        client.getFinalizedBridgeRoot(1);
        vm.stopBroadcast();
    }

    function getVoteCountChanges() internal pure returns (PillarBlock.VoteCountChange[] memory) {
        PillarBlock.VoteCountChange[] memory vote_changes = new PillarBlock.VoteCountChange[](20);
        for (uint256 i = 0; i < vote_changes.length; i++) {
            bytes32 pk = keccak256(abi.encodePacked(i));
            vote_changes[i] = PillarBlock.VoteCountChange(vm.addr(uint256(pk)), 10);
        }
        return vote_changes;
    }

    function getCompactSig(bytes32 pk, bytes32 h) public pure returns (CompactSignature memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(uint256(pk), h);
        if (v >= 27) {
            v -= 27;
        }

        return CompactSignature(r, (bytes32(uint256(v)) << 255) | s);
    }

    function sortSignatures(CompactSignature[] memory signatures) public pure returns (CompactSignature[] memory) {
        // sort signatures
        for (uint256 i = 0; i < signatures.length; i++) {
            for (uint256 j = i + 1; j < signatures.length; j++) {
                if (signatures[i].r < signatures[j].r) {
                    (signatures[i], signatures[j]) = (signatures[j], signatures[i]);
                }
            }
        }
        return signatures;
    }

    function getSignatures(uint32 count) public view returns (CompactSignature[] memory signatures) {
        signatures = new CompactSignature[](count);
        for (uint32 i = 0; i < count; i++) {
            bytes32 pk = keccak256(abi.encodePacked(uint256(i)));
            CompactSignature memory sig = getCompactSig(pk, PillarBlock.getVoteHash(currentBlock));
            signatures[uint256(i)] = sig;
        }
    }

    function getSortedSignatures(uint32 count) public view returns (CompactSignature[] memory signatures) {
        signatures = getSignatures(count);
        return sortSignatures(signatures);
    }

    function getTotalWeight(PillarBlock.WithChanges memory validatorBlock) public pure returns (uint256 totalWeight) {
        totalWeight = 0;
        for (uint256 i = 0; i < validatorBlock.validatorChanges.length; i++) {
            if (validatorBlock.validatorChanges[i].change < 0) {
                totalWeight -= uint256(uint32(-validatorBlock.validatorChanges[i].change));
            } else {
                totalWeight += uint256(uint32(validatorBlock.validatorChanges[i].change));
            }
        }
        return totalWeight;
    }

    function test_signatures() public view {
        uint32 signatures_count = 200;
        uint256 weight =
            client.getSignaturesWeight(PillarBlock.getVoteHash(currentBlock), getSortedSignatures(signatures_count));
        assertEq(weight, uint256(signatures_count));
    }

    function updateCurrentBlockVoteChanges(PillarBlock.VoteCountChange[] memory changes) public {
        delete currentBlock.validatorChanges;
        for (uint256 i = 0; i < changes.length; i++) {
            currentBlock.validatorChanges.push(changes[i]);
        }
    }

    function test_blockAccept() public {
        PillarBlock.WithChanges memory currBlock = currentBlock;
        assertEq(currentBlock.block.period, currBlock.block.period, "periods should match");
        currBlock.validatorChanges = getVoteCountChanges();
        assertNotEq(currBlock.validatorChanges.length, currentBlock.validatorChanges.length, "lengths should not match");
        PillarBlock.WithChanges[] memory blocks = new PillarBlock.WithChanges[](1);
        delete currentBlock.validatorChanges;
        for (uint256 i = 0; i < currBlock.validatorChanges.length; i++) {
            currentBlock.validatorChanges.push(currBlock.validatorChanges[i]);
        }
        blocks[0] = currentBlock;

        client.finalizeBlocks(blocks, getSortedSignatures(PILLAR_BLOCK_THRESHOLD));
        (bytes32 blockHash,, uint256 finalizedAt) = client.finalized();
        assertEq(blockHash, PillarBlock.getHash(currentBlock));
        assertEq(finalizedAt, block.number);
    }

    function test_rejectBlockWithWrongSignatures() public {
        updateCurrentBlockVoteChanges(getVoteCountChanges());
        PillarBlock.WithChanges[] memory blocks = new PillarBlock.WithChanges[](1);
        blocks[0] = currentBlock;
        currentBlock.block.period += 1;

        vm.expectRevert();
        client.finalizeBlocks(blocks, getSortedSignatures(PILLAR_BLOCK_THRESHOLD));
    }

    function makePillarChain(uint256 count) public returns (PillarBlock.WithChanges[] memory blocks) {
        blocks = new PillarBlock.WithChanges[](count);
        blocks[0] = currentBlock;
        for (uint256 i = 1; i < count; i++) {
            currentBlock.block.prevHash = PillarBlock.getHash(currentBlock);
            currentBlock.block.period += PILLAR_BLOCK_INTERVAL;
            blocks[i] = currentBlock;
        }
    }

    function test_acceptBatch() public {
        updateCurrentBlockVoteChanges(getVoteCountChanges());
        PillarBlock.WithChanges[] memory blocks = makePillarChain(10);

        client.finalizeBlocks(blocks, getSortedSignatures(PILLAR_BLOCK_THRESHOLD));
    }

    function test_rejectBatchWithWrongPrevHash() public {
        updateCurrentBlockVoteChanges(getVoteCountChanges());
        PillarBlock.WithChanges[] memory blocks = makePillarChain(10);

        blocks[3].block.prevHash = bytes32(0);

        vm.expectRevert();
        client.finalizeBlocks(blocks, getSortedSignatures(PILLAR_BLOCK_THRESHOLD));
    }

    function test_rejectBatchWithWrongSignatures() public {
        updateCurrentBlockVoteChanges(getVoteCountChanges());
        PillarBlock.WithChanges[] memory blocks = makePillarChain(10);

        // set some block in the middle to create signatures for
        currentBlock.block = blocks[3].block;
        vm.expectRevert();
        client.finalizeBlocks(blocks, getSortedSignatures(PILLAR_BLOCK_THRESHOLD));
    }

    function test_weightChanges() public {
        vm.startBroadcast(caller);
        PillarBlock.VoteCountChange[] memory changes = new PillarBlock.VoteCountChange[](20);
        for (uint256 i = 0; i < changes.length; i++) {
            bytes32 pk = keccak256(abi.encodePacked(i));
            changes[i] = PillarBlock.VoteCountChange(vm.addr(uint256(pk)), 10);
        }
        client.processValidatorChangesPublic(changes);
        vm.stopBroadcast();
    }

    function test_blockEncodeDecode() public pure {
        PillarBlock.VoteCountChange[] memory changes = new PillarBlock.VoteCountChange[](10);
        changes[0] = PillarBlock.VoteCountChange(address(uint160(1)), -1);
        changes[1] = PillarBlock.VoteCountChange(address(uint160(2)), 2);
        changes[2] = PillarBlock.VoteCountChange(address(uint160(3)), -3);
        changes[3] = PillarBlock.VoteCountChange(address(uint160(4)), 4);
        changes[4] = PillarBlock.VoteCountChange(address(uint160(5)), -5);
        changes[5] = PillarBlock.VoteCountChange(address(0x290DEcD9548b62A8D60345A988386Fc84Ba6BC95), 1215134324);
        changes[6] = PillarBlock.VoteCountChange(address(0xB10e2D527612073B26EeCDFD717e6a320cF44B4A), -112321);
        changes[7] = PillarBlock.VoteCountChange(address(0x405787FA12A823e0F2b7631cc41B3bA8828b3321), -1353468546);
        changes[8] = PillarBlock.VoteCountChange(address(0xc2575a0E9E593c00f959F8C92f12dB2869C3395a), 997698769);
        changes[9] = PillarBlock.VoteCountChange(address(0x8a35AcfbC15Ff81A39Ae7d344fD709f28e8600B4), 465876798);

        PillarBlock.WithChanges memory b = PillarBlock.WithChanges(
            PillarBlock.FinalizationData(11, bytes32(uint256(22)), bytes32(uint256(33)), bytes32(uint256(44)), 55),
            changes
        );

        bytes memory bb = abi.encode(b);
        PillarBlock.WithChanges memory bcb = PillarBlock.fromBytes(bb);
        bytes memory bb2 = abi.encode(bcb);
        assertEq(bb, bb2);
        assertEq(PillarBlock.getHash(bb), PillarBlock.getHash(bcb));
    }

    function test_voteHash() public pure {
        PillarBlock.Vote memory vote = PillarBlock.Vote(1, bytes32(0));
        bytes32 hash = PillarBlock.getHash(vote);
        assertEq(hash, keccak256(abi.encodePacked(uint256(1), bytes32(0))));
    }

    function test_decodeRecover() public pure {
        // signer: 3eea25034397b249a3ed8614bb4d0533e5b03594
        // signed: full: bee528553ef2594e5643179d30ea8e0f1c1cdc2ceaf559f7f739d7ba21e1f7772d41a09821dc4eba64811327013062e9c71d97383211b43bc5e82773f93ecb3700 sig: bee528553ef2594e5643179d30ea8e0f1c1cdc2ceaf559f7f739d7ba21e1f7772d41a09821dc4eba64811327013062e9c71d97383211b43bc5e82773f93ecb37
        //
        address signer = 0x3Eea25034397B249a3eD8614BB4d0533e5b03594;
        bytes memory vote =
            hex"0000000000000000000000000000000000000000000000000000000000000001405787fa12a823e0f2b7631cc41b3ba8828b3321ca811111fa75cd3aa3bb5acebee528553ef2594e5643179d30ea8e0f1c1cdc2ceaf559f7f739d7ba21e1f7772d41a09821dc4eba64811327013062e9c71d97383211b43bc5e82773f93ecb37";
        PillarBlock.SignedVote memory decoded = abi.decode(vote, (PillarBlock.SignedVote));
        // verify signature
        assertEq(decoded.signature.r, 0xbee528553ef2594e5643179d30ea8e0f1c1cdc2ceaf559f7f739d7ba21e1f777);
        assertEq(decoded.signature.vs, 0x2d41a09821dc4eba64811327013062e9c71d97383211b43bc5e82773f93ecb37);

        address recovered_signer =
            ECDSA.recover(PillarBlock.getHash(decoded.vote), decoded.signature.r, decoded.signature.vs);
        assertEq(recovered_signer, signer);
    }

    function test_pillarVoteSerialization() public pure {
        assertEq(
            PillarBlock.getVoteHash(12, bytes32(uint256(34))),
            0x00ec94cd6076f5d010620194cc66952562bc3ba027026bdd156000479a7754b1
        );
    }

    function test_epochCheck() public {
        PillarBlock.WithChanges[] memory blocks = new PillarBlock.WithChanges[](1);
        currentBlock.block.epoch += 1;
        blocks[0] = currentBlock;
        client.finalizeBlocks(blocks, getSortedSignatures(PILLAR_BLOCK_THRESHOLD));
    }

    function test_revertOnFutureEpoch() public {
        test_epochCheck();

        PillarBlock.WithChanges[] memory blocks = new PillarBlock.WithChanges[](1);
        currentBlock.block.epoch += 2;
        blocks[0] = currentBlock;

        vm.expectRevert();
        client.finalizeBlocks(blocks, getSortedSignatures(PILLAR_BLOCK_THRESHOLD));
    }

    function test_SignaturesNotSorted() public {
        PillarBlock.WithChanges[] memory blocks = new PillarBlock.WithChanges[](1);
        blocks[0] = currentBlock;

        CompactSignature[] memory signatures = getSignatures(PILLAR_BLOCK_THRESHOLD);
        vm.expectRevert();
        client.finalizeBlocks(blocks, signatures);
    }

    function test_DuplicateSignatures() public {
        PillarBlock.WithChanges[] memory blocks = new PillarBlock.WithChanges[](1);
        blocks[0] = currentBlock;

        CompactSignature[] memory signatures = getSignatures(PILLAR_BLOCK_THRESHOLD);
        signatures[1] = signatures[0];
        vm.expectRevert();
        client.finalizeBlocks(blocks, signatures);
    }
}
