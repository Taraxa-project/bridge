// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import "../src/eth/TaraClient.sol";

contract TaraClientTest is Test {
    bytes32 hash_to_sign;
    TaraClient client;
    PillarBlockWithChanges currentBlock;

    function setUp() public {
        hash_to_sign = keccak256(abi.encodePacked("hello world"));

        WeightChange[] memory initial = new WeightChange[](10);
        for (uint256 i = 0; i < initial.length; i++) {
            bytes32 pk = keccak256(abi.encodePacked(i));
            initial[i] = WeightChange(vm.addr(uint256(pk)), 20);
        }
        client = new TaraClient(initial, 100, 10, bytes32(0));
        currentBlock = PillarBlockWithChanges(PillarBlock(1, bytes32(0), bytes32(0), bytes32(0)), new WeightChange[](0));
    }

    function test_signatures() public {
        uint32 signatures_count = 200;
        int256 weight = client.getSignaturesWeight(client.getBlockHash(currentBlock), getSignatures(signatures_count));
        assertEq(weight, int256(uint256(signatures_count)));
    }

    function getSignatures(uint32 count) public view returns (Signature[] memory signatures) {
        signatures = new Signature[](count);
        for (uint32 i = 0; i < count; i++) {
            Signature memory sig;
            bytes32 pk = keccak256(abi.encodePacked(uint256(i)));
            (sig.v, sig.r, sig.s) = vm.sign(uint256(pk), client.getBlockHash(currentBlock));
            signatures[uint256(i)] = sig;
        }
    }

    function test_blockAccept() public {
        client.finalizeBlock(currentBlock, getSignatures(200));
        (bytes32 blockHash, uint256 finalizedAt, PillarBlock memory b) = client.finalized();
        assertEq(blockHash, client.getBlockHash(currentBlock));
        assertEq(finalizedAt, block.number);
    }

    function test_weightChanges() public {
        WeightChange[] memory changes = new WeightChange[](20);
        for (uint256 i = 0; i < changes.length; i++) {
            bytes32 pk = keccak256(abi.encodePacked(i));
            changes[i] = WeightChange(vm.addr(uint256(pk)), 10);
        }
        client.setThreshold(1);
        client.processValidatorChanges(changes);
    }

    function test_optimisticAccept() public {
        vm.roll(100);
        currentBlock.block.prevHash = client.getBlockHash(client.getPending());
        client.addPendingBlock(currentBlock);
        vm.roll(110);
        PillarBlockWithChanges memory b2 = PillarBlockWithChanges(
            PillarBlock(2, client.getBlockHash(currentBlock), bytes32(0), bytes32(0)), new WeightChange[](0)
        );
        client.addPendingBlock(b2);

        (bytes32 blockHash, uint256 finalizedAt, PillarBlock memory b) = client.finalized();
        assertEq(b.number, 1);
        assertEq(blockHash, client.getBlockHash(currentBlock));
        assertEq(finalizedAt, block.number);
    }
}
