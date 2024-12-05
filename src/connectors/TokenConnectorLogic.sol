// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {TransferFailed, InsufficientFunds} from "../errors/CommonErrors.sol";
import {NotBridge, InvalidEpoch, NoFinalizedState} from "../errors/ConnectorErrors.sol";
import {TokenState, Transfer} from "./TokenState.sol";
import {BridgeBase} from "../lib/BridgeBase.sol";
import {IBridgeConnector} from "../connectors/IBridgeConnector.sol";

abstract contract TokenConnectorLogic is IBridgeConnector {
    BridgeBase public bridge;
    address public token;
    address public otherNetworkAddress;
    TokenState public state;
    bytes public finalizedState;

    /// Events
    event Finalized(uint256 indexed epoch);
    event AssetBridged(address indexed connector, address indexed account, uint256 value);

    modifier onlySettled() {
        uint256 fee = estimateSettlementFee(msg.sender);
        if (msg.value < fee) {
            revert InsufficientFunds(fee, msg.value);
        }
        _;
    }

    modifier onlyBridge() {
        if (msg.sender != address(bridge)) {
            revert NotBridge(msg.sender);
        }
        _;
    }

    function estimateSettlementFee(address locker) public view returns (uint256) {
        bool alreadyHasBalance = state.hasBalance(locker);
        uint256 fee = bridge.settlementFee();
        if (!alreadyHasBalance) {
            return fee;
        }
        return 0;
    }

    function epoch() public view returns (uint256) {
        return state.epoch();
    }

    function decodeTransfers(bytes memory data) internal pure returns (Transfer[] memory) {
        return abi.decode(data, (Transfer[]));
    }

    function isStateEmpty() external view override returns (bool) {
        return state.empty();
    }

    function getStateLength() external view returns (uint256) {
        return state.getStateLength();
    }

    function finalize(uint256 epoch_to_finalize) public virtual override onlyBridge returns (bytes32) {
        // if epoch == 0 then it is the first epoch for this connector and epoch sohuld be synced with the bridge contract
        if (state.epoch() != 0 && epoch_to_finalize != state.epoch()) {
            revert InvalidEpoch({expected: state.epoch(), actual: epoch_to_finalize});
        }
        state.setEpoch(epoch_to_finalize + 1);

        Transfer[] memory transfers = state.getTransfers();
        // if no transfers was made, then the finalized state should be empty
        if (transfers.length == 0) {
            finalizedState = new bytes(0);
        } else {
            finalizedState = abi.encode(transfers);
            state.cleanup();
            uint256 settlementFeesToForward = bridge.settlementFee() * transfers.length;
            (bool success,) = address(bridge).call{value: settlementFeesToForward}("");
            if (!success) {
                revert TransferFailed(address(bridge), settlementFeesToForward);
            }
        }
        emit Finalized(epoch_to_finalize);
        return keccak256(finalizedState);
    }

    /**
     * @dev Retrieves the finalized state of the bridgeable contract.
     * @return A bytes serialized finalized state
     */
    function getFinalizedState() public view override returns (bytes memory) {
        return finalizedState;
    }

    /**
     * @dev Returns the address of the underlying contract in this network
     */
    function getSourceContract() external view returns (address) {
        return token;
    }

    /**
     * @dev Returns the address of the bridged contract on the other network
     */
    function getDestinationContract() external view returns (address) {
        return otherNetworkAddress;
    }

    function applyState(bytes calldata) external virtual;
}
