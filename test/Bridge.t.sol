// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import {Test, console2} from "forge-std/Test.sol";
// import {TaraBridge} from "../src/tara/Bridge.sol";

// contract BridgeTest {
//     TaraBridge bridge;

//     function beforeEach() public {
//         bridge = new TaraBridge();
//     }

//     function testRegisterToken() public {
//         bytes32 name = "TARA";
//         bridge.registerToken(address(0), name);
//         assertEq(bridge.tokenAddress(name), address(0));
//         assertEq(bridge.tokens(name).epoch(), 0);
//     }

//     function testTransferToken() public {
//         bytes32 name = "TARA";
//         bridge.registerToken(address(0), name);
//         bridge.transferToken(name, 100);
//         assertEq(bridge.tokens(name).amounts(address(this)), 100);
//     }

//     function testTransferTara() public {
//         bridge.transferTara{value: 100}();
//         assertEq(bridge.tokens("TARA").amounts(address(this)), 100);
//     }

//     function testFinalizeEpoch() public {
//         bytes32 name = "TARA";
//         bridge.registerToken(address(0), name);
//         bridge.transferToken(name, 100);
//         bridge.finalizeEpoch();
//         assertEq(bridge.tokens(name).epoch(), 1);
//         assertEq(bridge.tokens(name).amounts(address(this)), 0);
//     }
// }
