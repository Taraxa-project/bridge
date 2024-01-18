// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20MintableBurnable is IERC20 {
    /**
     * @dev Mints a specified amount of tokens and assigns them to the specified account.
     * @param account The address to which the tokens will be minted.
     * @param value The amount of tokens to be minted.
     */
    function mintTo(address account, uint256 value) external;
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
