// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Test.sol";
import {IUniswapV2Pair} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {TestBase_UniswapV2} from "@crane/contracts/protocols/dexes/uniswap/v2/test/bases/TestBase_UniswapV2.sol";
import {ConstProdUtils} from "@crane/contracts/utils/math/ConstProdUtils.sol";
import {ERC20PermitMintableStub} from "@crane/contracts/tokens/ERC20/ERC20PermitMintableStub.sol";

contract TestBase_ConstProdUtils_Uniswap is TestBase_UniswapV2 {
    // Test tokens for Uniswap V2 - Balanced Pool
    ERC20PermitMintableStub uniswapBalancedTokenA;
    ERC20PermitMintableStub uniswapBalancedTokenB;

    // Test tokens for Uniswap V2 - Unbalanced Pool
    ERC20PermitMintableStub uniswapUnbalancedTokenA;
    ERC20PermitMintableStub uniswapUnbalancedTokenB;

    // Test tokens for Uniswap V2 - Extreme Unbalanced Pool
    ERC20PermitMintableStub uniswapExtremeTokenA;
    ERC20PermitMintableStub uniswapExtremeTokenB;

    // Uniswap pairs for different configurations
    IUniswapV2Pair uniswapBalancedPair;
    IUniswapV2Pair uniswapUnbalancedPair;
    IUniswapV2Pair uniswapExtremeUnbalancedPair;

    // Standard test amounts
    uint256 constant INITIAL_LIQUIDITY = 10000e18;
    uint256 constant TEST_AMOUNT = 1000e18;

    // Unbalanced pool ratios
    uint256 constant UNBALANCED_RATIO_A = 10000e18; // 10,000 tokens
    uint256 constant UNBALANCED_RATIO_B = 1000e18; // 1,000 tokens (10:1 ratio)
    uint256 constant UNBALANCED_RATIO_C = 100e18; // 100 tokens (100:1 ratio)

    function setUp() public virtual override {
        TestBase_UniswapV2.setUp();
        _createUniswapTokens();
        _createUniswapPairs();
    }

    function _createUniswapTokens() internal {
        uniswapBalancedTokenA = new ERC20PermitMintableStub("UniswapBalancedTokenA", "UNIBALA", 18, address(this), 0);
        vm.label(address(uniswapBalancedTokenA), "UniswapBalancedTokenA");

        uniswapBalancedTokenB = new ERC20PermitMintableStub("UniswapBalancedTokenB", "UNIBALB", 18, address(this), 0);
        vm.label(address(uniswapBalancedTokenB), "UniswapBalancedTokenB");

        uniswapUnbalancedTokenA = new ERC20PermitMintableStub("UniswapUnbalancedTokenA", "UNIUNA", 18, address(this), 0);
        vm.label(address(uniswapUnbalancedTokenA), "UniswapUnbalancedTokenA");

        uniswapUnbalancedTokenB = new ERC20PermitMintableStub("UniswapUnbalancedTokenB", "UNIUNB", 18, address(this), 0);
        vm.label(address(uniswapUnbalancedTokenB), "UniswapUnbalancedTokenB");

        uniswapExtremeTokenA = new ERC20PermitMintableStub("UniswapExtremeTokenA", "UNIEXA", 18, address(this), 0);
        vm.label(address(uniswapExtremeTokenA), "UniswapExtremeTokenA");

        uniswapExtremeTokenB = new ERC20PermitMintableStub("UniswapExtremeTokenB", "UNIEXB", 18, address(this), 0);
        vm.label(address(uniswapExtremeTokenB), "UniswapExtremeTokenB");
    }

    function _createUniswapPairs() internal {
        uniswapBalancedPair = IUniswapV2Pair(uniswapV2Factory.createPair(address(uniswapBalancedTokenA), address(uniswapBalancedTokenB)));
        vm.label(address(uniswapBalancedPair), string.concat("UniswapBalancedPair - ", uniswapBalancedTokenA.symbol(), " / ", uniswapBalancedTokenB.symbol()));

        uniswapUnbalancedPair = IUniswapV2Pair(uniswapV2Factory.createPair(address(uniswapUnbalancedTokenA), address(uniswapUnbalancedTokenB)));
        vm.label(address(uniswapUnbalancedPair), string.concat("UniswapUnbalancedPair - ", uniswapUnbalancedTokenA.symbol(), " / ", uniswapUnbalancedTokenB.symbol()));

        uniswapExtremeUnbalancedPair = IUniswapV2Pair(uniswapV2Factory.createPair(address(uniswapExtremeTokenA), address(uniswapExtremeTokenB)));
        vm.label(address(uniswapExtremeUnbalancedPair), string.concat("UniswapExtremeUnbalancedPair - ", uniswapExtremeTokenA.symbol(), " / ", uniswapExtremeTokenB.symbol()));
    }

    function _initializeUniswapBalancedPools() internal {
        uniswapBalancedTokenA.mint(address(this), INITIAL_LIQUIDITY);
        uniswapBalancedTokenA.approve(address(uniswapV2Router), INITIAL_LIQUIDITY);
        uniswapBalancedTokenB.mint(address(this), INITIAL_LIQUIDITY);
        uniswapBalancedTokenB.approve(address(uniswapV2Router), INITIAL_LIQUIDITY);

        uniswapV2Router.addLiquidity(address(uniswapBalancedTokenA), address(uniswapBalancedTokenB), INITIAL_LIQUIDITY, INITIAL_LIQUIDITY, 1, 1, address(this), block.timestamp);
    }

    function _initializeUniswapUnbalancedPools() internal {
        uniswapUnbalancedTokenA.mint(address(this), UNBALANCED_RATIO_A);
        uniswapUnbalancedTokenA.approve(address(uniswapV2Router), UNBALANCED_RATIO_A);
        uniswapUnbalancedTokenB.mint(address(this), UNBALANCED_RATIO_B);
        uniswapUnbalancedTokenB.approve(address(uniswapV2Router), UNBALANCED_RATIO_B);

        uniswapV2Router.addLiquidity(address(uniswapUnbalancedTokenA), address(uniswapUnbalancedTokenB), UNBALANCED_RATIO_A, UNBALANCED_RATIO_B, 1, 1, address(this), block.timestamp);
    }

    function _initializeUniswapExtremeUnbalancedPools() internal {
        uniswapExtremeTokenA.mint(address(this), UNBALANCED_RATIO_A);
        uniswapExtremeTokenA.approve(address(uniswapV2Router), UNBALANCED_RATIO_A);
        uniswapExtremeTokenB.mint(address(this), UNBALANCED_RATIO_C);
        uniswapExtremeTokenB.approve(address(uniswapV2Router), UNBALANCED_RATIO_C);

        uniswapV2Router.addLiquidity(address(uniswapExtremeTokenA), address(uniswapExtremeTokenB), UNBALANCED_RATIO_A, UNBALANCED_RATIO_C, 1, 1, address(this), block.timestamp);
    }

    function _executeUniswapTradesToGenerateFees(ERC20PermitMintableStub tokenA, ERC20PermitMintableStub tokenB) internal {
        uint256 swapAmountA = 100e18;
        tokenA.mint(address(this), swapAmountA);
        tokenA.approve(address(uniswapV2Router), swapAmountA);

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapAmountA,
            0,
            path,
            address(this),
            block.timestamp + 300
        );

        uint256 balanceB = tokenB.balanceOf(address(this));
        if (balanceB > 0) {
            tokenB.approve(address(uniswapV2Router), balanceB);
            address[] memory pathRev = new address[](2);
            pathRev[0] = address(tokenB);
            pathRev[1] = address(tokenA);
            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                balanceB,
                0,
                pathRev,
                address(this),
                block.timestamp + 300
            );
        }

        uint256 balanceA = tokenA.balanceOf(address(this));
        if (balanceA > 0) {
            tokenA.approve(address(uniswapV2Router), balanceA);
            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                balanceA,
                0,
                path,
                address(this),
                block.timestamp + 300
            );
        }
    }

}
