// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {
    TestBase_PonsFamily
} from "@crane/contracts/protocols/launchpads/ponsFamily/v1/test/bases/TestBase_PonsFamily.sol";
import {PonsLaunchFactory} from
    "@crane/contracts/protocols/launchpads/ponsFamily/v1/PonsLaunchFactory.sol";
import {PonsLauncherToken} from
    "@crane/contracts/protocols/launchpads/ponsFamily/v1/PonsLauncherToken.sol";
import {IPonsLaunchFactory} from
    "@crane/contracts/protocols/launchpads/ponsFamily/v1/interfaces/ILaunchpad.sol";

contract PonsLaunchFactory_launch_Test is TestBase_PonsFamily {
    function test_launchToken_withoutSeedBuy() public {
        PonsLaunchFactory.TokenParams memory params = _defaultTokenParams("NoSeed", "NSD");
        bytes32 saltStart = keccak256("nseed-1");

        uint256 feeBefore = ponsFeeSink.balance;
        address token = _launchWithoutSeed(params, saltStart);

        assertTrue(token != address(0), "token deployed");
        assertTrue(token.code.length > 0, "token has code");
        assertEq(uint16(uint160(token)), 0xbbbb, "vanity suffix bbbb");

        IPonsLaunchFactory.LaunchedToken memory launched = _launched(token);
        assertTrue(launched.exists);
        assertEq(launched.token, token);
        assertEq(launched.deployer, ponsLauncher);
        assertEq(launched.pairedToken, address(weth));
        assertEq(launched.positionManager, address(positionManager));
        assertEq(launched.supply, PONS_SUPPLY);
        assertEq(launched.initialBuyAmount, 0);
        assertEq(launched.poolFee, PONS_POOL_FEE);
        assertGt(launched.positionId, 0);

        address pool = PonsLauncherToken(token).liquidityPool();
        assertTrue(pool != address(0), "pool exists");
        assertEq(_positionOwner(launched.positionId), address(ponsLocker), "NFT with locker");
        // Production locker does not expose isLocked; NFT custody asserted via positionOwner.
        assertEq(ponsFeeSink.balance, feeBefore + PONS_LAUNCH_FEE, "launch fee paid to sink");
        assertEq(PonsLauncherToken(token).totalSupply(), PONS_SUPPLY);
    }

    function test_launchToken_withSeedBuy() public {
        PonsLaunchFactory.TokenParams memory params = _defaultTokenParams("SeedBuy", "SDB");
        // Prefer feeWallet as seed recipient so balance assert is clear.
        address seedRecipient = makeAddr("seedRecipient");
        params.feeWallet = seedRecipient;

        uint256 seedEth = 0.05 ether;
        uint256 value = PONS_LAUNCH_FEE + seedEth;
        bytes32 saltStart = keccak256("seed-1");

        address token = _launch(params, saltStart, value);

        IPonsLaunchFactory.LaunchedToken memory launched = _launched(token);
        assertEq(launched.initialBuyAmount, seedEth, "seed amount recorded");
        assertGt(PonsLauncherToken(token).balanceOf(seedRecipient), 0, "seed recipient got tokens");
        assertEq(ponsLocker.feeRedirects(token), seedRecipient, "fee redirect set");
    }

    function test_launchToken_revertsWhenFeeUnderpaid() public {
        PonsLaunchFactory.TokenParams memory params = _defaultTokenParams("Underpay", "UND");
        vm.prank(ponsLauncher);
        vm.expectRevert(PonsLaunchFactory.LaunchFeeNotPaid.selector);
        ponsFactory.launchToken{value: PONS_LAUNCH_FEE - 1}(
            params, ponsLaunchConfigId, ponsDexId, keccak256("underpay")
        );
    }

    function test_launchToken_revertsWhenLaunchDisabled() public {
        vm.prank(ponsOwner);
        ponsFactory.setLaunchEnabled(false);

        PonsLaunchFactory.TokenParams memory params = _defaultTokenParams("Disabled", "DIS");
        vm.prank(ponsLauncher);
        vm.expectRevert(PonsLaunchFactory.NotWhitelisted.selector);
        ponsFactory.launchToken{value: PONS_LAUNCH_FEE}(
            params, ponsLaunchConfigId, ponsDexId, keccak256("disabled")
        );
    }
}
