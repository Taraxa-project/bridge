// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";

interface IERC20MintableBurnable is IERC20Upgradeable {
    /**
     * @dev Mints a specified amount of tokens and assigns them to the specified account.
     * @param receiver The address to which the tokens will be minted.
     * @param amount The amount of tokens to be minted.
     */
    function mintTo(address receiver, uint256 amount) external;

    /**
     * @dev Destroys a `value` amount of tokens from `account`, deducting from
     * the caller's allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `value`.
     * @param account The address from which the tokens will be burnt.
     * @param value The amount of tokens to burn.
     */

    function burnFrom(address account, uint256 value) external;
}
