// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../connectors/IERC20MintableBurnable.sol";
import "forge-std/console.sol";

contract TestERC20 is ERC20, IERC20MintableBurnable {
    constructor(string memory symbol) ERC20(symbol, symbol) {}

    /**
     * @dev Mints a specified amount of tokens and assigns them to the specified account.
     * @param receiver The address to which the tokens will be minted.
     * @param amount The amount of tokens to be minted.
     */
    function mintTo(address receiver, uint256 amount) public {
        _mint(receiver, amount);
    }

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
     */
    function burnFrom(address account, uint256 value) public virtual {
        _spendAllowance(account, _msgSender(), value);
        _burn(account, value);
    }
}
