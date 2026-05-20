// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.35;
import "@crane/contracts/protocols/tokens/stable/frax/ERC20/ERC20.sol";

// Mock anyUSDC token
contract anyUSDC is ERC20("USD Coin", "USDC") {
    // Nothing here
}