// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {NotBridge, InvalidEpoch, NoFinalizedState, TransferFailed, InsufficientFunds} from "../errors/ConnectorErrors.sol";
import {SharedStructs} from "../lib/SharedStructs.sol";
import {Constants} from "../lib/Constants.sol";
import {TokenState, Transfer} from "./TokenState.sol";
import {BridgeBase} from "../lib/BridgeBase.sol";
import {IBridgeConnector} from "../connectors/IBridgeConnector.sol";

abstract contract TokenConnectorLogic is IBridgeConnector {
    BridgeBase public bridge;
    address public token;
    address public otherNetworkAddress; 
    TokenState public state; 
    TokenState public finalizedState;
    mapping(address => uint256) public toClaim;
    mapping(address => uint256) public feeToClaim;

    /// Events
    event Funded(address indexed sender, address indexed connectorBase, uint256 amount);
    event Refunded(address indexed receiver, uint256 amount);
    event Finalized(uint256 indexed epoch);
    event ClaimAccrued(address indexed account, uint256 value);
    event Claimed(address indexed account, uint256 value);

     modifier onlySettled(uint256 lockAmount, bool isNative) {
        bool alreadyHasBalance = state.hasBalance(msg.sender);
        uint256 fee = bridge.settlementFee();
        uint256 minAmount;
        if (alreadyHasBalance) {
            minAmount = lockAmount;
        } else {
            minAmount = isNative ? fee + lockAmount : fee;
        }
        if (msg.value < minAmount) {
            revert InsufficientFunds(minAmount, msg.value);
        }
        _;
    }

    modifier onlyBridge() {
        if (msg.sender != address(bridge)) {
            revert NotBridge(msg.sender);
        }
        _;
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

    function finalize(uint256 epoch_to_finalize) public virtual override onlyBridge returns (bytes32) {
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
        if (epochTransfers.length > 0) {
            uint256 settlementFeesToForward = bridge.settlementFee() * epochTransfers.length;
            (bool success,) = address(bridge).call{value: settlementFeesToForward}("");
            if (!success) {
                revert TransferFailed(address(bridge), settlementFeesToForward);
            }
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

        if (finalizedState.empty()) {
            return new bytes(0);
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

    function applyState(bytes calldata) external virtual;
}
