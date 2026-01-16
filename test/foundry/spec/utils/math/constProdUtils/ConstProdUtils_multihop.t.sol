// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Test.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {FEE_DENOMINATOR} from "@crane/contracts/constants/Constants.sol";
import {ICamelotPair} from "@crane/contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {CamelotV2Service} from "@crane/contracts/protocols/dexes/camelot/v2/services/CamelotV2Service.sol";
import {TestBase_CamelotV2} from "@crane/contracts/protocols/dexes/camelot/v2/test/bases/TestBase_CamelotV2.sol";
import {ERC20PermitMintableStub} from "@crane/contracts/tokens/ERC20/ERC20PermitMintableStub.sol";

/**
 * @title ConstProdUtils Multi-hop Routing Tests
 * @notice Tests for chained swap calculations across multiple pools (multi-hop routes)
 * @dev Verifies that intermediate amounts in multi-hop routes match expected values
 */
contract ConstProdUtils_multihop is TestBase_CamelotV2 {
    using ConstProdUtils for uint256;

    // Tokens for multi-hop routes
    ERC20PermitMintableStub tokenA;
    ERC20PermitMintableStub tokenB;
    ERC20PermitMintableStub tokenC;
    ERC20PermitMintableStub tokenD;

    // Pairs for multi-hop routes
    ICamelotPair pairAB;
    ICamelotPair pairBC;
    ICamelotPair pairCD;

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

    function setUp() public override {
        TestBase_CamelotV2.setUp();
        _createTokens();
        _createPairs();
        _initializeLiquidity();
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

    function _initializeLiquidity() internal {
        // Initialize pair A-B (balanced)
        tokenA.mint(address(this), INITIAL_LIQUIDITY);
        tokenA.approve(address(camelotV2Router), INITIAL_LIQUIDITY);
        tokenB.mint(address(this), INITIAL_LIQUIDITY);
        tokenB.approve(address(camelotV2Router), INITIAL_LIQUIDITY);
        CamelotV2Service._deposit(camelotV2Router, tokenA, tokenB, INITIAL_LIQUIDITY, INITIAL_LIQUIDITY);

        // Initialize pair B-C (balanced)
        tokenB.mint(address(this), INITIAL_LIQUIDITY);
        tokenB.approve(address(camelotV2Router), INITIAL_LIQUIDITY);
        tokenC.mint(address(this), INITIAL_LIQUIDITY);
        tokenC.approve(address(camelotV2Router), INITIAL_LIQUIDITY);
        CamelotV2Service._deposit(camelotV2Router, tokenB, tokenC, INITIAL_LIQUIDITY, INITIAL_LIQUIDITY);

        // Initialize pair C-D (balanced)
        tokenC.mint(address(this), INITIAL_LIQUIDITY);
        tokenC.approve(address(camelotV2Router), INITIAL_LIQUIDITY);
        tokenD.mint(address(this), INITIAL_LIQUIDITY);
        tokenD.approve(address(camelotV2Router), INITIAL_LIQUIDITY);
        CamelotV2Service._deposit(camelotV2Router, tokenC, tokenD, INITIAL_LIQUIDITY, INITIAL_LIQUIDITY);
    }

    /* -------------------------------------------------------------------------- */
    /*                           2-Hop Route Tests (A->B->C)                      */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Test 2-hop _saleQuote: A -> B -> C
     * @dev Verifies chained forward swap calculations match actual router execution
     */
    function test_multihop_saleQuote_2hop_AtoC() public {
        uint256 amountIn = SWAP_AMOUNT;

        // Calculate expected output through 2 hops using ConstProdUtils
        uint256 expectedAmountB = _calculateSaleQuote(pairAB, address(tokenA), amountIn);
        uint256 expectedAmountC = _calculateSaleQuote(pairBC, address(tokenB), expectedAmountB);

        // Execute actual swap through router
        tokenA.mint(address(this), amountIn);
        tokenA.approve(address(camelotV2Router), amountIn);

        address[] memory path = new address[](3);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        path[2] = address(tokenC);

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            0, // Accept any amount for test
            path,
            address(this),
            address(0),
            block.timestamp + 300
        );

        uint256 actualAmountC = tokenC.balanceOf(address(this));

        // Verify the calculated amount matches actual
        assertEq(actualAmountC, expectedAmountC, "2-hop saleQuote should match actual output");
    }

    /**
     * @notice Test 2-hop _purchaseQuote: C -> B -> A (reverse direction)
     * @dev Verifies chained reverse quote calculations to get desired output
     */
    function test_multihop_purchaseQuote_2hop_AtoC() public {
        uint256 desiredAmountC = SWAP_AMOUNT / 2; // Want 50e18 of token C

        // Calculate required input through 2 hops using ConstProdUtils (working backwards)
        uint256 requiredAmountB = _calculatePurchaseQuote(pairBC, address(tokenC), desiredAmountC);
        uint256 requiredAmountA = _calculatePurchaseQuote(pairAB, address(tokenB), requiredAmountB);

        // Execute actual swap through router with calculated input
        tokenA.mint(address(this), requiredAmountA);
        tokenA.approve(address(camelotV2Router), requiredAmountA);

        address[] memory path = new address[](3);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        path[2] = address(tokenC);

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            requiredAmountA,
            desiredAmountC, // Minimum output
            path,
            address(this),
            address(0),
            block.timestamp + 300
        );

        uint256 actualAmountC = tokenC.balanceOf(address(this));

        // Verify we got at least the desired amount
        assertGe(actualAmountC, desiredAmountC, "2-hop purchaseQuote should yield at least desired output");
    }

    /**
     * @notice Test intermediate amounts in 2-hop route
     * @dev Verifies each hop's output matches expected intermediate values
     */
    function test_multihop_intermediateAmounts_2hop() public {
        uint256 amountIn = SWAP_AMOUNT;

        // Get reserves before any swap
        HopData memory hop1 = _getHopData(pairAB, address(tokenA));
        HopData memory hop2 = _getHopData(pairBC, address(tokenB));

        // Calculate expected intermediate amounts
        uint256 expectedAmountB = ConstProdUtils._saleQuote(
            amountIn, hop1.reserveIn, hop1.reserveOut, hop1.feePercent, FEE_DENOMINATOR
        );
        uint256 expectedAmountC = ConstProdUtils._saleQuote(
            expectedAmountB, hop2.reserveIn, hop2.reserveOut, hop2.feePercent, FEE_DENOMINATOR
        );

        // Execute first hop only
        tokenA.mint(address(this), amountIn);
        tokenA.approve(address(camelotV2Router), amountIn);

        address[] memory path1 = new address[](2);
        path1[0] = address(tokenA);
        path1[1] = address(tokenB);

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn, 0, path1, address(this), address(0), block.timestamp + 300
        );

        uint256 actualAmountB = tokenB.balanceOf(address(this));
        assertEq(actualAmountB, expectedAmountB, "Intermediate amount B should match");

        // Execute second hop
        tokenB.approve(address(camelotV2Router), actualAmountB);

        address[] memory path2 = new address[](2);
        path2[0] = address(tokenB);
        path2[1] = address(tokenC);

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            actualAmountB, 0, path2, address(this), address(0), block.timestamp + 300
        );

        uint256 actualAmountC = tokenC.balanceOf(address(this));
        assertEq(actualAmountC, expectedAmountC, "Final amount C should match");
    }

    /* -------------------------------------------------------------------------- */
    /*                         3-Hop Route Tests (A->B->C->D)                     */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Test 3-hop _saleQuote: A -> B -> C -> D
     * @dev Verifies chained forward swap calculations across 3 pools
     */
    function test_multihop_saleQuote_3hop_AtoD() public {
        uint256 amountIn = SWAP_AMOUNT;

        // Calculate expected output through 3 hops using ConstProdUtils
        uint256 expectedAmountB = _calculateSaleQuote(pairAB, address(tokenA), amountIn);
        uint256 expectedAmountC = _calculateSaleQuote(pairBC, address(tokenB), expectedAmountB);
        uint256 expectedAmountD = _calculateSaleQuote(pairCD, address(tokenC), expectedAmountC);

        // Execute actual swap through router
        tokenA.mint(address(this), amountIn);
        tokenA.approve(address(camelotV2Router), amountIn);

        address[] memory path = new address[](4);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        path[2] = address(tokenC);
        path[3] = address(tokenD);

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            0,
            path,
            address(this),
            address(0),
            block.timestamp + 300
        );

        uint256 actualAmountD = tokenD.balanceOf(address(this));

        assertEq(actualAmountD, expectedAmountD, "3-hop saleQuote should match actual output");
    }

    /**
     * @notice Test 3-hop _purchaseQuote: D -> C -> B -> A
     * @dev Verifies chained reverse quote calculations across 3 pools
     */
    function test_multihop_purchaseQuote_3hop_AtoD() public {
        uint256 desiredAmountD = SWAP_AMOUNT / 4; // Want 25e18 of token D

        // Calculate required input through 3 hops using ConstProdUtils (working backwards)
        uint256 requiredAmountC = _calculatePurchaseQuote(pairCD, address(tokenD), desiredAmountD);
        uint256 requiredAmountB = _calculatePurchaseQuote(pairBC, address(tokenC), requiredAmountC);
        uint256 requiredAmountA = _calculatePurchaseQuote(pairAB, address(tokenB), requiredAmountB);

        // Execute actual swap through router with calculated input
        tokenA.mint(address(this), requiredAmountA);
        tokenA.approve(address(camelotV2Router), requiredAmountA);

        address[] memory path = new address[](4);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        path[2] = address(tokenC);
        path[3] = address(tokenD);

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            requiredAmountA,
            desiredAmountD,
            path,
            address(this),
            address(0),
            block.timestamp + 300
        );

        uint256 actualAmountD = tokenD.balanceOf(address(this));

        assertGe(actualAmountD, desiredAmountD, "3-hop purchaseQuote should yield at least desired output");
    }

    /**
     * @notice Test all intermediate amounts in 3-hop route
     * @dev Verifies each hop's output matches expected intermediate values
     */
    function test_multihop_intermediateAmounts_3hop() public {
        uint256 amountIn = SWAP_AMOUNT;

        // Get reserves before any swap
        HopData memory hop1 = _getHopData(pairAB, address(tokenA));
        HopData memory hop2 = _getHopData(pairBC, address(tokenB));
        HopData memory hop3 = _getHopData(pairCD, address(tokenC));

        // Calculate expected intermediate amounts
        uint256 expectedAmountB = ConstProdUtils._saleQuote(
            amountIn, hop1.reserveIn, hop1.reserveOut, hop1.feePercent, FEE_DENOMINATOR
        );
        uint256 expectedAmountC = ConstProdUtils._saleQuote(
            expectedAmountB, hop2.reserveIn, hop2.reserveOut, hop2.feePercent, FEE_DENOMINATOR
        );
        uint256 expectedAmountD = ConstProdUtils._saleQuote(
            expectedAmountC, hop3.reserveIn, hop3.reserveOut, hop3.feePercent, FEE_DENOMINATOR
        );

        // Execute hop 1
        tokenA.mint(address(this), amountIn);
        tokenA.approve(address(camelotV2Router), amountIn);

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn, 0, path, address(this), address(0), block.timestamp + 300
        );
        uint256 actualAmountB = tokenB.balanceOf(address(this));
        assertEq(actualAmountB, expectedAmountB, "Intermediate B should match");

        // Execute hop 2
        tokenB.approve(address(camelotV2Router), actualAmountB);
        path[0] = address(tokenB);
        path[1] = address(tokenC);

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            actualAmountB, 0, path, address(this), address(0), block.timestamp + 300
        );
        uint256 actualAmountC = tokenC.balanceOf(address(this));
        assertEq(actualAmountC, expectedAmountC, "Intermediate C should match");

        // Execute hop 3
        tokenC.approve(address(camelotV2Router), actualAmountC);
        path[0] = address(tokenC);
        path[1] = address(tokenD);

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            actualAmountC, 0, path, address(this), address(0), block.timestamp + 300
        );
        uint256 actualAmountD = tokenD.balanceOf(address(this));
        assertEq(actualAmountD, expectedAmountD, "Final D should match");
    }

    /* -------------------------------------------------------------------------- */
    /*                                Fuzz Tests                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Fuzz test 2-hop route with varying input amounts
     * @dev Verifies calculation accuracy across a range of swap sizes
     */
    function testFuzz_multihop_2hop_varyingAmounts(uint256 amountIn) public {
        // Bound input to reasonable range (avoid dust and reserve-draining amounts)
        amountIn = bound(amountIn, 1e15, INITIAL_LIQUIDITY / 10);

        // Calculate expected output through 2 hops
        uint256 expectedAmountB = _calculateSaleQuote(pairAB, address(tokenA), amountIn);

        // Skip if first hop produces 0 output
        vm.assume(expectedAmountB > 0);

        uint256 expectedAmountC = _calculateSaleQuote(pairBC, address(tokenB), expectedAmountB);

        // Skip if final output is 0
        vm.assume(expectedAmountC > 0);

        // Execute actual swap
        tokenA.mint(address(this), amountIn);
        tokenA.approve(address(camelotV2Router), amountIn);

        address[] memory path = new address[](3);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        path[2] = address(tokenC);

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn, 0, path, address(this), address(0), block.timestamp + 300
        );

        uint256 actualAmountC = tokenC.balanceOf(address(this));
        assertEq(actualAmountC, expectedAmountC, "Fuzz 2-hop output should match");
    }

    /**
     * @notice Fuzz test 3-hop route with varying input amounts
     * @dev Verifies calculation accuracy across 3 pools with varied sizes
     */
    function testFuzz_multihop_3hop_varyingAmounts(uint256 amountIn) public {
        // Bound input to reasonable range
        amountIn = bound(amountIn, 1e15, INITIAL_LIQUIDITY / 20);

        // Calculate expected output through 3 hops
        uint256 expectedAmountB = _calculateSaleQuote(pairAB, address(tokenA), amountIn);
        vm.assume(expectedAmountB > 0);

        uint256 expectedAmountC = _calculateSaleQuote(pairBC, address(tokenB), expectedAmountB);
        vm.assume(expectedAmountC > 0);

        uint256 expectedAmountD = _calculateSaleQuote(pairCD, address(tokenC), expectedAmountC);
        vm.assume(expectedAmountD > 0);

        // Execute actual swap
        tokenA.mint(address(this), amountIn);
        tokenA.approve(address(camelotV2Router), amountIn);

        address[] memory path = new address[](4);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        path[2] = address(tokenC);
        path[3] = address(tokenD);

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn, 0, path, address(this), address(0), block.timestamp + 300
        );

        uint256 actualAmountD = tokenD.balanceOf(address(this));
        assertEq(actualAmountD, expectedAmountD, "Fuzz 3-hop output should match");
    }

    /**
     * @notice Fuzz test with varying pool reserves
     * @dev Creates new pools with fuzzed reserves and tests multi-hop accuracy
     */
    function testFuzz_multihop_varyingReserves(
        uint256 reserveAB_A,
        uint256 reserveAB_B,
        uint256 reserveBC_B,
        uint256 reserveBC_C,
        uint256 amountIn
    ) public {
        // Bound reserves to reasonable range (avoid extreme ratios)
        reserveAB_A = bound(reserveAB_A, 1000e18, 100_000e18);
        reserveAB_B = bound(reserveAB_B, 1000e18, 100_000e18);
        reserveBC_B = bound(reserveBC_B, 1000e18, 100_000e18);
        reserveBC_C = bound(reserveBC_C, 1000e18, 100_000e18);

        // Bound input to be small relative to reserves
        uint256 maxInput = reserveAB_A / 20;
        amountIn = bound(amountIn, 1e15, maxInput > 1e15 ? maxInput : 1e16);

        // Create new tokens for this test
        ERC20PermitMintableStub fuzzTokenA = new ERC20PermitMintableStub("FuzzA", "FA", 18, address(this), 0);
        ERC20PermitMintableStub fuzzTokenB = new ERC20PermitMintableStub("FuzzB", "FB", 18, address(this), 0);
        ERC20PermitMintableStub fuzzTokenC = new ERC20PermitMintableStub("FuzzC", "FC", 18, address(this), 0);

        // Create pairs with fuzzed reserves
        ICamelotPair fuzzPairAB = ICamelotPair(camelotV2Factory.createPair(address(fuzzTokenA), address(fuzzTokenB)));
        ICamelotPair fuzzPairBC = ICamelotPair(camelotV2Factory.createPair(address(fuzzTokenB), address(fuzzTokenC)));

        // Initialize pair AB
        fuzzTokenA.mint(address(this), reserveAB_A);
        fuzzTokenA.approve(address(camelotV2Router), reserveAB_A);
        fuzzTokenB.mint(address(this), reserveAB_B);
        fuzzTokenB.approve(address(camelotV2Router), reserveAB_B);
        CamelotV2Service._deposit(camelotV2Router, fuzzTokenA, fuzzTokenB, reserveAB_A, reserveAB_B);

        // Initialize pair BC
        fuzzTokenB.mint(address(this), reserveBC_B);
        fuzzTokenB.approve(address(camelotV2Router), reserveBC_B);
        fuzzTokenC.mint(address(this), reserveBC_C);
        fuzzTokenC.approve(address(camelotV2Router), reserveBC_C);
        CamelotV2Service._deposit(camelotV2Router, fuzzTokenB, fuzzTokenC, reserveBC_B, reserveBC_C);

        // Calculate expected output through 2 hops
        uint256 expectedAmountB = _calculateSaleQuote(fuzzPairAB, address(fuzzTokenA), amountIn);
        vm.assume(expectedAmountB > 0);

        uint256 expectedAmountC = _calculateSaleQuote(fuzzPairBC, address(fuzzTokenB), expectedAmountB);
        vm.assume(expectedAmountC > 0);

        // Execute actual swap
        fuzzTokenA.mint(address(this), amountIn);
        fuzzTokenA.approve(address(camelotV2Router), amountIn);

        address[] memory path = new address[](3);
        path[0] = address(fuzzTokenA);
        path[1] = address(fuzzTokenB);
        path[2] = address(fuzzTokenC);

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn, 0, path, address(this), address(0), block.timestamp + 300
        );

        uint256 actualAmountC = fuzzTokenC.balanceOf(address(this));
        assertEq(actualAmountC, expectedAmountC, "Fuzz varying reserves output should match");
    }

    /* -------------------------------------------------------------------------- */
    /*                              Helper Functions                              */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Get HopData struct with reserves and fee for a given pair and input token
     */
    function _getHopData(ICamelotPair pair, address tokenIn) internal view returns (HopData memory data) {
        (uint112 r0, uint112 r1, uint16 token0Fee, uint16 token1Fee) = pair.getReserves();
        (data.reserveIn, data.feePercent, data.reserveOut,) = ConstProdUtils._sortReserves(
            tokenIn, pair.token0(), r0, uint256(token0Fee), r1, uint256(token1Fee)
        );
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
     * @dev Calculate purchase quote for a given pair and output token
     */
    function _calculatePurchaseQuote(ICamelotPair pair, address tokenOut, uint256 amountOut)
        internal
        view
        returns (uint256)
    {
        // For purchase quote, we need reserves sorted for the OUTPUT token direction
        // tokenOut is what we want, so the "in" token is the other token
        address tokenIn = pair.token0() == tokenOut ? pair.token1() : pair.token0();
        HopData memory data = _getHopData(pair, tokenIn);
        return
            ConstProdUtils._purchaseQuote(amountOut, data.reserveIn, data.reserveOut, data.feePercent, FEE_DENOMINATOR);
    }
}
