// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import {BetterAddress} from '@crane/contracts/utils/BetterAddress.sol';
import {ERC20} from "@crane/contracts/tokens/ERC20/ERC20.sol";
import {IWETH} from "@crane/contracts/external/balancer/v3/interfaces/contracts/solidity-utils/misc/IWETH.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IERC20Events} from "@crane/contracts/interfaces/IERC20Events.sol";

/// @notice WETH test token for Balancer testing
/// @dev Implements IWETH interface
contract WETHTestToken is ERC20, IWETH {
    // Events taken from actual WETH implementation in mainnet
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    constructor() ERC20("Wrapped Ether", "WETH") {}

    receive() external payable {
        deposit();
    }

    function deposit() public payable override {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) public override {
        _burn(msg.sender, wad);
        BetterAddress.sendValue(payable(msg.sender), wad);
        emit Withdrawal(msg.sender, wad);
    }

    // ============ IERC20 overrides for diamond inheritance ============

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override(ERC20, IERC20Metadata) returns (string memory) {
        return ERC20.name();
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() public view virtual override(ERC20, IERC20Metadata) returns (string memory) {
        return ERC20.symbol();
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * Defaults to 18. Override to change.
     */
    function decimals() public view virtual override(ERC20, IERC20Metadata) returns (uint8) {
        return ERC20.decimals();
    }

    function totalSupply() public view override(ERC20, IERC20) returns (uint256) {
        return ERC20.totalSupply();
    }

    function balanceOf(address account) public view override(ERC20, IERC20) returns (uint256) {
        return ERC20.balanceOf(account);
    }

    function transfer(address to, uint256 value) public override(ERC20, IERC20) returns (bool) {
        return ERC20.transfer(to, value);
    }

    function allowance(address owner, address spender) public view override(ERC20, IERC20) returns (uint256) {
        return ERC20.allowance(owner, spender);
    }

    function approve(address spender, uint256 value) public override(ERC20, IERC20) returns (bool) {
        return ERC20.approve(spender, value);
    }

    function transferFrom(address from, address to, uint256 value) public override(ERC20, IERC20) returns (bool) {
        return ERC20.transferFrom(from, to, value);
    }
}
