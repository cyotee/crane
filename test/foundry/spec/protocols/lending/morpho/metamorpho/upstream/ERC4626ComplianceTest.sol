// SPDX-License-Identifier: GPL-2.0-or-later
// Ported from morpho-org/metamorpho-v1.1@bcc003108c0fbb9f715566207c52a1d3f279c5c3 — path: test/ERC4626ComplianceTest.sol
pragma solidity ^0.8.0;

import "erc4626-tests/ERC4626.test.sol";

import {IntegrationTest} from "./helpers/IntegrationTest.sol";

contract ERC4626ComplianceTest is IntegrationTest, ERC4626Test {
    function setUp() public override(IntegrationTest, ERC4626Test) {
        super.setUp();

        _underlying_ = address(loanToken);
        _vault_ = address(vault);
        _delta_ = 0;
        _vaultMayBeEmpty = true;
        _unlimitedAmount = true;

        _setCap(allMarkets[0], 100e18);
        _sortSupplyQueueIdleLast();
    }
}
