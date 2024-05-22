// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../connectors/IERC20MintableBurnable.sol";

contract TestERC20 is ERC20, Ownable, IERC20MintableBurnable {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable(msg.sender) {}

    /**
     * @dev Mints a specified amount of tokens and assigns them to the specified account.
     * @param receiver The address to which the tokens will be minted.
     * @param amount The amount of tokens to be minted.
     */
    function mintTo(address receiver, uint256 amount) public onlyOwner {
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
    function burnFrom(address account, uint256 value) public virtual onlyOwner {
        _spendAllowance(account, _msgSender(), value);
        _burn(account, value);
    }
}
