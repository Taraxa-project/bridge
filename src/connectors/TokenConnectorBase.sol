// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {InvalidEpoch, NoFinalizedState, TransferFailed} from "../errors/ConnectorErrors.sol";
import {SharedStructs} from "../lib/SharedStructs.sol";
import {Constants} from "../lib/Constants.sol";
import {BridgeConnectorBase} from "./BridgeConnectorBase.sol";
import {TokenState, Transfer} from "./TokenState.sol";
import {BridgeBase} from "../lib/BridgeBase.sol";

abstract contract TokenConnectorBase is BridgeConnectorBase {
    using SafeERC20 for IERC20;

    IERC20 public token; // slot 1 as slot 0 is used by BridgeConnectorBase
    address public otherNetworkAddress; // slot 2
    TokenState public state; // slot 3
    TokenState public finalizedState; // slot 4
    mapping(address => uint256) public toClaim; // slot 5

    /// Events
    event Finalized(uint256 indexed epoch);
    event ClaimAccrued(address indexed account, uint256 value);
    event Claimed(address indexed account, uint256 value);

    function TokenConnectorBase_init(BridgeBase _bridge, IERC20 _token, address token_on_other_network)
        public
        onlyInitializing
    {
        __TokenConnectorBase_init(_bridge, _token, token_on_other_network);
    }

    function __TokenConnectorBase_init(BridgeBase _bridge, IERC20 _token, address token_on_other_network)
        internal
        onlyInitializing
    {
        require(
            address(_bridge) != address(0) && address(_token) != address(0) && token_on_other_network != address(0),
            "TokenConnectorBase: invalid bridge, token, or token_on_other_network"
        );
        __BridgeConnectorBase_init(_bridge);
        otherNetworkAddress = token_on_other_network;
        token = _token;
        state = new TokenState(0);
    }

    function epoch() public view returns (uint256) {
        return state.epoch();
    }

    function deserializeTransfers(bytes memory data) internal pure returns (Transfer[] memory) {
        return abi.decode(data, (Transfer[]));
    }

    function finalizedSerializedTransfers() internal view returns (bytes memory) {
        return abi.encode(finalizedState.getTransfers());
    }

    function isStateEmpty() external view override returns (bool) {
        return state.empty();
    }

    function getStateLength() external view returns (uint256) {
        return state.getStateLength();
    }

    function finalize(uint256 epoch_to_finalize) public override onlyOwner returns (bytes32) {
        if (epoch_to_finalize != state.epoch()) {
            revert InvalidEpoch({expected: state.epoch(), actual: epoch_to_finalize});
        }

        // increase epoch if there are no pending transfers
        if (state.empty() && address(finalizedState) != address(0) && finalizedState.empty()) {
            state.increaseEpoch();
            finalizedState.increaseEpoch();
        } else {
            finalizedState = state;
            state = new TokenState(epoch_to_finalize + 1);
        }
        Transfer[] memory epochTransfers = finalizedState.getTransfers();
        uint256 settlementFeesToForward = bridge.settlementFee() * epochTransfers.length;
        (bool success,) = address(bridge).call{value: settlementFeesToForward}("");
        if (!success) {
            revert TransferFailed(address(bridge), settlementFeesToForward);
        }
        emit Finalized(epoch_to_finalize);
        return keccak256(abi.encode(epochTransfers));
    }

    /**
     * @dev Retrieves the finalized state of the bridgeable contract.
     * @return A bytes serialized finalized state
     */
    function getFinalizedState() public view override returns (bytes memory) {
        if (address(finalizedState) == address(0)) {
            revert NoFinalizedState();
        }

        return finalizedSerializedTransfers();
    }

    /**
     * @dev Returns the address of the underlying contract in this network
     */
    function getContractSource() public view returns (address) {
        return address(token);
    }

    /**
     * @dev Returns the address of the bridged contract on the other network
     */
    function getContractDestination() external view returns (address) {
        return otherNetworkAddress;
    }
}
