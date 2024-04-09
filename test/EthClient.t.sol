// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import "../src/tara/EthClient.sol";

contract LightClientMock {
    bytes32 merkleRoot;

    function set_merkle_root(bytes32 root) external {
        merkleRoot = root;
    }

    function merkle_root() external view returns (bytes32) {
        return merkleRoot;
    }
}

contract EthClientTest is Test {
    EthClientWrapper client;
    LightClientMock lightClient = new LightClientMock();

    function setUp() public {
        address ethBridgeAddress = 0x47A5339E575aC525b1278eA1F0bCE3A092384416;
        bytes32 key = 0x0;
        client = new EthClientWrapper(
            BeaconLightClient(address(lightClient)),
            ethBridgeAddress,
            key
        );
    }

    function test_merkleRoot() public {
        bytes32 root = 0x0000000000000000000000000000000000000000000000000000000000111111;
        lightClient.set_merkle_root(root);
        assertEq(client.getMerkleRoot(), root);
    }

    function test_bridgeRootProof() public {
        // curl https://eth-sepolia.public.blastapi.io -X POST -H "Content-Type: application/json" --data '{"method":"eth_getProof","params":["0x47A5339E575aC525b1278eA1F0bCE3A092384416", ["0x0"], "0x4EB38A"],"id":1,"jsonrpc":"2.0"}'
        bytes32 stateRoot = 0x0fd6262cbcd27159356419dca723374bb7073bd7402b35f7461704e077a02b48;
        lightClient.set_merkle_root(stateRoot);

        bytes[] memory accountProof = new bytes[](8);
        accountProof[
            0
        ] = hex"f90211a045d54a01b8a315d5855138b469c7c50a230a0d757e7c0013530d6bafd71c8768a0a566deeb240f9162f16f78ffc8dd6e670c102509e0baf7df3e902d9d6d68aa6ea0d8919bf932d739f61e241aa933641a41a79fb290e997c0d1b61652b33f0e0c5fa073e66036edc0bf1ac1e677222ecfd71a1bde8c6bcf6246d237fc4cfa24aaa856a0a2ecc72592416f703a89e381e6bb192543d6935c5561c2fed80e8ae7e8e3a8c6a0b3ea7ce321a355e3aa6fbbb61931c0b327f501f36acd2c8c4192743e5c2a95dca0e41f6bd64517fc27524555ce71bfba965bc9310531078821c9de83a4faa1b25ca05c231f2fbe8ecce6ccc0c33f13b6ae8a8412d6cfaf34f3e73b6d977de231f336a0ff556e2394a20c9f713e9e3192c306fb05f1beab1d248a971058da5da07270f2a0d6f7aa7a09a019175706814edd5a1724657f4228d956855500716054961a1b87a09ce71422afe29f8313aad3f4530083b5714cadfa27367b007b07b7bd9f137d25a08d3b3c25eb178433e84efc38f0d43e649b8f8a84845a434a1eca46f28fcaf58fa0b663c709f5c46557b0e072e77d67df967d58f03bd3e87aa435fcd766b6aabcb5a085013ca214693a5d66f94c8b36d6d19e9ef8a0e61532021e41f6cafb30699e7da066591bd73f040c8049dd630775c70b533c9dacc2df825241762dcb205cb3732ca0d2e418a47a9e8b1b3b7d9912e06c5f9970368fb90f9f68bf61cda49dab65abf280";
        accountProof[
            1
        ] = hex"f90211a0dc4b11d607ea5268a5cf71de1ea13f98595811ce77f8a41c5055a99d7d6d6a1fa0292223d69b136f81d712416d6bfcd3be898b4ddb45c1d4e32ff2a8a77abb75b2a0b17ca99f1ea0298877cf9cc9cd7165fde3347e751c54f52a4854343ebcbe4ba9a0dee06a6b68f3cc28d863d897ed7bff8cfb3c804885f2c67d2b49b029dde980e5a08cf422f461a54696bb54b7073ddff08da3c06133bccee6d608453504268c14e3a0e53ba8bf2749dc3bc0b3eedbb8f43e3c6b347be0acace10de72e45f4e26f7273a0a2e4eea3a8f0a4316352b069e7f67810f8f4bd4542cd99efc20a1c067d60233ea0d7d50bfc893ed9a2d56dba97b9bd6492005191e78d0f971bced957c35819f153a06fcf4eb4dedde66dc629e78c7132a47f4b059e11a3ebdbcb6194302470073da9a0e56303601eb5a30b6a1c53ef83c1171b9674343bdbaf1ae6212357329d33c0c5a0d1578cd43ceedbc9ad3d7ae42386bdac50365963f5fe177ac981676427b4a845a044cbb4e82058e58e768cf0cb7864cea2b65e2e63861c584691eb9909257b3ab7a0a5543806055f8d93e4a3a60ad6d751b297766f4d7cc2080c97b60759efaf9051a0fde3a3a55df91a0e65acb3c076802bda139159e0d20fadb966ca47281543c9d7a0173b6428902a52fcf0d3b1ff78e5b97e44230bfc2c7437cbac46c52d0172bfffa0481c4697578871d1f8b1a45b2620fa5c8a5c2a6ac488aab504ccb323d806bb5480";
        accountProof[
            2
        ] = hex"f90211a06ad7eda9f84baa4730043671f28a4d4356e021c668e5f036429f0f134d4a4b28a03a7e063f6207b1fd03aead2032ace2e37ebd2ca31d19569ba3376a0e38123e11a0c4acda6fdf259577255c66bbaceecded2b45c951b58210dd16f26675bc61b236a02a493f59bba6b28c46d4182249130a5725dd817e971dec1fe26b024a99c2232fa09ad6e59579bd4909cfac168091d28252436d3f8ef82c44b1474ea83d76e8d64ea0d6dd31c40614c12f627d483f5638d53f0efaf3c9a284d47fa1b5d1a8e0bd3c1ca00165b2f299d08cd1c56122ad799d2525671f25d589d17a48a692bdb48a2ddae0a0b402762a64978c18fde4d13bb49b0f0389752815653084a74a6805f463e74e22a0159055e88496256d1d308fc8aac66f7e56048632af0dc4edd2c30b16ccd79ca0a0b7c3e9728e917a1c1c9159c6a2649e7fc0201908ec84c549ed21c6779e7faf48a0a697fb2b42749568e47212668293263f76ed1592756f3a4096227ded9a3e7ec0a09c536e3802984b99de0a3e2320d55e62e7e5537c7e61e4da1f24fad2a81c249ca0aed0dc9b94b042fee046289718788270956fd55d79fdca3fcd6509175dc3d2c7a02b03db148076f7648b6f6fd8a8475449614169ff7399284b03155cff2a548bc9a0eef0101f9c0c0b78afd5512319d13ef1cb5bee0c0851e331037e7bb17cae6a6da03e225355de80ed13bd07d12aa137ea3613c8de30cf28a8392699e501ec617d7d80";
        accountProof[
            3
        ] = hex"f90211a0fa46c8883559a83c5148096bd27e8fc41afd3c1be72eccff4624075fa4a596fca09d55c7551fcb517b30c1c3fb2ce5ff925364533e93a23186638fb09cd4ef55f1a0f6aa289d04b9d6d8428f17cc98eb2254aa89f94a51f79b89ffd80cb9ed8fa735a0a12e89a0780862f9d6ec107b1bc75b28f3c0279e8533b7613aeea597ba559c6aa0738e6b80fcb8701c346fe246d42ff504777cf8d0c42f64dea0ac12c5d01b31f5a0eddf6244039c2ae43634760f3f1c7fb69ba4604ece390e74d8a99f23f1407cb8a07564b096bbafe1e4825fa8eee5bc1d5df8e68b96496a0141577d07d8234954bea07491518d240de45f33f678d5ab3a5f027e3fcbd35c9ec6f27ccca68821c09489a0bbf4abbe286f35afe9ca0fbbf6e3748ab67d41fa7207d9b1fcb649b0f41d83c0a0a9c526f32a701cf67f1ffec22714dd7ef0b448c91a62c0eb78d523e05baca617a0bfcebca9c48eee0764290360e328d10e1dd3a10b19ff22d851e91cd32dfa7e9ca04aa18793c9121c0b0d3196de7fe32d0093d6a5dd6f84ff30dd84a5a5acf24c14a004a79f2a7ea0a7ff841e566e430b9d9e4b6d8193ca8e19ad4f215c29848585e6a09598f9b9315d94f34cec9c8a5338cf834b57e8ab829fa298223b84e90ed9859fa07944db4220c3fb73b5ef624fb89b2090d370cf7727aa738f09060a0c783ca51ca09026a8e0515e0fbf75781d38a087ba6fb00ec65af72aa74db2521d1bc934cdb980";
        accountProof[
            4
        ] = hex"f90211a054bbd877ca86a53466d5be92a8bae080efac215cfaa743f73a2eab1d4a117e4fa0608f137770b53c6cdbc5e80b4fccd7fe1ec7b7a1cbf86110136ae51919960ccea0b9617477e2b066b4de7650e9b77d31f53288aeb330c76af9985052fec2c22332a0c96cb0dd4556039a28e68911ae2ef65173af72cb8de70e49cc9767f383f76d56a032b0b73491f12a42559a55ba4830b555328d89baaac7748c77ca72c3a127c528a0469406dfbf2e082d5285be4128566cc3ee3222eb9ca4e83d4422c6ea0dbd3fe7a008ccf162ba14f22d4907791ca41f87a112eaa8d0148fd02131eccbc2dc7d848fa0bf6d5cbe6428824ca4e12fde17903bd055e7b0d1bdd486ccac9a575a79b5a7b4a08c4d3683c65d4eb2c36661232920344efc540534267eb866889f2ce0fe7fdb02a0954fe3d48fa435f19e1310fe288e53950546972f3aa9653ebbea2ab77d2904a6a0beeee11dd08498e399ad2251ddaeb7f65bd7d61c559f5e09d1316e072d15adbea012203b62f38542c09284da21f15c323b243277635dd79414339008ce4051a9fca0479890e236e38a7d8c658a08e564de1108996ac66bc9384f470975d4ee38ebe1a0ad0625f3029a2e9699fa410cd2bc451d4f410d4d90817ec0621da307191e8a91a05d253d90bbc44132b194d3ca899556926d317938b13d322ec220ca7f8298c7eaa04d229f73e59a703d6ebeb300a6a39bbece075dadb908d2def26f1758efe8fe3f80";
        accountProof[
            5
        ] = hex"f9017180a0b04dbafe230c935779bba534a95d3dea29bf7b63b9b7840473ee5df2f2f9ae58a0bd79f269303eabceb385448a35049e7e4d1c4992b6e3e606f71f729cbc20da02a06668bb290d5eae353ea85f31acd9df4c10ca8c5bc65024300613f1c36a7f3d7ba0b4264bdf8fac683ef10f3a32e1c8649913ee2abcb2a7fdc449fb57a56ce5584380a0b839bdd9b1aa579553e0cb5cf0bc92756ff87029f56383bb4702682181f1c2f7a034ec47bddba6a8036774e9499b84ea883074dc94f95cd39ff61f7e62ac93c33980a0593aa6dc3eb4412cba462c971e452beef739bf5fc0a94104cef364bfcc5dad88a03fd0e88ea550c7fda049740af94f08827e2a2b572925e690bcceb3c79a82ba85a02c6b56a4c8aaae3dff97af7e9995aabf2f379a786be73a940d8599b21bcee438a0baad6ad1a0e9d1bf2e2ee0c7ffa487e488c9e5147c37cc4d4251f6d81320961b80a0b64300eb154cd6c049ba58a9ffa49477dc5f61ec35896d76ae0ac17bfa999be48080";
        accountProof[
            6
        ] = hex"f85180808080a0c7251f28b5711ad5ebe8dd06341f63c76cdffd1ff89a94b560d6759ca7dafa358080808080808080a0cfac271016fc340ee9607120edb943a2596c6e7b5a9f35001f8e4d974b80a0da808080";
        accountProof[
            7
        ] = hex"f8669d3b673e571fbd6665e87cf8fcba9fb5ed2dcaba58ab6ccf9542818163bbb846f8440180a08aa1155cba880c632d39005ac99902ef3c058f1f78e211654f597e8f5082583ea0f96223f375264fd32d76bb95755f6bd4ee7efe35fbf2daeaa2b76c3421df08ee";

        bytes[] memory storageProof = new bytes[](1);
        storageProof[
            0
        ] = hex"f844a120290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563a1a02a6bdefe81a8e9d36fb1a8f8fb0b3e6e5fb45aa05b8542441a4c552b51e13fa7";

        client.processBridgeRoot(accountProof, storageProof);

        bytes32 bridgeRoot = 0x2a6bdefe81a8e9d36fb1a8f8fb0b3e6e5fb45aa05b8542441a4c552b51e13fa7;
        assertEq(client.getFinalizedBridgeRoot(), bridgeRoot);
    }

    function test_bridgeRootProofFail() public {
        bytes32 stateRoot = 0x0fd6262cbcd27159356419dca723374bb7073bd7402b35f7461704e077a02b48;
        lightClient.set_merkle_root(stateRoot);

        bytes[] memory accountProof = new bytes[](1);
        accountProof[
            0
        ] = hex"f8669d3b673e571fbd6665e87cf8fcba9fb5ed2dcaba58ab6ccf9542818163bbb846f8440180a08aa1155cba880c632d39005ac99902ef3c058f1f78e211654f597e8f5082583ea0f96223f375264fd32d76bb95755f6bd4ee7efe35fbf2daeaa2b76c3421df08ee";

        bytes[] memory storageProof = new bytes[](1);
        storageProof[
            0
        ] = hex"f844a120290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563a1a02a6bdefe81a8e9d36fb1a8f8fb0b3e6e5fb45aa05b8542441a4c552b51e13fa7";

        vm.expectRevert("MerkleTrie: invalid root hash");
        client.processBridgeRoot(accountProof, storageProof);
    }
}
