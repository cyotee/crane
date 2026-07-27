// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {console2} from "forge-std/console2.sol";
import {Script} from "forge-std/Script.sol";

import {IERC20Metadata} from
    "@crane/contracts/external/openzeppelin-contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {BaseSplitCodeFactory} from
    "@crane/contracts/protocols/perps/pendle/core/libraries/BaseSplitCodeFactory.sol";

import {PendleYieldContractFactory} from
    "@crane/contracts/protocols/perps/pendle/core/YieldContracts/PendleYieldContractFactory.sol";
import {PendleYieldToken} from
    "@crane/contracts/protocols/perps/pendle/core/YieldContracts/PendleYieldToken.sol";
import {PendleMarketFactoryV3} from
    "@crane/contracts/protocols/perps/pendle/core/Market/v3/PendleMarketFactoryV3.sol";
import {PendleMarketV3} from
    "@crane/contracts/protocols/perps/pendle/core/Market/v3/PendleMarketV3.sol";
import {PendleERC20SY} from
    "@crane/contracts/protocols/perps/pendle/core/StandardizedYield/implementations/PendleERC20SY.sol";
import {PendlePoolDeployHelper} from
    "@crane/contracts/protocols/perps/pendle/offchain-helpers/PendlePoolDeployHelper.sol";
import {PendlePYLpOracle} from
    "@crane/contracts/protocols/perps/pendle/oracles/PendlePYLpOracle.sol";
import {ERC1967Proxy} from
    "@crane/contracts/external/openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {PendleRouterV4} from
    "@crane/contracts/protocols/perps/pendle/router/PendleRouterV4.sol";
import {ActionStorageV4} from
    "@crane/contracts/protocols/perps/pendle/router/ActionStorageV4.sol";
import {ActionMiscV3} from
    "@crane/contracts/protocols/perps/pendle/router/ActionMiscV3.sol";
import {ActionAddRemoveLiqV3} from
    "@crane/contracts/protocols/perps/pendle/router/ActionAddRemoveLiqV3.sol";
import {ActionSwapPTV3} from
    "@crane/contracts/protocols/perps/pendle/router/ActionSwapPTV3.sol";
import {ActionSwapYTV3} from
    "@crane/contracts/protocols/perps/pendle/router/ActionSwapYTV3.sol";
import {ActionCallbackV3} from
    "@crane/contracts/protocols/perps/pendle/router/ActionCallbackV3.sol";

import {IPActionStorageV4} from
    "@crane/contracts/protocols/perps/pendle/interfaces/IPActionStorageV4.sol";
import {IPActionMiscV3} from
    "@crane/contracts/protocols/perps/pendle/interfaces/IPActionMiscV3.sol";
import {IPActionAddRemoveLiqV3} from
    "@crane/contracts/protocols/perps/pendle/interfaces/IPActionAddRemoveLiqV3.sol";
import {IPActionSwapPTV3} from
    "@crane/contracts/protocols/perps/pendle/interfaces/IPActionSwapPTV3.sol";
import {IPActionSwapYTV3} from
    "@crane/contracts/protocols/perps/pendle/interfaces/IPActionSwapYTV3.sol";
import {IPActionCallbackV3} from
    "@crane/contracts/protocols/perps/pendle/interfaces/IPActionCallbackV3.sol";
import {IPMarketSwapCallback} from
    "@crane/contracts/protocols/perps/pendle/interfaces/IPMarketSwapCallback.sol";
import {IPLimitRouterCallback} from
    "@crane/contracts/protocols/perps/pendle/interfaces/IPLimitRouter.sol";
import {IPMarketFactoryV3} from
    "@crane/contracts/protocols/perps/pendle/interfaces/IPMarketFactoryV3.sol";
import {IPYieldContractFactory} from
    "@crane/contracts/protocols/perps/pendle/interfaces/IPYieldContractFactory.sol";
import {IStandardizedYield} from
    "@crane/contracts/protocols/perps/pendle/interfaces/IStandardizedYield.sol";
import {IPMarket} from
    "@crane/contracts/protocols/perps/pendle/interfaces/IPMarket.sol";

/// @dev Minimal gauge controller so PendleMarketV3 construction can read `pendle()`.
contract BcPendleGaugeControllerStub {
    address public immutable pendle;

    constructor(address pendle_) {
        pendle = pendle_;
    }
}

/// @dev Tiny ERC20 used only as the PENDLE token pointer for gauge stub (not a product token).
contract BcPendleTokenStub {
    string public constant name = "PENDLE-STUB";
    string public constant symbol = "PENDLE";
    uint8 public constant decimals = 18;
}

/// @notice Phase 13a Pendle seed deploy: factories + router + one ERC20 SY + PT/YT + market.
/// @dev Plain CREATE path (Phase-9 style) so hermetic/fork tests and operator scripts share one graph.
///      No vm.etch CREATE2 factory. No live BC broadcast.
contract BcPendlePhase13aDeploy is Script {
    /// @dev ~0.3% fee: ln(1.003) in Pendle fixed-point.
    uint80 internal constant DEFAULT_LN_FEE_RATE_ROOT = uint80(uint256(2_995_732_273)); // approx ln(1.003)*1e18

    struct DeployResult {
        address yieldContractFactory;
        address marketFactory;
        address router;
        address actionStorage;
        address actionMisc;
        address actionAddRemoveLiq;
        address actionSwapPT;
        address actionSwapYT;
        address actionCallback;
        address poolDeployHelper;
        address pyLpOracle;
        address gaugeControllerStub;
        address pendleTokenStub;
        address sy;
        address pt;
        address yt;
        address market;
        address underlying;
        uint32 expiry;
    }

    /// @notice Deploy full Pendle seed surface for `underlying` (e.g. BC WETH or hermetic ERC20).
    /// @param treasury Fee recipient / factory owner roles.
    /// @param underlying Asset for PendleERC20SY (1:1 SY wrapper).
    function deploySeed(address treasury, address underlying) public returns (DeployResult memory r) {
        require(treasury != address(0), "13a: treasury zero");
        require(underlying != address(0), "13a: underlying zero");
        require(underlying.code.length > 0, "13a: underlying no code");

        r.underlying = underlying;
        _deployFactories(r, treasury);
        _deployRouterAndHelpers(r, treasury);
        _deploySyMarketAndTransfer(r, treasury);

        require(r.router.code.length > 0, "13a: router");
        require(r.sy.code.length > 0, "13a: sy");
        require(r.pt.code.length > 0 && r.yt.code.length > 0, "13a: pt/yt");
        require(r.market.code.length > 0, "13a: market");
        require(IPMarketFactoryV3(r.marketFactory).isValidMarket(r.market), "13a: invalid market");
        (IStandardizedYield syR,,) = IPMarket(r.market).readTokens();
        require(address(syR) == r.sy, "13a: market SY mismatch");

        console2.log("13a yieldContractFactory", r.yieldContractFactory);
        console2.log("13a marketFactory", r.marketFactory);
        console2.log("13a router", r.router);
        console2.log("13a sy", r.sy);
        console2.log("13a pt", r.pt);
        console2.log("13a yt", r.yt);
        console2.log("13a market", r.market);
        console2.log("13a pyLpOracle", r.pyLpOracle);
        console2.log("13a expiry", r.expiry);

        return r;
    }

    function _deployFactories(DeployResult memory r, address treasury) internal {
        r.yieldContractFactory = _deployYieldContractFactory(treasury);
        r.pendleTokenStub = address(new BcPendleTokenStub());
        r.gaugeControllerStub = address(new BcPendleGaugeControllerStub(r.pendleTokenStub));
        r.marketFactory = _deployMarketFactory(r.yieldContractFactory, treasury, r.gaugeControllerStub);
    }

    function _deployYieldContractFactory(address treasury) internal returns (address) {
        (address a, uint256 sa, address b, uint256 sb) =
            BaseSplitCodeFactory.setCreationCode(type(PendleYieldToken).creationCode);
        PendleYieldContractFactory ycf = new PendleYieldContractFactory(a, sa, b, sb);
        ycf.initialize(uint96(1 days), uint128(1e17), uint128(2e17), treasury);
        return address(ycf);
    }

    function _deployMarketFactory(address ycf, address treasury, address gauge) internal returns (address) {
        (address a, uint256 sa, address b, uint256 sb) =
            BaseSplitCodeFactory.setCreationCode(type(PendleMarketV3).creationCode);
        return address(
            new PendleMarketFactoryV3(ycf, a, sa, b, sb, treasury, 80, address(0), gauge)
        );
    }

    function _deployRouterAndHelpers(DeployResult memory r, address treasury) internal {
        r.actionStorage = address(new ActionStorageV4());
        r.actionMisc = address(new ActionMiscV3());
        r.actionAddRemoveLiq = address(new ActionAddRemoveLiqV3());
        r.actionSwapPT = address(new ActionSwapPTV3());
        r.actionSwapYT = address(new ActionSwapYTV3());
        r.actionCallback = address(new ActionCallbackV3());
        // Owner must be address(this) to wire selectors; transfer to treasury after.
        r.router = address(new PendleRouterV4(address(this), r.actionStorage));
        _wireRouterSelectors(r);
        IPActionStorageV4(r.router).transferOwnership(treasury, true, false);

        r.poolDeployHelper =
            address(new PendlePoolDeployHelper(r.router, r.yieldContractFactory, r.marketFactory));
        // PendlePYLpOracle disables initializers in ctor (proxy pattern) — deploy behind ERC1967.
        PendlePYLpOracle oracleImpl = new PendlePYLpOracle();
        r.pyLpOracle = address(
            new ERC1967Proxy(
                address(oracleImpl), abi.encodeCall(PendlePYLpOracle.initialize, (uint16(1000)))
            )
        );
    }

    function _deploySyMarketAndTransfer(DeployResult memory r, address treasury) internal {
        string memory sym = IERC20Metadata(r.underlying).symbol();
        r.sy = address(
            new PendleERC20SY(string.concat("SY ", sym), string.concat("SY-", sym), r.underlying)
        );

        uint32 day = uint32(1 days);
        r.expiry = uint32(((block.timestamp / day) + 90) * day);
        (r.pt, r.yt) =
            PendleYieldContractFactory(r.yieldContractFactory).createYieldContract(r.sy, r.expiry, true);

        r.market = PendleMarketFactoryV3(r.marketFactory).createNewMarket(
            r.pt, int256(50e18), int256(12e17), DEFAULT_LN_FEE_RATE_ROOT
        );

        PendleYieldContractFactory(r.yieldContractFactory).transferOwnership(treasury, true, false);
        PendleMarketFactoryV3(r.marketFactory).transferOwnership(treasury, true, false);
    }

    function _wireRouterSelectors(DeployResult memory r) internal {
        IPActionStorageV4.SelectorsToFacet[] memory arr = new IPActionStorageV4.SelectorsToFacet[](6);

        // ActionStorage (already has setSelectorToFacets; re-register ownership + read)
        {
            bytes4[] memory s = new bytes4[](6);
            s[0] = IPActionStorageV4.setSelectorToFacets.selector;
            s[1] = IPActionStorageV4.owner.selector;
            s[2] = IPActionStorageV4.pendingOwner.selector;
            s[3] = IPActionStorageV4.transferOwnership.selector;
            s[4] = IPActionStorageV4.claimOwnership.selector;
            s[5] = IPActionStorageV4.selectorToFacet.selector;
            arr[0] = IPActionStorageV4.SelectorsToFacet({facet: r.actionStorage, selectors: s});
        }

        // ActionMiscV3 — mint/redeem core
        {
            bytes4[] memory s = new bytes4[](12);
            s[0] = IPActionMiscV3.mintSyFromToken.selector;
            s[1] = IPActionMiscV3.redeemSyToToken.selector;
            s[2] = IPActionMiscV3.mintPyFromToken.selector;
            s[3] = IPActionMiscV3.redeemPyToToken.selector;
            s[4] = IPActionMiscV3.mintPyFromSy.selector;
            s[5] = IPActionMiscV3.redeemPyToSy.selector;
            s[6] = IPActionMiscV3.redeemDueInterestAndRewards.selector;
            s[7] = IPActionMiscV3.swapTokenToToken.selector;
            s[8] = IPActionMiscV3.swapTokenToTokenViaSy.selector;
            s[9] = IPActionMiscV3.multicall.selector;
            s[10] = IPActionMiscV3.boostMarkets.selector;
            s[11] = IPActionMiscV3.simulate.selector;
            arr[1] = IPActionStorageV4.SelectorsToFacet({facet: r.actionMisc, selectors: s});
        }

        // Add/remove liquidity
        {
            bytes4[] memory s = new bytes4[](12);
            s[0] = IPActionAddRemoveLiqV3.addLiquidityDualTokenAndPt.selector;
            s[1] = IPActionAddRemoveLiqV3.addLiquidityDualSyAndPt.selector;
            s[2] = IPActionAddRemoveLiqV3.addLiquiditySinglePt.selector;
            s[3] = IPActionAddRemoveLiqV3.addLiquiditySingleToken.selector;
            s[4] = IPActionAddRemoveLiqV3.addLiquiditySingleSy.selector;
            s[5] = IPActionAddRemoveLiqV3.addLiquiditySingleTokenKeepYt.selector;
            s[6] = IPActionAddRemoveLiqV3.addLiquiditySingleSyKeepYt.selector;
            s[7] = IPActionAddRemoveLiqV3.removeLiquidityDualTokenAndPt.selector;
            s[8] = IPActionAddRemoveLiqV3.removeLiquidityDualSyAndPt.selector;
            s[9] = IPActionAddRemoveLiqV3.removeLiquiditySinglePt.selector;
            s[10] = IPActionAddRemoveLiqV3.removeLiquiditySingleToken.selector;
            s[11] = IPActionAddRemoveLiqV3.removeLiquiditySingleSy.selector;
            arr[2] = IPActionStorageV4.SelectorsToFacet({facet: r.actionAddRemoveLiq, selectors: s});
        }

        // Swap PT
        {
            bytes4[] memory s = new bytes4[](4);
            s[0] = IPActionSwapPTV3.swapExactTokenForPt.selector;
            s[1] = IPActionSwapPTV3.swapExactSyForPt.selector;
            s[2] = IPActionSwapPTV3.swapExactPtForToken.selector;
            s[3] = IPActionSwapPTV3.swapExactPtForSy.selector;
            arr[3] = IPActionStorageV4.SelectorsToFacet({facet: r.actionSwapPT, selectors: s});
        }

        // Swap YT
        {
            bytes4[] memory s = new bytes4[](6);
            s[0] = IPActionSwapYTV3.swapExactTokenForYt.selector;
            s[1] = IPActionSwapYTV3.swapExactSyForYt.selector;
            s[2] = IPActionSwapYTV3.swapExactYtForToken.selector;
            s[3] = IPActionSwapYTV3.swapExactYtForSy.selector;
            s[4] = IPActionSwapYTV3.swapExactPtForYt.selector;
            s[5] = IPActionSwapYTV3.swapExactYtForPt.selector;
            arr[4] = IPActionStorageV4.SelectorsToFacet({facet: r.actionSwapYT, selectors: s});
        }

        // Callbacks
        {
            bytes4[] memory s = new bytes4[](2);
            s[0] = IPMarketSwapCallback.swapCallback.selector;
            s[1] = IPLimitRouterCallback.limitRouterCallback.selector;
            arr[5] = IPActionStorageV4.SelectorsToFacet({facet: r.actionCallback, selectors: s});
        }

        IPActionStorageV4(r.router).setSelectorToFacets(arr);
    }
}
