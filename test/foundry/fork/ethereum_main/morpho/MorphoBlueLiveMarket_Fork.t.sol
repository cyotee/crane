// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {IMorpho, Id, MarketParams, Market} from "@crane/contracts/external/morpho/blue/interfaces/IMorpho.sol";
import {MorphoBalancesLib} from
    "@crane/contracts/external/morpho/blue/libraries/periphery/MorphoBalancesLib.sol";
import {MorphoLib} from "@crane/contracts/external/morpho/blue/libraries/periphery/MorphoLib.sol";
import {MarketParamsLib} from "@crane/contracts/external/morpho/blue/libraries/MarketParamsLib.sol";
import {TestBase_MorphoBlueFork} from "./TestBase_MorphoBlueFork.sol";

/// @title MorphoBlueLiveMarket_Fork
/// @notice View/math + small supply/withdraw against a known liquid USDC/WETH Morpho Blue market.
/// @dev loan=USDC 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
///      coll=WETH 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
///      irm=AdaptiveCurveIRM, lltv=86%. Market ids verified liquid at ETHEREUM_MAIN.DEFAULT_FORK_BLOCK.
contract MorphoBlueLiveMarket_Fork_Test is TestBase_MorphoBlueFork {
    using MorphoBalancesLib for IMorpho;
    using MorphoLib for IMorpho;
    using MarketParamsLib for MarketParams;

    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// @dev Known liquid Morpho Blue market (USDC loan / WETH collateral) — oracle from live params at fork.
    MarketParams internal marketParams;
    Id internal marketId;

    function setUp() public override {
        super.setUp();

        // Morpho Blue has no market enumeration. Candidate market ids (USDC/WETH 86% LLTV, different oracles)
        // verified present with totalSupplyAssets > 0 at DEFAULT_FORK_BLOCK (25_000_000) via Morpho API + cast.
        bytes32[3] memory candidates = [
            // Primary liquid USDC/WETH 86% (creation ~24.37M)
            bytes32(0x94b823e6bd8ea533b4e33fbc307faea0b307301bc48763acc4d4aa4def7636cd),
            // Older USDC/WETH 86% market (creation ~19.03M)
            bytes32(0x7dde86a1e94561d9690ec678db673c1a6396365f7d1d65e129c5fff0990ff758),
            // Fallback: USDC/wstETH 86% (historically liquid; pair filter still accepts USDC loan only for WETH coll)
            bytes32(0xb323495f7e4148be5643a4ea4a8221eef163e4bccfdedc2a6f4696baacbc86cc)
        ];
        for (uint256 i; i < candidates.length; ++i) {
            MarketParams memory p = liveMorpho.idToMarketParams(Id.wrap(candidates[i]));
            if (p.loanToken == address(0)) continue;
            // Prefer true USDC/WETH; last candidate is USDC/wstETH only if both WETH markets vanish at fork block.
            bool pairOk = (p.loanToken == USDC && p.collateralToken == WETH)
                || (p.loanToken == WETH && p.collateralToken == USDC)
                || (i == candidates.length - 1 && p.loanToken == USDC && p.collateralToken != address(0));
            if (pairOk && liveMorpho.market(Id.wrap(candidates[i])).totalSupplyAssets > 0) {
                marketId = Id.wrap(candidates[i]);
                marketParams = p;
                break;
            }
        }
        require(marketParams.loanToken != address(0), "no liquid USDC market at fork block");
        require(marketParams.loanToken == USDC, "loan token not USDC");
    }

    function test_live_market_params_bound() public view {
        MarketParams memory p = liveMorpho.idToMarketParams(marketId);
        assertEq(p.loanToken, USDC, "loanToken");
        assertTrue(p.collateralToken != address(0), "collateral set");
        assertEq(p.irm, liveIrm, "irm");
        assertTrue(liveMorpho.isLltvEnabled(p.lltv), "lltv enabled");
    }

    function test_live_balancesLib_matches_market_storage() public view {
        Market memory m = liveMorpho.market(marketId);
        uint256 expectedSupply = liveMorpho.expectedTotalSupplyAssets(marketParams);
        uint256 expectedBorrow = liveMorpho.expectedTotalBorrowAssets(marketParams);

        // If lastUpdate < now, expected may be higher than stored (pending interest).
        assertGe(expectedSupply, m.totalSupplyAssets, "expected supply >= stored");
        assertGe(expectedBorrow, m.totalBorrowAssets, "expected borrow >= stored");
    }

    function test_live_small_supply_withdraw_exact_delta() public {
        address user = makeAddr("liveUser");
        uint256 amount = 1e6; // 1 USDC (6 decimals)

        deal(USDC, user, amount);
        vm.startPrank(user);
        (bool ok,) = USDC.call(abi.encodeWithSignature("approve(address,uint256)", address(liveMorpho), type(uint256).max));
        require(ok, "approve");

        uint256 beforeUser = _balance(USDC, user);
        uint256 beforeMorpho = _balance(USDC, address(liveMorpho));

        (uint256 assetsSupplied, uint256 shares) = liveMorpho.supply(marketParams, amount, 0, user, "");
        assertEq(assetsSupplied, amount);
        assertGt(shares, 0);
        assertEq(_balance(USDC, user), beforeUser - amount);
        assertEq(_balance(USDC, address(liveMorpho)), beforeMorpho + amount);

        (uint256 assetsWithdrawn, uint256 sharesBurned) =
            liveMorpho.withdraw(marketParams, 0, shares, user, user);
        assertEq(sharesBurned, shares);
        assertGe(assetsWithdrawn, amount - 1); // allow 1 wei share rounding
        vm.stopPrank();
    }

    function _balance(address token, address who) internal view returns (uint256) {
        (bool ok, bytes memory data) = token.staticcall(abi.encodeWithSignature("balanceOf(address)", who));
        require(ok && data.length >= 32, "balanceOf");
        return abi.decode(data, (uint256));
    }
}
