// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "@crane/contracts/protocols/tokens/stable/frax/ERC20/ERC20.sol";

contract FRAX3CRV_V2_Mock is ERC20 {
    constructor() ERC20("Curve.fi Factory USD Metapool: Frax", "FRAX3CRV-f-2") {}
}
