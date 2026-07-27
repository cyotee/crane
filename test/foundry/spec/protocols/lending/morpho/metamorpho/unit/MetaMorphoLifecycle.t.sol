// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {TestBase_MetaMorpho} from
    "@crane/contracts/protocols/lending/morpho/metamorpho/test/bases/TestBase_MetaMorpho.sol";

/// @title MetaMorphoLifecycle
/// @notice Hermetic MetaMorpho V1.1 deposit/withdraw with exact share math.
contract MetaMorphoLifecycle_Test is TestBase_MetaMorpho {
    function test_deposit_withdraw_exact() public {
        uint256 assets = 100e18;
        address user = makeAddr("vaultUser");

        loanToken.setBalance(user, assets);
        vm.startPrank(user);
        loanToken.approve(address(vault), type(uint256).max);

        uint256 preview = vault.previewDeposit(assets);
        uint256 shares = vault.deposit(assets, user);
        assertEq(shares, preview, "shares == previewDeposit");
        assertEq(vault.balanceOf(user), shares);
        assertEq(vault.totalAssets(), assets);

        uint256 previewRedeem = vault.previewRedeem(shares);
        uint256 assetsOut = vault.redeem(shares, user, user);
        assertEq(assetsOut, previewRedeem, "assetsOut == previewRedeem");
        assertEq(vault.balanceOf(user), 0);
        // First depositor may leave dust from virtual shares offset depending on OZ ERC4626 offset.
        assertLe(assets - assetsOut, 1e6, "withdraw nearly full");
        vm.stopPrank();
    }

    function test_factory_deploys_with_morpho() public view {
        assertEq(address(vault.MORPHO()), address(morpho));
        assertEq(vault.asset(), address(loanToken));
        assertEq(vault.owner(), OWNER);
    }
}
