// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "./BetterERC20PermitTargetTest.sol";

/**
 * @title BetterERC20PermitTarget_IERC20Permit_noncesTest
 * @dev Test suite for the nonces function of BetterERC20PermitTarget
 */
contract BetterERC20PermitTarget_IERC20Permit_noncesTest is BetterERC20PermitTargetTest {
    function test_IERC20Permit_nonces_BetterERC20PermitTarget() public view {
        // Check initial nonce is zero for an address
        assertEq(token.nonces(address(this)), 0);
        assertEq(token.nonces(address(1)), 0);

        // The nonce would normally increment after a permit is executed,
        // but we can't test that in a view function
    }
}
