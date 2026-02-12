// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IUniswapV2Factory} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {IUniswapV2Router} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";
import {IERC20PermitProxy} from "@crane/contracts/interfaces/proxies/IERC20PermitProxy.sol";
import {ETHEREUM_MAIN} from "@crane/contracts/constants/networks/ETHEREUM_MAIN.sol";
import {ConstProdUtils} from "@crane/contracts/utils/math/ConstProdUtils.sol";

/// @title TestBase_UniswapV2Fork
/// @notice Base test contract for Uniswap V2 fork tests against Ethereum mainnet
/// @dev Provides common setup, constants, and helper functions for fork testing
abstract contract TestBase_UniswapV2Fork is Test {
    /* -------------------------------------------------------------------------- */
    /*                              Fork Configuration                            */
    /* -------------------------------------------------------------------------- */

    /// @dev Block number for fork reproducibility (Dec 2024)
    /// Use a recent block with known pool states for deterministic testing
    uint256 internal constant FORK_BLOCK = 21_000_000;

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

    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    /* -------------------------------------------------------------------------- */
    /*                              Well-Known Pairs                              */
    /* -------------------------------------------------------------------------- */

    // WETH/USDC pair
    address internal constant WETH_USDC_PAIR = 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc;

    // WETH/DAI pair
    address internal constant WETH_DAI_PAIR = 0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11;

    // WETH/USDT pair
    address internal constant WETH_USDT_PAIR = 0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852;

    /* -------------------------------------------------------------------------- */
    /*                                   Setup                                    */
    /* -------------------------------------------------------------------------- */

    function setUp() public virtual {
        // Skip fork tests when no RPC credentials are configured.
        // The `ethereum_mainnet_infura` endpoint in foundry.toml depends on ${INFURA_KEY}.
        // string memory infuraKey = vm.envOr("INFURA_KEY", string(""));
        // if (bytes(infuraKey).length == 0) {
        //     vm.skip(true);
        // }

        // Create fork at specific block for reproducibility
        // Uses the rpc_endpoints defined in foundry.toml
        vm.createSelectFork("ethereum_mainnet_infura", FORK_BLOCK);

        // Set up contract references from network constants
        uniswapV2Factory = IUniswapV2Factory(ETHEREUM_MAIN.UNISWAP_V2_FACTORY);
        uniswapV2Router = IUniswapV2Router(ETHEREUM_MAIN.UNISWAP_V2_ROUTER);

        vm.label(address(uniswapV2Factory), "UniswapV2Factory");
        vm.label(address(uniswapV2Router), "UniswapV2Router");

        // Label common tokens
        vm.label(WETH, "WETH");
        vm.label(USDC, "USDC");
        vm.label(USDT, "USDT");
        vm.label(DAI, "DAI");
        vm.label(WBTC, "WBTC");

        // Label well-known pairs
        vm.label(WETH_USDC_PAIR, "WETH_USDC_Pair");
        vm.label(WETH_DAI_PAIR, "WETH_DAI_Pair");
        vm.label(WETH_USDT_PAIR, "WETH_USDT_Pair");
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
