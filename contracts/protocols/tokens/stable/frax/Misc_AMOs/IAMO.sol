// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.35;

interface IAMO {
    function dollarBalances() external view returns (uint256 frax_val_e18, uint256 collat_val_e18);
}
