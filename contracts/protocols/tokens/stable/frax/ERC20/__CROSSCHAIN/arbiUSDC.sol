// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.35;
import "@crane/contracts/protocols/tokens/stable/frax/ERC20/ERC20.sol";

// Mock arbiUSDC token
contract arbiUSDC is ERC20("USD Coin (Arb1)", "USDC") {
    // Nothing here
}