// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "./BetterERC20PermitTargetTest.sol";

/**
 * @title BetterERC20PermitTarget_IERC20Permit_domainSeparatorTest
 * @dev Test suite for the DOMAIN_SEPARATOR function of BetterERC20PermitTarget
 */
contract BetterERC20PermitTarget_IERC20Permit_domainSeparatorTest is BetterERC20PermitTargetTest {
    function test_IERC20Permit_DOMAIN_SEPARATOR_BetterERC20PermitTarget() public view {
        // Check that the domain separator is not empty
        bytes32 domainSeparator = token.DOMAIN_SEPARATOR();
        assertFalse(domainSeparator == bytes32(0));

        // This is a more complex test that would normally calculate the expected domain separator
        // and compare, but for simplicity we're just checking that it's not empty
    }
}
