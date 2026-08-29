// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {TestBase_NetNetFork} from
    "@crane/contracts/protocols/pol/net/test/bases/TestBase_NetNetFork.sol";
import {ROBINHOOD_MAIN} from "@crane/contracts/constants/networks/ROBINHOOD_MAIN.sol";

contract NetNetFork_Bind_Test is TestBase_NetNetFork {
    function test_bind_code_length() public view {
        assertGt(address(net).code.length, 0, "NET");
        assertGt(address(sNet).code.length, 0, "sNET");
        assertGt(address(staking).code.length, 0, "Staking");
        assertGt(address(treasury).code.length, 0, "Treasury");
        assertGt(address(bondDepository).code.length, 0, "BondDepository");
        assertGt(address(taxCollector).code.length, 0, "TaxCollector");
        assertGt(address(pTeam).code.length, 0, "PTeam");
        assertGt(address(turboRouter).code.length, 0, "TurboRouter");
        assertGt(address(pair).code.length, 0, "pair");
        assertGt(address(morpho).code.length, 0, "Morpho");
        assertGt(address(morphoVault).code.length, 0, "steakUSDG");
        assertEq(ROBINHOOD_MAIN.DEFAULT_FORK_BLOCK, 20_714_383);
    }
}
