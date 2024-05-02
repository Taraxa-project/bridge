// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

import {InvalidEpoch, NoFinalizedState} from "../errors/ConnectorErrors.sol";
import "../lib/SharedStructs.sol";
import "../lib/Constants.sol";
import "./BridgeConnectorBase.sol";
import "./TokenState.sol";

abstract contract TokenConnectorBase is BridgeConnectorBase {
    address public token; // slot 1 as slot 0 is used by BridgeConnectorBase
    address public otherNetworkAddress; // slot 2
    TokenState public state; // slot 3
    TokenState public finalizedState; // slot 4
    mapping(address => uint256) public toClaim; // slot 5

    /// Events
    event Finalized(uint256 indexed epoch);
    event Initialized(address indexed token, address indexed otherNetworkAddress, address indexed tokenState);
    event StateApplied(bytes state);
    event ClaimAccrued(address indexed account, uint256 value);
    event Claimed(address indexed account, uint256 value);

    function TokenConnectorBase_init(address bridge, address _token, address token_on_other_network)
        public
        onlyInitializing
    {
        __TokenConnectorBase_init(bridge, _token, token_on_other_network);
    }

    function __TokenConnectorBase_init(address bridge, address _token, address token_on_other_network)
        internal
        onlyInitializing
    {
        __BridgeConnectorBase_init(bridge);
        otherNetworkAddress = token_on_other_network;
        token = _token;
        state = new TokenState(1);
        emit Initialized(_token, token_on_other_network, address(state));
    }

    function epoch() public view returns (uint256) {
        return state.epoch();
    }

    function deserializeTransfers(bytes memory data) internal pure returns (Transfer[] memory) {
        return abi.decode(data, (Transfer[]));
    }

    function finalizedSerializedTransfers() internal view returns (bytes memory) {
        Transfer[] memory transfers = finalizedState.getTransfers();
        return abi.encode(transfers);
    }

    function finalize(uint256 epoch_to_finalize) public override onlyOwner returns (bytes32) {
        if (epoch_to_finalize != state.epoch()) {
            revert InvalidEpoch({expected: state.epoch(), actual: epoch_to_finalize});
        }
        finalizedState = state;
        state = new TokenState(epoch_to_finalize + 1);
        emit Finalized(epoch_to_finalize);
        return keccak256(finalizedSerializedTransfers());
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
    function getContractAddress() public view returns (address) {
        return address(token);
    }

    /**
     * @dev Returns the address of the bridged contract in the other network
     */
    function getBridgedContractAddress() external view returns (address) {
        return otherNetworkAddress;
    }

    /**
     * @dev Allows the caller to claim tokens by sending Ether to this function to cover fees.
     * This function is virtual and must be implemented by derived contracts.
     */
    function claim() public payable virtual;
}
