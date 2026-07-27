// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {console2} from "forge-std/console2.sol";
import {Script} from "forge-std/Script.sol";

import {IERC20} from "@crane/contracts/external/openzeppelin-contracts/token/ERC20/IERC20.sol";

import {FraxswapFactory} from
    "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/core/FraxswapFactory.sol";
import {FraxswapPair} from
    "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/core/FraxswapPair.sol";
import {
    FraxswapRouterMultihop
} from "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/periphery/FraxswapRouterMultihop.sol";
import {BAMM} from "@crane/contracts/protocols/tokens/stable/frax/BAMM/BAMM.sol";
import {BAMMHelper} from "@crane/contracts/protocols/tokens/stable/frax/BAMM/BAMMHelper.sol";
import {FraxswapOracle} from
    "@crane/contracts/protocols/tokens/stable/frax/BAMM/FraxswapOracle.sol";
import {FraxswapDummyRouter} from
    "@crane/contracts/protocols/tokens/stable/frax/BAMM/FraxswapDummyRouter.sol";
import {DummyToken} from
    "@crane/contracts/protocols/tokens/stable/frax/Fraxferry/DummyToken.sol";

// BAMMTest casts FraxswapDummyRouter → FraxswapRouterMultihop; same pattern here.

/// @notice Exact BAMM graph from `BAMMTest._deployBamm` / TestBase_FraxBAMM path:
/// FraxswapFactory → createPair → FraxswapDummyRouter (+ optional Multihop type) →
/// BAMMHelper → FraxswapOracle → BAMM.
/// @dev Phase-9 style helper: plain CREATE so hermetic/fork tests and operator scripts share one path.
contract BcFraxPhase13bDeploy is Script {
    /// @dev Fee numerator as in BAMMTest (9970) → pairFeeTier = 10000 - 9970 = 30.
    uint256 public constant DEFAULT_FEE_NUMERATOR = 9970;
    uint256 public constant DEFAULT_PAIR_FEE_TIER = 10_000 - DEFAULT_FEE_NUMERATOR; // 30

    struct DeployResult {
        address fraxswapFactory;
        address pair;
        address token0;
        address token1;
        address bamm;
        address bammHelper;
        address fraxswapOracle;
        address fraxswapDummyRouter;
        uint256 pairFeeTier;
    }

    /// @notice Hermetic graph: mintable DummyTokens + full BAMM setup (matches BAMMTest).
    function deployHermetic(address owner, uint256 seedLiquidity)
        external
        returns (DeployResult memory r)
    {
        require(owner != address(0), "13b: owner zero");
        if (seedLiquidity == 0) seedLiquidity = 100e18;

        DummyToken tA = new DummyToken();
        DummyToken tB = new DummyToken();
        if (address(tB) < address(tA)) {
            r.token0 = address(tB);
            r.token1 = address(tA);
        } else {
            r.token0 = address(tA);
            r.token1 = address(tB);
        }

        DummyToken(r.token0).mint(owner, type(uint256).max / 2);
        DummyToken(r.token1).mint(owner, type(uint256).max / 2);
        // Mint to this helper for seed + dummy router funding
        DummyToken(r.token0).mint(address(this), type(uint256).max / 4);
        DummyToken(r.token1).mint(address(this), type(uint256).max / 4);

        r = _deployGraph(owner, r.token0, r.token1, seedLiquidity);
        return r;
    }

    /// @notice BC / fork graph: existing token pair (e.g. WETH + USDC) + BAMM.
    function deployWithTokens(address owner, address tokenA, address tokenB, uint256 seedLiquidity)
        external
        returns (DeployResult memory r)
    {
        require(owner != address(0), "13b: owner zero");
        require(tokenA != address(0) && tokenB != address(0), "13b: tokens zero");
        require(tokenA != tokenB, "13b: identical tokens");
        require(tokenA.code.length > 0 && tokenB.code.length > 0, "13b: token no code");

        if (tokenB < tokenA) {
            r.token0 = tokenB;
            r.token1 = tokenA;
        } else {
            r.token0 = tokenA;
            r.token1 = tokenB;
        }

        r = _deployGraph(owner, r.token0, r.token1, seedLiquidity);
        return r;
    }

    function _deployGraph(address owner, address token0, address token1, uint256 seedLiquidity)
        internal
        returns (DeployResult memory r)
    {
        r.token0 = token0;
        r.token1 = token1;
        r.pairFeeTier = DEFAULT_PAIR_FEE_TIER;

        FraxswapFactory factory = new FraxswapFactory(owner);
        r.fraxswapFactory = address(factory);

        address pairAddr = factory.createPair(token0, token1, r.pairFeeTier);
        require(pairAddr != address(0) && pairAddr.code.length > 0, "13b: pair create failed");
        r.pair = pairAddr;
        FraxswapPair pair = FraxswapPair(pairAddr);

        // Seed liquidity when helper holds balances (hermetic) or caller pre-funded this contract.
        if (seedLiquidity > 0) {
            uint256 bal0 = IERC20(token0).balanceOf(address(this));
            uint256 bal1 = IERC20(token1).balanceOf(address(this));
            if (bal0 >= seedLiquidity && bal1 >= seedLiquidity) {
                IERC20(token0).transfer(pairAddr, seedLiquidity);
                IERC20(token1).transfer(pairAddr, seedLiquidity);
                pair.mint(owner);
            }
        }

        r.bammHelper = address(new BAMMHelper());
        r.fraxswapOracle = address(new FraxswapOracle());

        // BAMMTest path: FraxswapDummyRouter cast to FraxswapRouterMultihop
        FraxswapDummyRouter dummy = new FraxswapDummyRouter();
        r.fraxswapDummyRouter = address(dummy);
        uint256 fund = 1000e18;
        if (IERC20(token0).balanceOf(address(this)) >= fund) {
            IERC20(token0).transfer(address(dummy), fund);
        }
        if (IERC20(token1).balanceOf(address(this)) >= fund) {
            IERC20(token1).transfer(address(dummy), fund);
        }

        BAMM bamm = new BAMM(
            pair,
            true, // isFraxswapPair
            r.pairFeeTier,
            FraxswapRouterMultihop(payable(address(dummy))),
            BAMMHelper(r.bammHelper),
            FraxswapOracle(r.fraxswapOracle)
        );
        r.bamm = address(bamm);

        require(r.fraxswapFactory.code.length > 0, "13b: factory");
        require(r.pair.code.length > 0, "13b: pair");
        require(r.bamm.code.length > 0, "13b: bamm");
        require(r.bammHelper.code.length > 0, "13b: helper");
        require(r.fraxswapOracle.code.length > 0, "13b: oracle");
        require(r.fraxswapDummyRouter.code.length > 0, "13b: router");

        console2.log("13b fraxswapFactory", r.fraxswapFactory);
        console2.log("13b pair", r.pair);
        console2.log("13b bamm", r.bamm);
        console2.log("13b bammHelper", r.bammHelper);
        console2.log("13b fraxswapOracle", r.fraxswapOracle);
        console2.log("13b dummyRouter", r.fraxswapDummyRouter);
        console2.log("13b token0", r.token0);
        console2.log("13b token1", r.token1);

        return r;
    }
}
