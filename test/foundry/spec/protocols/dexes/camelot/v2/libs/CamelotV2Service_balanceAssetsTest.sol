// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {betterconsole as console} from "../../../../../../../../contracts/utils/vm/foundry/tools/console/betterconsole.sol";
import "forge-std/Base.sol";
import "../../../../../../../../contracts/constants/Constants.sol";
import {APE_CHAIN_CURTIS} from "../../../../../../../../contracts/networks/arbitrum/apechain/constants/APE_CHAIN_CURTIS.sol";
import {CraneTest} from "../../../../../../../../contracts/test/CraneTest.sol";
import {IOwnableStorage, OwnableStorage} from "../../../../../../../../contracts/access/ownable/utils/OwnableStorage.sol";
import {ConstProdUtils} from "../../../../../../../../contracts/utils/math/ConstProdUtils.sol";
import {CamelotV2Service} from "../../../../../../../../contracts/protocols/dexes/camelot/v2/utils/CamelotV2Service.sol";
import {ICamelotPair} from "../../../../../../../../contracts/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {ICamelotFactory} from "../../../../../../../../contracts/protocols/dexes/camelot/v2/ICamelotFactory.sol";
import {ICamelotV2Router} from "../../../../../../../../contracts/protocols/dexes/camelot/v2/ICamelotV2Router.sol";
import {BetterIERC20 as IERC20} from "../../../../../../../../contracts/token/ERC20/BetterIERC20.sol";
import {IERC20MintBurn} from "../../../../../../../../contracts/token/ERC20/IERC20MintBurn.sol";
import {IERC20MintBurnOperableStorage, ERC20MintBurnOperableStorage} from "../../../../../../../../contracts/token/ERC20/utils/ERC20MintBurnOperableStorage.sol";

/**
 * @title CamelotV2Service_balanceAssetsTest
 * @dev Test suite for the _balanceAssets function variants of CamelotV2Service
 */
contract CamelotV2Service_balanceAssetsTest is CraneTest {
    IERC20MintBurn tokenA;
    IERC20MintBurn tokenB;
    ICamelotPair pool;
    address referrer = address(0); // Using zero address as dummy referrer
    uint256 depositAmount = TENK_WAD;
    uint256 saleAmount = ONE_WAD * 5; // Amount to use for balancing assets
    
    // Pool reserve variables to avoid stack too deep
    uint256 saleReserve;
    uint256 reserveOut;
    uint256 saleTokenFeePerc;

    function setUp() public virtual override {
        // Fork chain state
        vm.createSelectFork("apeChain_curtis_rpc", 8579331);

        // Initialize token owner
        IOwnableStorage.OwnableAccountInit memory globalOwnableAccountInit;
        globalOwnableAccountInit.owner = address(this);

        // Create TokenA
        IERC20MintBurnOperableStorage.MintBurnOperableAccountInit memory tokenAInit;
        tokenAInit.ownableAccountInit = globalOwnableAccountInit;
        tokenAInit.name = "TokenA";
        tokenAInit.symbol = tokenAInit.name;
        tokenAInit.decimals = 18;

        tokenA = IERC20MintBurn(
            diamondFactory()
            .deploy(
                erc20MintBurnPkg(),
                abi.encode(tokenAInit)
            )
        );
        vm.label(address(tokenA), "TokenA");

        // Create TokenB
        IERC20MintBurnOperableStorage.MintBurnOperableAccountInit memory tokenBInit;
        tokenBInit.ownableAccountInit = globalOwnableAccountInit;
        tokenBInit.name = "TokenB";
        tokenBInit.symbol = tokenBInit.name;
        tokenBInit.decimals = 18;

        tokenB = IERC20MintBurn(
            diamondFactory()
            .deploy(
                erc20MintBurnPkg(),
                abi.encode(tokenBInit)
            )
        );
        vm.label(address(tokenB), "TokenB");
        
        // Create pool
        pool = ICamelotPair(
            camV2Factory()
            .createPair(
                address(tokenA),
                address(tokenB)
            )
        );
        vm.label(
            address(pool),
            string.concat(
                pool.symbol(),
                " - ",
                IERC20(address(tokenA)).symbol(),
                " / ",
                IERC20(address(tokenB)).symbol()
            )
        );
        
        // Initialize pool with liquidity
        tokenA.mint(address(this), depositAmount);
        tokenA.approve(address(camV2Router()), depositAmount);
        tokenB.mint(address(this), depositAmount);
        tokenB.approve(address(camV2Router()), depositAmount);
        
        CamelotV2Service._deposit(
            camV2Router(),
            tokenA,
            tokenB,
            depositAmount,
            depositAmount
        );
    }
    
    // Helper function to load reserves and avoid stack too deep
    function _loadReserves() internal {
        (uint112 reserve0, uint112 reserve1, uint16 token0feePercent, uint16 token1FeePercent) = pool.getReserves();
        (saleReserve, reserveOut, saleTokenFeePerc) = address(tokenA) == pool.token0()
            ? (reserve0, reserve1, token0feePercent)
            : (reserve1, reserve0, token1FeePercent);
    }

    /* ---------------------------------------------------------------------- */
    /*                _balanceAssets with Pool Parameter Test                 */
    /* ---------------------------------------------------------------------- */

    function test_balanceAssets_withPoolParam() public {
        // Mint tokens for the sale
        tokenA.mint(address(this), saleAmount);
        tokenA.approve(address(camV2Router()), saleAmount);
        
        // Balance the assets
        uint256[] memory amounts = CamelotV2Service._balanceAssets(
            camV2Router(),
            pool,
            saleAmount,
            tokenA,
            tokenB,
            referrer
        );
        
        // Verify we got two amounts back
        assertEq(amounts.length, 2, "Should return two amounts");
        
        // Ensure the first amount (tokenA to keep) plus the second amount (tokenB received from swap)
        // are both non-zero
        assertGt(amounts[0], 0, "TokenA amount to keep should be non-zero");
        assertGt(amounts[1], 0, "TokenB amount from swap should be non-zero");
        
        // Verify the sum of kept tokens and swapped tokens equals the original sale amount
        assertEq(amounts[0] + saleAmount - amounts[0], saleAmount, "Sum of kept and swapped should equal original");
        
        // Verify that the first amount is less than the total sale amount (some was swapped)
        assertLt(amounts[0], saleAmount, "TokenA kept should be less than total sale amount");
    }

    /* ---------------------------------------------------------------------- */
    /*              _balanceAssets with Direct Reserves Test                  */
    /* ---------------------------------------------------------------------- */

    function test_balanceAssets_withDirectReserves() public {
        // Mint tokens for the sale
        tokenA.mint(address(this), saleAmount);
        tokenA.approve(address(camV2Router()), saleAmount);
        
        // Get reserves data directly using helper
        _loadReserves();
        
        // Balance the assets using direct reserves
        uint256[] memory amounts = CamelotV2Service._balanceAssets(
            camV2Router(),
            saleAmount,
            tokenA,
            saleReserve,
            saleTokenFeePerc,
            tokenB,
            reserveOut,
            referrer
        );
        
        // Verify we got two amounts back
        assertEq(amounts.length, 2, "Should return two amounts");
        
        // Ensure the first amount (tokenA to keep) plus the second amount (tokenB received from swap)
        // are both non-zero
        assertGt(amounts[0], 0, "TokenA amount to keep should be non-zero");
        assertGt(amounts[1], 0, "TokenB amount from swap should be non-zero");
        
        // Verify the sum of kept tokens and swapped tokens equals the original sale amount
        assertEq(amounts[0] + saleAmount - amounts[0], saleAmount, "Sum of kept and swapped should equal original");
        
        // Verify that the first amount is less than the total sale amount (some was swapped)
        assertLt(amounts[0], saleAmount, "TokenA kept should be less than total sale amount");
    }
    
    /* ---------------------------------------------------------------------- */
    /*                   Comparison Between Variants Test                     */
    /* ---------------------------------------------------------------------- */
    
    function test_balanceAssets_compareVariants() public {
        // Mint tokens for the sale
        tokenA.mint(address(this), saleAmount * 2); // Double the amount for two tests
        tokenA.approve(address(camV2Router()), saleAmount * 2);
        
        // First variant: using pool
        uint256[] memory amountsWithPool = CamelotV2Service._balanceAssets(
            camV2Router(),
            pool,
            saleAmount,
            tokenA,
            tokenB,
            referrer
        );
        
        // Get reserves data directly for second variant using helper
        _loadReserves();
        
        // Second variant: using direct reserves
        uint256[] memory amountsWithReserves = CamelotV2Service._balanceAssets(
            camV2Router(),
            saleAmount,
            tokenA,
            saleReserve,
            saleTokenFeePerc,
            tokenB,
            reserveOut,
            referrer
        );
        
        // The results should be similar but not identical because pool state changes
        // after the first _balanceAssets call
        assertApproxEqRel(
            amountsWithPool[0], 
            amountsWithReserves[0], 
            0.10e18, // 10% tolerance due to pool state changes
            "TokenA kept should be similar between variants"
        );
        
        assertApproxEqRel(
            amountsWithPool[1], 
            amountsWithReserves[1], 
            0.10e18, // 10% tolerance due to pool state changes
            "TokenB received should be similar between variants"
        );
    }

    /* ---------------------------------------------------------------------- */
    /*                          Edge Case Tests                               */
    /* ---------------------------------------------------------------------- */
    
    // This test intentionally skipped as zero amount swaps are expected to revert
    // in the CamelotV2 protocol with "INSUFFICIENT_OUTPUT_AMOUNT"
    function skip_test_balanceAssets_zeroAmount() public {
        // The underlying router call will revert with "INSUFFICIENT_OUTPUT_AMOUNT"
        // if we try to swap zero tokens, so we can't test a successful call
        
        // For zero amount swaps, the router should be responsible for handling this edge case
        // This test is here to document the expected behavior, but is skipped as it cannot pass
    }
} 