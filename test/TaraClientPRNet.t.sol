// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {Test} from "forge-std/Test.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {TaraClient} from "../src/eth/TaraClient.sol";
import {CompactSignature} from "../src/lib/PillarBlock.sol";
import {PillarBlock} from "../src/lib/PillarBlock.sol";
import {TaraClientHarness} from "./utils/TaraClientHarness.sol";

/**
 * @title Test that Tara client accepts blocks from the PRNet
 * @author @kstdl
 */
contract TaraClientPRNetTest is Test {
    TaraClient client;
    PillarBlock.WithChanges currentBlock;
    uint256 constant PILLAR_BLOCK_INTERVAL = 100;

    // {
    //     "hash": "0x659f33d940342ccbb534a745e93b3cc0d44f09f8b5f9db7d8c9ede2d047b4522",
    //     "pbft_period": 100,
    //     "previous_pillar_block_hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
    //     "state_root": "0xc8e155d2b0f39dd07a9520667445a79a67576387f97cdb15b14157e45f1bee91",
    //     "bridge_root": "0x0000000000000000000000000000000000000000000000000000000000000000",
    //     "epoch": 0,
    //     "validators_vote_counts_changes": [
    //         {
    //         "address": "0xfe3d5e3b9c2080bf338638fd831a35a4b4344a2c",
    //         "value": 100
    //         },
    //         {
    //         "address": "0x515c990ef87668e57a290f650b4c39c343d73d9a",
    //         "value": 100
    //         },
    //         {
    //         "address": "0x3e62c62ac89c71412ca68688530d112433fec78c",
    //         "value": 100
    //         }
    //     ]
    // }
    function setUp() public {
        PillarBlock.VoteCountChange[] memory initial = new PillarBlock.VoteCountChange[](3);
        initial[0] = PillarBlock.VoteCountChange(0xFe3d5E3B9c2080bF338638Fd831a35A4B4344a2C, 100);
        initial[1] = PillarBlock.VoteCountChange(0x515C990Ef87668E57A290F650b4C39c343d73d9a, 100);
        initial[2] = PillarBlock.VoteCountChange(0x3E62C62Ac89c71412CA68688530D112433FEC78C, 100);

        PillarBlock.WithChanges memory _currentBlock = PillarBlock.WithChanges(
            PillarBlock.FinalizationData(
                100, 0xc8e155d2b0f39dd07a9520667445a79a67576387f97cdb15b14157e45f1bee91, 0x0, 0x0, 0x0
            ),
            initial
        );
        currentBlock.block = _currentBlock.block;
        for (uint256 i = 0; i < initial.length; i++) {
            currentBlock.validatorChanges.push(initial[i]);
        }
        assertEq(PillarBlock.getHash(currentBlock), 0x816742a75eea9cca5530e25894135258d0a2a81d4c9701cd0d34a7fae40c9842);

        address taraClientProxy = Upgrades.deployUUPSProxy(
            "TaraClientHarness.sol", abi.encodeCall(TaraClientHarness.initializeIt, (PILLAR_BLOCK_INTERVAL))
        );
        client = TaraClientHarness(taraClientProxy);

        PillarBlock.WithChanges[] memory blocks = new PillarBlock.WithChanges[](1);
        blocks[0] = currentBlock;
        client.finalizeBlocks(blocks, new CompactSignature[](0));
        assertEq(client.validatorVoteCounts(0xFe3d5E3B9c2080bF338638Fd831a35A4B4344a2C), 100);
        assertEq(client.validatorVoteCounts(0x515C990Ef87668E57A290F650b4C39c343d73d9a), 100);
        assertEq(client.validatorVoteCounts(0x3E62C62Ac89c71412CA68688530D112433FEC78C), 100);
    }

    // {
    //     "pillar_block": {
    //         "bridge_root": "0x0000000000000000000000000000000000000000000000000000000000000000",
    //         "epoch": 0,
    //         "hash": "0xb5821389568f0baa4f422eea88ec490be7d5a45eb36917703c07ce7a2069f870",
    //         "pbft_period": 200,
    //         "previous_pillar_block_hash": "0x816742a75eea9cca5530e25894135258d0a2a81d4c9701cd0d34a7fae40c9842",
    //         "state_root": "0x3927e752a7732d2380a8d5c3480103590bd53bdb6fa694fbdce326203792a5bb",
    //         "validators_vote_counts_changes": []
    //     },
    //     "pillar_block_binary_data": "0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000c83927e752a7732d2380a8d5c3480103590bd53bdb6fa694fbdce326203792a5bb0000000000000000000000000000000000000000000000000000000000000000659f33d940342ccbb534a745e93b3cc0d44f09f8b5f9db7d8c9ede2d047b452200000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000000",
    //     "signatures": [
    //         {
    //             "r": "0xc99aa7129783f9e04daba144b6346b69982db9a518f03c4f345181d7d417fbc7",
    //             "vs": "0x932ec62fc58f9f4b6e3233dc8ce0cdd8f5fe770920491803cfa855773f38db82"
    //         },
    //         {
    //             "r": "0x19755b9e65303f8c479c5b33488d6b5830dbb059332524968c71b2c5739abee4",
    //             "vs": "0xcb27f39ea0d434be260048a99ffdf2bfea1f04657750aebaee17c4d56a739ca6"
    //         },
    //         {
    //             "r": "0x70cf255902ab32b09f72a09afa682522555dd05aa32c4c01ef383896a1842157",
    //             "vs": "0x96dd278029d9c555fa5956950aa227d2778c99d85aba6f0985f398aa6caca9fc"
    //         }
    //     ]
    // }
    function test_acceptPrNetBlocks() public {
        // PillarBlock.WithChanges memory _currentBlock = PillarBlock.WithChanges(
        //     PillarBlock.FinalizationData(
        //         200,
        //         0x3927e752a7732d2380a8d5c3480103590bd53bdb6fa694fbdce326203792a5bb,
        //         0x816742a75eea9cca5530e25894135258d0a2a81d4c9701cd0d34a7fae40c9842,
        //         0x0,
        //         0x0
        //     ),
        //     new PillarBlock.VoteCountChange[](0)
        // );
        // currentBlock.block = _currentBlock.block;
        // delete currentBlock.validatorChanges;

        // assertEq(PillarBlock.getHash(currentBlock), 0x1f76e8e54a1403277c637e4db7f77942d149db1cef0b6c7e2ede09d87ba084fa);

        // CompactSignature[] memory signatures = new CompactSignature[](3);
        // signatures[0] = CompactSignature(
        //     0xc99aa7129783f9e04daba144b6346b69982db9a518f03c4f345181d7d417fbc7,
        //     0x932ec62fc58f9f4b6e3233dc8ce0cdd8f5fe770920491803cfa855773f38db82
        // );
        // signatures[1] = CompactSignature(
        //     0x19755b9e65303f8c479c5b33488d6b5830dbb059332524968c71b2c5739abee4,
        //     0xcb27f39ea0d434be260048a99ffdf2bfea1f04657750aebaee17c4d56a739ca6
        // );
        // signatures[2] = CompactSignature(
        //     0x70cf255902ab32b09f72a09afa682522555dd05aa32c4c01ef383896a1842157,
        //     0x96dd278029d9c555fa5956950aa227d2778c99d85aba6f0985f398aa6caca9fc
        // );
        // PillarBlock.WithChanges[] memory blocks = new PillarBlock.WithChanges[](1);
        // blocks[0] = currentBlock;
        // client.finalizeBlocks(blocks, signatures);
        // // {
        // //     "pillar_block": {
        // //         "bridge_root": "0x0000000000000000000000000000000000000000000000000000000000000000",
        // //         "hash": "0xfc2f5857f08ff62434f1f4d0b54ca32ccb10e39e95c046e9ce1826a7447a2821",
        // //         "pbft_period": 300,
        // //         "previous_pillar_block_hash": "0x1f76e8e54a1403277c637e4db7f77942d149db1cef0b6c7e2ede09d87ba084fa",
        // //         "state_root": "0x2f14aba5f820184ac95fe79aff921047d73a567d70d46f0c44d609f00749b1e6",
        // //         "validators_vote_counts_changes": []
        // //     },
        // //     "pillar_block_binary_data": "0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000012c2f14aba5f820184ac95fe79aff921047d73a567d70d46f0c44d609f00749b1e60000000000000000000000000000000000000000000000000000000000000000b5821389568f0baa4f422eea88ec490be7d5a45eb36917703c07ce7a2069f87000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000000",
        // //     "signatures": [
        // //         {
        // //             "r": "0xa16e03ac24dc0d86565fb17cb5fe57e10e3f8ef20aebc793547f9cde3db256fb",
        // //             "vs": "0xa13d6f01dc084b1568d3196e01b42b51845261cdcffaaa8c9bb9dca3c828d5d2"
        // //         },
        // //         {
        // //             "r": "0xf371392864559867c725bf8f610bf8991e099dff3528cb993a75b900df46c950",
        // //             "vs": "0x7e7d032ccf494e36f4515c39296ec40719f7c394b392746cb0eea26e5dce75f3"
        // //         },
        // //         {
        // //             "r": "0x042fbe924b6a2da0d039aed4b397933f43e826f50a64ca5b6ad50bf092452a9d",
        // //             "vs": "0xd995ce339a6cb80ccdf3905c1e45a82a500ff0f39ff53b4d1727983e3ddd2657"
        // //         }
        // //     ]
        // // }
        // PillarBlock.WithChanges memory _currentBlock2 = PillarBlock.WithChanges(
        //     PillarBlock.FinalizationData(
        //         300,
        //         0x2f14aba5f820184ac95fe79aff921047d73a567d70d46f0c44d609f00749b1e6,
        //         0x1f76e8e54a1403277c637e4db7f77942d149db1cef0b6c7e2ede09d87ba084fa,
        //         0x0,
        //         0x0
        //     ),
        //     new PillarBlock.VoteCountChange[](0)
        // );
        // currentBlock.block = _currentBlock2.block;
        // delete currentBlock.validatorChanges;
        // assertEq(PillarBlock.getHash(currentBlock), 0x816742a75eea9cca5530e25894135258d0a2a81d4c9701cd0d34a7fae40c9842);

        // signatures = new CompactSignature[](3);
        // signatures[0] = CompactSignature(
        //     0xa16e03ac24dc0d86565fb17cb5fe57e10e3f8ef20aebc793547f9cde3db256fb,
        //     0xa13d6f01dc084b1568d3196e01b42b51845261cdcffaaa8c9bb9dca3c828d5d2
        // );
        // signatures[1] = CompactSignature(
        //     0xf371392864559867c725bf8f610bf8991e099dff3528cb993a75b900df46c950,
        //     0x7e7d032ccf494e36f4515c39296ec40719f7c394b392746cb0eea26e5dce75f3
        // );
        // signatures[2] = CompactSignature(
        //     0x042fbe924b6a2da0d039aed4b397933f43e826f50a64ca5b6ad50bf092452a9d,
        //     0xd995ce339a6cb80ccdf3905c1e45a82a500ff0f39ff53b4d1727983e3ddd2657
        // );
        // blocks[0] = currentBlock;
        // client.finalizeBlocks(blocks, signatures);
    }

    function test_notAcceptChangedBlock() public {
        PillarBlock.WithChanges memory _currentBlock2 = PillarBlock.WithChanges(
            PillarBlock.FinalizationData(
                200,
                0x3927e752a7732d2380a8d5c3480103590bd53bdb6fa694fbdce326203792a5bb,
                0x659f33d940342ccbb534a745e93b3cc0d44f09f8b5f9db7d8c9ede2d047b4522,
                bytes32(uint256(0x1)),
                0x0
            ),
            new PillarBlock.VoteCountChange[](0)
        );
        currentBlock.block = _currentBlock2.block;
        delete currentBlock.validatorChanges;
        assertNotEq(
            PillarBlock.getHash(currentBlock), 0xb5821389568f0baa4f422eea88ec490be7d5a45eb36917703c07ce7a2069f870
        );

        CompactSignature[] memory signatures = new CompactSignature[](3);
        signatures[0] = CompactSignature(
            0xc99aa7129783f9e04daba144b6346b69982db9a518f03c4f345181d7d417fbc7,
            0x932ec62fc58f9f4b6e3233dc8ce0cdd8f5fe770920491803cfa855773f38db82
        );
        signatures[1] = CompactSignature(
            0x19755b9e65303f8c479c5b33488d6b5830dbb059332524968c71b2c5739abee4,
            0xcb27f39ea0d434be260048a99ffdf2bfea1f04657750aebaee17c4d56a739ca6
        );
        signatures[2] = CompactSignature(
            0x70cf255902ab32b09f72a09afa682522555dd05aa32c4c01ef383896a1842157,
            0x96dd278029d9c555fa5956950aa227d2778c99d85aba6f0985f398aa6caca9fc
        );
        PillarBlock.WithChanges[] memory blocks = new PillarBlock.WithChanges[](1);
        blocks[0] = currentBlock;
        vm.expectRevert();
        client.finalizeBlocks(blocks, signatures);
    }
}
