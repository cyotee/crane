// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Test.sol";
import {ICamelotPair} from "@crane/contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {ICamelotFactory} from "@crane/contracts/interfaces/protocols/dexes/camelot/v2/ICamelotFactory.sol";
import {CamelotV2Service} from "@crane/contracts/protocols/dexes/camelot/v2/services/CamelotV2Service.sol";
import {TestBase_CamelotV2} from "@crane/contracts/protocols/dexes/camelot/v2/test/bases/TestBase_CamelotV2.sol";
import {ConstProdUtils} from "@crane/contracts/utils/math/ConstProdUtils.sol";
import {FEE_DENOMINATOR} from "@crane/contracts/constants/Constants.sol";
import {ERC20PermitMintableStub} from "@crane/contracts/tokens/ERC20/ERC20PermitMintableStub.sol";
import {CamelotPair} from "@crane/contracts/protocols/dexes/camelot/v2/stubs/CamelotPair.sol";

/**
 * @title CamelotV2_multihop Tests
 * @notice Tests for multi-hop swaps with different directional fees per hop
 * @dev Verifies that cumulative fee impact is correctly calculated when each pool
 *      in a multi-hop path has different token0Fee and token1Fee values.
 *
 *      Key concepts tested:
 *      - Each hop may have different fee configurations (token0Fee vs token1Fee)
 *      - The fee applied depends on which token is being sold at each hop
 *      - Fees compound through the path, reducing output at each step
 *      - Quote calculations must match actual swap results
 */
contract CamelotV2_multihop is TestBase_CamelotV2 {
    using ConstProdUtils for uint256;

    /* ---------------------------------------------------------------------- */
    /*                                 State                                  */
    /* ---------------------------------------------------------------------- */

    // Tokens for multi-hop routes
    ERC20PermitMintableStub tokenA;
    ERC20PermitMintableStub tokenB;
    ERC20PermitMintableStub tokenC;
    ERC20PermitMintableStub tokenD;

    // Pairs for multi-hop routes with different fee configurations
    ICamelotPair pairAB; // Hop 1: A->B (custom fees)
    ICamelotPair pairBC; // Hop 2: B->C (custom fees)
    ICamelotPair pairCD; // Hop 3: C->D (custom fees)

    // Fee configurations (in basis points, out of 100000)
    // e.g., 300 = 0.3%, 500 = 0.5%, 100 = 0.1%
    uint16 constant FEE_0_3_PERCENT = 300;  // 0.3%
    uint16 constant FEE_0_5_PERCENT = 500;  // 0.5%
    uint16 constant FEE_0_1_PERCENT = 100;  // 0.1%
    uint16 constant FEE_0_2_PERCENT = 200;  // 0.2%
    uint16 constant FEE_0_4_PERCENT = 400;  // 0.4%
    uint16 constant FEE_1_0_PERCENT = 1000; // 1.0%

    // Standard liquidity amounts
    uint256 constant INITIAL_LIQUIDITY = 10000e18;

    // Standard test swap amount
    uint256 constant SWAP_AMOUNT = 100e18;

    // Struct to avoid stack-too-deep
    struct HopData {
        uint256 reserveIn;
        uint256 reserveOut;
        uint256 feePercent;
        uint256 amountOut;
    }

    /* ---------------------------------------------------------------------- */
    /*                                 Setup                                  */
    /* ---------------------------------------------------------------------- */

    function setUp() public override {
        TestBase_CamelotV2.setUp();
        _createTokens();
        _createPairs();
    }

    function _createTokens() internal {
        tokenA = new ERC20PermitMintableStub("Token A", "TKA", 18, address(this), 0);
        vm.label(address(tokenA), "TokenA");

        tokenB = new ERC20PermitMintableStub("Token B", "TKB", 18, address(this), 0);
        vm.label(address(tokenB), "TokenB");

        tokenC = new ERC20PermitMintableStub("Token C", "TKC", 18, address(this), 0);
        vm.label(address(tokenC), "TokenC");

        tokenD = new ERC20PermitMintableStub("Token D", "TKD", 18, address(this), 0);
        vm.label(address(tokenD), "TokenD");
    }

    function _createPairs() internal {
        pairAB = ICamelotPair(camelotV2Factory.createPair(address(tokenA), address(tokenB)));
        vm.label(address(pairAB), "PairAB");

        pairBC = ICamelotPair(camelotV2Factory.createPair(address(tokenB), address(tokenC)));
        vm.label(address(pairBC), "PairBC");

        pairCD = ICamelotPair(camelotV2Factory.createPair(address(tokenC), address(tokenD)));
        vm.label(address(pairCD), "PairCD");
    }

    /**
     * @dev Initialize liquidity in all pairs with balanced reserves
     */
    function _initializeLiquidity() internal {
        // Initialize pair A-B
        tokenA.mint(address(this), INITIAL_LIQUIDITY);
        tokenA.approve(address(camelotV2Router), INITIAL_LIQUIDITY);
        tokenB.mint(address(this), INITIAL_LIQUIDITY);
        tokenB.approve(address(camelotV2Router), INITIAL_LIQUIDITY);
        CamelotV2Service._deposit(camelotV2Router, tokenA, tokenB, INITIAL_LIQUIDITY, INITIAL_LIQUIDITY);

        // Initialize pair B-C
        tokenB.mint(address(this), INITIAL_LIQUIDITY);
        tokenB.approve(address(camelotV2Router), INITIAL_LIQUIDITY);
        tokenC.mint(address(this), INITIAL_LIQUIDITY);
        tokenC.approve(address(camelotV2Router), INITIAL_LIQUIDITY);
        CamelotV2Service._deposit(camelotV2Router, tokenB, tokenC, INITIAL_LIQUIDITY, INITIAL_LIQUIDITY);

        // Initialize pair C-D
        tokenC.mint(address(this), INITIAL_LIQUIDITY);
        tokenC.approve(address(camelotV2Router), INITIAL_LIQUIDITY);
        tokenD.mint(address(this), INITIAL_LIQUIDITY);
        tokenD.approve(address(camelotV2Router), INITIAL_LIQUIDITY);
        CamelotV2Service._deposit(camelotV2Router, tokenC, tokenD, INITIAL_LIQUIDITY, INITIAL_LIQUIDITY);
    }

    /**
     * @dev Set custom fee percentages on a pair
     * @param pair The pair to configure
     * @param token0Fee Fee for selling token0 (in basis points out of 100000)
     * @param token1Fee Fee for selling token1 (in basis points out of 100000)
     */
    function _setFees(ICamelotPair pair, uint16 token0Fee, uint16 token1Fee) internal {
        // feePercentOwner is msg.sender of factory constructor, which is this test contract
        // No prank needed since this contract deployed the factory
        CamelotPair(address(pair)).setFeePercent(token0Fee, token1Fee);
    }

    /* ---------------------------------------------------------------------- */
    /*                   Different Fee Configurations Per Hop                 */
    /* ---------------------------------------------------------------------- */

    /**
     * @notice Test multi-hop with different fee configs per pool
     * @dev Path: A -> B (0.3%) -> C (0.5%) -> D (0.1%)
     *      where the fee applied depends on token sort order at each hop
     */
    function test_multihop_differentFeesPerHop() public {
        _initializeLiquidity();

        // Configure fees for each pair
        // PairAB: token0Fee = 0.3%, token1Fee = 0.5%
        _setFees(pairAB, FEE_0_3_PERCENT, FEE_0_5_PERCENT);
        // PairBC: token0Fee = 0.2%, token1Fee = 0.4%
        _setFees(pairBC, FEE_0_2_PERCENT, FEE_0_4_PERCENT);
        // PairCD: token0Fee = 0.1%, token1Fee = 1.0%
        _setFees(pairCD, FEE_0_1_PERCENT, FEE_1_0_PERCENT);

        uint256 amountIn = SWAP_AMOUNT;

        // Calculate expected output through 3 hops
        uint256 expectedAmountB = _calculateSaleQuote(pairAB, address(tokenA), amountIn);
        uint256 expectedAmountC = _calculateSaleQuote(pairBC, address(tokenB), expectedAmountB);
        uint256 expectedAmountD = _calculateSaleQuote(pairCD, address(tokenC), expectedAmountC);

        // Execute actual swap
        tokenA.mint(address(this), amountIn);
        tokenA.approve(address(camelotV2Router), amountIn);

        address[] memory path = new address[](4);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        path[2] = address(tokenC);
        path[3] = address(tokenD);

        uint256 balanceBefore = tokenD.balanceOf(address(this));

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn, 0, path, address(this), address(0), block.timestamp + 300
        );

        uint256 actualAmountD = tokenD.balanceOf(address(this)) - balanceBefore;

        assertEq(actualAmountD, expectedAmountD, "Multi-hop with different fees should match quote");
    }

    /**
     * @notice Test that directional fee applies based on which token is being sold
     * @dev Same pair, different directions should apply different fees
     */
    function test_multihop_directionalFeeSelection() public {
        _initializeLiquidity();

        // Configure asymmetric fees: token0Fee = 0.1%, token1Fee = 1.0%
        _setFees(pairAB, FEE_0_1_PERCENT, FEE_1_0_PERCENT);

        uint256 amountIn = SWAP_AMOUNT;

        // Determine which token is token0 in the pair
        address pairToken0 = pairAB.token0();
        bool tokenAIsToken0 = (address(tokenA) == pairToken0);

        // Forward swap: A -> B
        uint256 feeForward = tokenAIsToken0 ? FEE_0_1_PERCENT : FEE_1_0_PERCENT;
        HopData memory hopForward = _getHopData(pairAB, address(tokenA));
        uint256 expectedForward =
            ConstProdUtils._saleQuote(amountIn, hopForward.reserveIn, hopForward.reserveOut, feeForward, FEE_DENOMINATOR);

        tokenA.mint(address(this), amountIn);
        tokenA.approve(address(camelotV2Router), amountIn);

        address[] memory pathForward = new address[](2);
        pathForward[0] = address(tokenA);
        pathForward[1] = address(tokenB);

        uint256 tokenBBefore = tokenB.balanceOf(address(this));

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn, 0, pathForward, address(this), address(0), block.timestamp + 300
        );

        uint256 actualForward = tokenB.balanceOf(address(this)) - tokenBBefore;
        assertEq(actualForward, expectedForward, "Forward swap should apply correct directional fee");

        // Reverse swap: B -> A (use fresh amounts)
        uint256 feeReverse = tokenAIsToken0 ? FEE_1_0_PERCENT : FEE_0_1_PERCENT;
        HopData memory hopReverse = _getHopData(pairAB, address(tokenB));
        uint256 reverseAmountIn = actualForward / 2; // Use half for reverse
        uint256 expectedReverse = ConstProdUtils._saleQuote(
            reverseAmountIn, hopReverse.reserveIn, hopReverse.reserveOut, feeReverse, FEE_DENOMINATOR
        );

        tokenB.approve(address(camelotV2Router), reverseAmountIn);

        address[] memory pathReverse = new address[](2);
        pathReverse[0] = address(tokenB);
        pathReverse[1] = address(tokenA);

        uint256 tokenABefore = tokenA.balanceOf(address(this));

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            reverseAmountIn, 0, pathReverse, address(this), address(0), block.timestamp + 300
        );

        uint256 actualReverse = tokenA.balanceOf(address(this)) - tokenABefore;
        assertEq(actualReverse, expectedReverse, "Reverse swap should apply correct directional fee");
    }

    /* ---------------------------------------------------------------------- */
    /*                      Accumulated Fee Impact Tests                      */
    /* ---------------------------------------------------------------------- */

    /**
     * @notice Test that fees compound correctly through multi-hop path
     * @dev Higher fees = more tokens lost at each hop, compounding the loss
     */
    function test_multihop_accumulatedFeeImpact() public {
        _initializeLiquidity();

        uint256 amountIn = SWAP_AMOUNT;

        // Scenario 1: All pools have minimum fees (0.1%)
        _setFees(pairAB, FEE_0_1_PERCENT, FEE_0_1_PERCENT);
        _setFees(pairBC, FEE_0_1_PERCENT, FEE_0_1_PERCENT);
        _setFees(pairCD, FEE_0_1_PERCENT, FEE_0_1_PERCENT);

        uint256 outputLowFees = _executeAndGetOutput(amountIn);

        // Reset pool reserves by redeploying
        _resetPools();

        // Scenario 2: All pools have higher fees (1.0%)
        _setFees(pairAB, FEE_1_0_PERCENT, FEE_1_0_PERCENT);
        _setFees(pairBC, FEE_1_0_PERCENT, FEE_1_0_PERCENT);
        _setFees(pairCD, FEE_1_0_PERCENT, FEE_1_0_PERCENT);

        uint256 outputHighFees = _executeAndGetOutput(amountIn);

        // Higher fees should result in significantly less output
        assertGt(outputLowFees, outputHighFees, "Low fees should yield more output than high fees");

        // Calculate expected ratio: fees compound multiplicatively
        // With 3 hops and 10x fee difference, output should be significantly different
        // 0.1% vs 1.0% fee difference, compounded over 3 hops
        // Low fees: (1 - 0.001)^3 * price_impact ≈ 0.997 of ideal
        // High fees: (1 - 0.01)^3 * price_impact ≈ 0.970 of ideal
        // Ratio is approximately 1.027 (2.7% more output with low fees)
        assertGe(
            outputLowFees * 100 / outputHighFees,
            102, // At least 2% more output with low fees
            "Fee compounding should have significant impact over 3 hops"
        );
    }

    /**
     * @notice Test specific path: A->B (0.3%) -> B->C (0.5%) -> C->D (0.1%)
     * @dev This is the exact scenario from the task requirements
     */
    function test_multihop_specificPath_0_3_0_5_0_1() public {
        _initializeLiquidity();

        // Configure the exact fee scenario from requirements
        // Note: Fee applied depends on token sort order
        // We'll set both directions to the same fee for clarity
        _setFees(pairAB, FEE_0_3_PERCENT, FEE_0_3_PERCENT); // 0.3% both directions
        _setFees(pairBC, FEE_0_5_PERCENT, FEE_0_5_PERCENT); // 0.5% both directions
        _setFees(pairCD, FEE_0_1_PERCENT, FEE_0_1_PERCENT); // 0.1% both directions

        uint256 amountIn = SWAP_AMOUNT;

        // Calculate expected cumulative output
        HopData memory hop1 = _getHopData(pairAB, address(tokenA));
        uint256 amountAfterHop1 = ConstProdUtils._saleQuote(
            amountIn, hop1.reserveIn, hop1.reserveOut, FEE_0_3_PERCENT, FEE_DENOMINATOR
        );

        HopData memory hop2 = _getHopData(pairBC, address(tokenB));
        uint256 amountAfterHop2 = ConstProdUtils._saleQuote(
            amountAfterHop1, hop2.reserveIn, hop2.reserveOut, FEE_0_5_PERCENT, FEE_DENOMINATOR
        );

        HopData memory hop3 = _getHopData(pairCD, address(tokenC));
        uint256 expectedFinal = ConstProdUtils._saleQuote(
            amountAfterHop2, hop3.reserveIn, hop3.reserveOut, FEE_0_1_PERCENT, FEE_DENOMINATOR
        );

        // Execute actual swap
        tokenA.mint(address(this), amountIn);
        tokenA.approve(address(camelotV2Router), amountIn);

        address[] memory path = new address[](4);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        path[2] = address(tokenC);
        path[3] = address(tokenD);

        uint256 balanceBefore = tokenD.balanceOf(address(this));

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn, 0, path, address(this), address(0), block.timestamp + 300
        );

        uint256 actualFinal = tokenD.balanceOf(address(this)) - balanceBefore;

        assertEq(actualFinal, expectedFinal, "Path A->B(0.3%)->C(0.5%)->D(0.1%) quote should match actual");
    }

    /**
     * @notice Test intermediate amounts at each hop
     * @dev Verifies step-by-step that each hop applies the correct fee
     */
    function test_multihop_intermediateAmounts_differentFees() public {
        _initializeLiquidity();

        // Configure distinct fees for each pair
        _setFees(pairAB, FEE_0_3_PERCENT, FEE_0_3_PERCENT);
        _setFees(pairBC, FEE_0_5_PERCENT, FEE_0_5_PERCENT);
        _setFees(pairCD, FEE_0_1_PERCENT, FEE_0_1_PERCENT);

        uint256 amountIn = SWAP_AMOUNT;

        // Get pre-swap data
        HopData memory hop1 = _getHopData(pairAB, address(tokenA));
        uint256 expectedAmountB = ConstProdUtils._saleQuote(
            amountIn, hop1.reserveIn, hop1.reserveOut, FEE_0_3_PERCENT, FEE_DENOMINATOR
        );

        // Execute hop 1
        tokenA.mint(address(this), amountIn);
        tokenA.approve(address(camelotV2Router), amountIn);

        address[] memory path1 = new address[](2);
        path1[0] = address(tokenA);
        path1[1] = address(tokenB);

        uint256 tokenBBefore = tokenB.balanceOf(address(this));

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn, 0, path1, address(this), address(0), block.timestamp + 300
        );

        uint256 actualAmountB = tokenB.balanceOf(address(this)) - tokenBBefore;
        assertEq(actualAmountB, expectedAmountB, "Hop 1 intermediate amount should match (0.3% fee)");

        // Get data for hop 2 (reserves changed after hop 1)
        HopData memory hop2 = _getHopData(pairBC, address(tokenB));
        uint256 expectedAmountC = ConstProdUtils._saleQuote(
            actualAmountB, hop2.reserveIn, hop2.reserveOut, FEE_0_5_PERCENT, FEE_DENOMINATOR
        );

        // Execute hop 2
        tokenB.approve(address(camelotV2Router), actualAmountB);

        address[] memory path2 = new address[](2);
        path2[0] = address(tokenB);
        path2[1] = address(tokenC);

        uint256 tokenCBefore = tokenC.balanceOf(address(this));

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            actualAmountB, 0, path2, address(this), address(0), block.timestamp + 300
        );

        uint256 actualAmountC = tokenC.balanceOf(address(this)) - tokenCBefore;
        assertEq(actualAmountC, expectedAmountC, "Hop 2 intermediate amount should match (0.5% fee)");

        // Get data for hop 3
        HopData memory hop3 = _getHopData(pairCD, address(tokenC));
        uint256 expectedAmountD = ConstProdUtils._saleQuote(
            actualAmountC, hop3.reserveIn, hop3.reserveOut, FEE_0_1_PERCENT, FEE_DENOMINATOR
        );

        // Execute hop 3
        tokenC.approve(address(camelotV2Router), actualAmountC);

        address[] memory path3 = new address[](2);
        path3[0] = address(tokenC);
        path3[1] = address(tokenD);

        uint256 tokenDBefore = tokenD.balanceOf(address(this));

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            actualAmountC, 0, path3, address(this), address(0), block.timestamp + 300
        );

        uint256 actualAmountD = tokenD.balanceOf(address(this)) - tokenDBefore;
        assertEq(actualAmountD, expectedAmountD, "Hop 3 final amount should match (0.1% fee)");
    }

    /* ---------------------------------------------------------------------- */
    /*                      Cumulative Quote Verification                     */
    /* ---------------------------------------------------------------------- */

    /**
     * @notice Verify cumulative quote calculation matches actual multi-hop swap
     * @dev Tests the complete workflow: calculate quote, execute swap, verify match
     */
    function test_multihop_cumulativeQuoteMatchesActual() public {
        _initializeLiquidity();

        // Configure various fee combinations
        _setFees(pairAB, FEE_0_2_PERCENT, FEE_0_4_PERCENT);
        _setFees(pairBC, FEE_0_3_PERCENT, FEE_0_5_PERCENT);
        _setFees(pairCD, FEE_0_1_PERCENT, FEE_0_2_PERCENT);

        uint256 amountIn = SWAP_AMOUNT;

        // Pre-calculate cumulative quote
        uint256 expectedAmountB = _calculateSaleQuote(pairAB, address(tokenA), amountIn);
        uint256 expectedAmountC = _calculateSaleQuote(pairBC, address(tokenB), expectedAmountB);
        uint256 expectedAmountD = _calculateSaleQuote(pairCD, address(tokenC), expectedAmountC);

        // Execute multi-hop swap in one transaction
        tokenA.mint(address(this), amountIn);
        tokenA.approve(address(camelotV2Router), amountIn);

        address[] memory path = new address[](4);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        path[2] = address(tokenC);
        path[3] = address(tokenD);

        uint256 balanceBefore = tokenD.balanceOf(address(this));

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn, 0, path, address(this), address(0), block.timestamp + 300
        );

        uint256 actualAmountD = tokenD.balanceOf(address(this)) - balanceBefore;

        // Cumulative quote should exactly match actual output
        assertEq(actualAmountD, expectedAmountD, "Cumulative quote must match actual swap output");
    }

    /**
     * @notice Fuzz test multi-hop with varying fees
     * @dev Verifies quote accuracy across a range of fee configurations
     */
    function testFuzz_multihop_varyingFees(
        uint16 fee1Token0,
        uint16 fee1Token1,
        uint16 fee2Token0,
        uint16 fee2Token1,
        uint16 fee3Token0,
        uint16 fee3Token1,
        uint256 amountIn
    ) public {
        _initializeLiquidity();

        // Bound fees to valid range (1-2000 basis points = 0.001% to 2%)
        fee1Token0 = uint16(bound(fee1Token0, 1, 2000));
        fee1Token1 = uint16(bound(fee1Token1, 1, 2000));
        fee2Token0 = uint16(bound(fee2Token0, 1, 2000));
        fee2Token1 = uint16(bound(fee2Token1, 1, 2000));
        fee3Token0 = uint16(bound(fee3Token0, 1, 2000));
        fee3Token1 = uint16(bound(fee3Token1, 1, 2000));

        // Bound amount to reasonable range
        amountIn = bound(amountIn, 1e15, INITIAL_LIQUIDITY / 10);

        // Configure fees
        _setFees(pairAB, fee1Token0, fee1Token1);
        _setFees(pairBC, fee2Token0, fee2Token1);
        _setFees(pairCD, fee3Token0, fee3Token1);

        // Calculate expected output
        uint256 expectedAmountB = _calculateSaleQuote(pairAB, address(tokenA), amountIn);
        vm.assume(expectedAmountB > 0);

        uint256 expectedAmountC = _calculateSaleQuote(pairBC, address(tokenB), expectedAmountB);
        vm.assume(expectedAmountC > 0);

        uint256 expectedAmountD = _calculateSaleQuote(pairCD, address(tokenC), expectedAmountC);
        vm.assume(expectedAmountD > 0);

        // Execute swap
        tokenA.mint(address(this), amountIn);
        tokenA.approve(address(camelotV2Router), amountIn);

        address[] memory path = new address[](4);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        path[2] = address(tokenC);
        path[3] = address(tokenD);

        uint256 balanceBefore = tokenD.balanceOf(address(this));

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn, 0, path, address(this), address(0), block.timestamp + 300
        );

        uint256 actualAmountD = tokenD.balanceOf(address(this)) - balanceBefore;
        assertEq(actualAmountD, expectedAmountD, "Fuzz: quote should match actual with varying fees");
    }

    /* ---------------------------------------------------------------------- */
    /*                            Helper Functions                            */
    /* ---------------------------------------------------------------------- */

    /**
     * @dev Get HopData struct with reserves and fee for a given pair and input token
     */
    function _getHopData(ICamelotPair pair, address tokenIn) internal view returns (HopData memory data) {
        (uint112 r0, uint112 r1, uint16 token0Fee, uint16 token1Fee) = pair.getReserves();
        (data.reserveIn, data.feePercent, data.reserveOut,) =
            ConstProdUtils._sortReserves(tokenIn, pair.token0(), r0, uint256(token0Fee), r1, uint256(token1Fee));
    }

    /**
     * @dev Calculate sale quote for a given pair and input token
     */
    function _calculateSaleQuote(ICamelotPair pair, address tokenIn, uint256 amountIn)
        internal
        view
        returns (uint256)
    {
        HopData memory data = _getHopData(pair, tokenIn);
        return ConstProdUtils._saleQuote(amountIn, data.reserveIn, data.reserveOut, data.feePercent, FEE_DENOMINATOR);
    }

    /**
     * @dev Execute 3-hop swap and return output amount
     */
    function _executeAndGetOutput(uint256 amountIn) internal returns (uint256) {
        tokenA.mint(address(this), amountIn);
        tokenA.approve(address(camelotV2Router), amountIn);

        uint256 balanceBefore = tokenD.balanceOf(address(this));

        address[] memory path = new address[](4);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        path[2] = address(tokenC);
        path[3] = address(tokenD);

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn, 0, path, address(this), address(0), block.timestamp + 300
        );

        return tokenD.balanceOf(address(this)) - balanceBefore;
    }

    /**
     * @dev Reset pools by creating new pairs and reinitializing liquidity
     */
    function _resetPools() internal {
        // Create new tokens
        tokenA = new ERC20PermitMintableStub("Token A Reset", "TKAR", 18, address(this), 0);
        tokenB = new ERC20PermitMintableStub("Token B Reset", "TKBR", 18, address(this), 0);
        tokenC = new ERC20PermitMintableStub("Token C Reset", "TKCR", 18, address(this), 0);
        tokenD = new ERC20PermitMintableStub("Token D Reset", "TKDR", 18, address(this), 0);

        // Create new pairs
        pairAB = ICamelotPair(camelotV2Factory.createPair(address(tokenA), address(tokenB)));
        pairBC = ICamelotPair(camelotV2Factory.createPair(address(tokenB), address(tokenC)));
        pairCD = ICamelotPair(camelotV2Factory.createPair(address(tokenC), address(tokenD)));

        // Initialize liquidity
        _initializeLiquidity();
    }
}
