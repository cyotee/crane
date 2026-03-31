// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {IWETH} from "@crane/contracts/interfaces/protocols/tokens/wrappers/weth/v9/IWETH.sol";
import {WETH9} from "@crane/contracts/protocols/tokens/wrappers/weth/v9/WETH9.sol";

/**
 * @title TestBase_SharedConstants
 * @notice Shared test constants and common fixtures used across TestBase contracts.
 * @dev This centralizes common declarations (like `TEST_AMOUNT` and `weth`) so
 *      multiple TestBase contracts can inherit without causing duplicate symbol
 *      declarations in downstream test contracts.
 */
abstract contract TestBase_SharedConstants is Test {
    // Standard test amount used by many test bases
    uint256 internal constant TEST_AMOUNT = 1000e18;

    // Shared WETH instance used by tests; some forks will overwrite this to the
    // mainnet WETH address during their own setUp() if needed.
    IWETH internal weth;

    function setUpSharedConstants() internal virtual {
        // Only deploy a local WETH9 when none is present. Fork setups may replace
        // this value with mainnet addresses during their own binding steps.
        if (address(weth) == address(0)) {
            weth = IWETH(address(new WETH9()));
            vm.label(address(weth), "WETH9_Shared");
        }
    }
}
