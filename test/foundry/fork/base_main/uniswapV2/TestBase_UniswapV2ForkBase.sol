// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IUniswapV2Factory} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {IUniswapV2Router} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";
import {IERC20PermitProxy} from "@crane/contracts/interfaces/proxies/IERC20PermitProxy.sol";
import {BASE_MAIN} from "@crane/contracts/constants/networks/BASE_MAIN.sol";
import {ConstProdUtils} from "@crane/contracts/utils/math/ConstProdUtils.sol";

/// @title TestBase_UniswapV2ForkBase
/// @notice Base test contract for Uniswap V2 fork tests against Base mainnet
/// @dev Provides common setup, constants, and helper functions for fork testing
abstract contract TestBase_UniswapV2ForkBase is Test {
    /* -------------------------------------------------------------------------- */
    /*                              Fork Configuration                            */
    /* -------------------------------------------------------------------------- */

    /// @dev Block number for fork reproducibility (Jan 2026)
    /// Use a recent block with known pool states for deterministic testing
    uint256 internal constant FORK_BLOCK = 28_000_000;

    /* -------------------------------------------------------------------------- */
    /*                            Mainnet Contract Refs                           */
    /* -------------------------------------------------------------------------- */

    IUniswapV2Factory internal uniswapV2Factory;
    IUniswapV2Router internal uniswapV2Router;

    /// @dev Uniswap V2 fee: 0.3% = 3/1000 = 300/100000
    uint256 internal constant UNISWAP_V2_FEE_PERCENT = 300;
    uint256 internal constant UNISWAP_V2_FEE_DENOMINATOR = 100_000;

    /* -------------------------------------------------------------------------- */
    /*                              Common Token Addresses                        */
    /* -------------------------------------------------------------------------- */

    address internal constant WETH = 0x4200000000000000000000000000000000000006;
    address internal constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address internal constant USDbC = 0xd9aAEc86B65D86f6A7B5B1b0c42FFA531710b6CA;
    address internal constant DAI = 0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb;
    address internal constant cbBTC = 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf;

    /* -------------------------------------------------------------------------- */
    /*                                   Setup                                    */
    /* -------------------------------------------------------------------------- */

    function setUp() public virtual {
        // Skip fork tests when no RPC credentials are configured.
        // The `base_mainnet_infura` endpoint in foundry.toml depends on ${INFURA_KEY}.
        // string memory infuraKey = vm.envOr("INFURA_KEY", string(""));
        // if (bytes(infuraKey).length == 0) {
        //     vm.skip(true);
        // }

        // Create fork at specific block for reproducibility
        // Uses the rpc_endpoints defined in foundry.toml
        vm.createSelectFork("base_mainnet_infura", FORK_BLOCK);

        // Set up contract references from network constants
        uniswapV2Factory = IUniswapV2Factory(BASE_MAIN.UNISWAP_V2_FACTORY);
        uniswapV2Router = IUniswapV2Router(BASE_MAIN.UNISWAP_V2_ROUTER);

        vm.label(address(uniswapV2Factory), "UniswapV2Factory");
        vm.label(address(uniswapV2Router), "UniswapV2Router");

        // Label common tokens
        vm.label(WETH, "WETH");
        vm.label(USDC, "USDC");
        vm.label(USDbC, "USDbC");
        vm.label(DAI, "DAI");
        vm.label(cbBTC, "cbBTC");
    }

    /* -------------------------------------------------------------------------- */
    /*                              Pair Helpers                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Get a pair interface from an address
    function getPair(address pairAddress) internal pure returns (IUniswapV2Pair) {
        return IUniswapV2Pair(pairAddress);
    }

    /// @notice Get the pair for two tokens from the factory
    function getPair(address tokenA, address tokenB) internal view returns (IUniswapV2Pair) {
        return IUniswapV2Pair(uniswapV2Factory.getPair(tokenA, tokenB));
    }

    /// @notice Get sorted reserves for a pair given the tokens
    function getReserves(IUniswapV2Pair pair, address tokenA, address tokenB)
        internal
        view
        returns (uint256 reserveA, uint256 reserveB)
    {
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        address token0 = pair.token0();
        (reserveA, reserveB) = tokenA == token0
            ? (uint256(reserve0), uint256(reserve1))
            : (uint256(reserve1), uint256(reserve0));
    }

    /* -------------------------------------------------------------------------- */
    /*                              Quote Helpers                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice Get quote from router's getAmountsOut
    function quoteAmountOut(uint256 amountIn, address tokenIn, address tokenOut)
        internal
        view
        returns (uint256 amountOut)
    {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint256[] memory amounts = uniswapV2Router.getAmountsOut(amountIn, path);
        amountOut = amounts[1];
    }

    /// @notice Get quote from router's getAmountsIn
    function quoteAmountIn(uint256 amountOut, address tokenIn, address tokenOut)
        internal
        view
        returns (uint256 amountIn)
    {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint256[] memory amounts = uniswapV2Router.getAmountsIn(amountOut, path);
        amountIn = amounts[0];
    }

    /// @notice Get quote using ConstProdUtils._saleQuote (exact in)
    function quoteConstProdSale(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountOut)
    {
        amountOut = ConstProdUtils._saleQuote(
            amountIn,
            reserveIn,
            reserveOut,
            UNISWAP_V2_FEE_PERCENT,
            UNISWAP_V2_FEE_DENOMINATOR
        );
    }

    /// @notice Get quote using ConstProdUtils._purchaseQuote (exact out)
    function quoteConstProdPurchase(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountIn)
    {
        amountIn = ConstProdUtils._purchaseQuote(
            amountOut,
            reserveIn,
            reserveOut,
            UNISWAP_V2_FEE_PERCENT,
            UNISWAP_V2_FEE_DENOMINATOR
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                              Swap Execution                                */
    /* -------------------------------------------------------------------------- */

    /// @notice Execute a swap via the router (exact input)
    function swapExactTokensForTokens(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        address recipient
    ) internal returns (uint256 amountOut) {
        // Deal tokens to this contract
        deal(tokenIn, address(this), amountIn);

        // Approve router
        IERC20PermitProxy(tokenIn).approve(address(uniswapV2Router), amountIn);

        // Build path
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        // Execute swap
        uint256[] memory amounts = uniswapV2Router.swapExactTokensForTokens(
            amountIn,
            0, // Accept any output
            path,
            recipient,
            block.timestamp + 1
        );

        amountOut = amounts[1];
    }

    /// @notice Execute a swap via the router (exact output)
    function swapTokensForExactTokens(
        uint256 amountOut,
        address tokenIn,
        address tokenOut,
        address recipient
    ) internal returns (uint256 amountIn) {
        // Deal a large amount of tokens to this contract
        uint256 maxAmountIn = amountOut * 10000 + 100 ether;
        deal(tokenIn, address(this), maxAmountIn);

        // Approve router
        IERC20PermitProxy(tokenIn).approve(address(uniswapV2Router), maxAmountIn);

        // Build path
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        // Execute swap
        uint256[] memory amounts = uniswapV2Router.swapTokensForExactTokens(
            amountOut,
            maxAmountIn,
            path,
            recipient,
            block.timestamp + 1
        );

        amountIn = amounts[0];
    }

    /* -------------------------------------------------------------------------- */
    /*                          Pool Existence Check                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Check if a pair exists and has sufficient liquidity at the fork block
    function pairExistsAndHasLiquidity(address pairAddress) internal view returns (bool exists) {
        // Check if address has code
        if (pairAddress.code.length == 0) return false;

        // Try to get reserves from the pair
        try IUniswapV2Pair(pairAddress).getReserves() returns (uint112 r0, uint112 r1, uint32) {
            exists = r0 > 0 && r1 > 0;
        } catch {
            exists = false;
        }
    }

    /// @notice Skip the current test if the pair doesn't exist or has no liquidity
    function skipIfPairInvalid(address pairAddress, string memory pairName) internal {
        if (!pairExistsAndHasLiquidity(pairAddress)) {
            console.log("Skipping test - pair not available at fork block:", pairName);
            vm.skip(true);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                            Assertion Helpers                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Assert that two amounts match exactly
    function assertExactMatch(uint256 expected, uint256 actual, string memory message) internal pure {
        assertEq(expected, actual, message);
    }

    /// @notice Assert amounts match within 1 wei tolerance (for rounding)
    function assertWithinRounding(uint256 expected, uint256 actual, string memory message) internal pure {
        assertApproxEqAbs(expected, actual, 1, message);
    }
}
