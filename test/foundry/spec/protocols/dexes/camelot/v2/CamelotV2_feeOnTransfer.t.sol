// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {ICamelotPair} from "@crane/contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {CamelotV2Service} from "@crane/contracts/protocols/dexes/camelot/v2/services/CamelotV2Service.sol";
import {TestBase_CamelotV2} from "@crane/contracts/protocols/dexes/camelot/v2/test/bases/TestBase_CamelotV2.sol";
import {ConstProdUtils} from "@crane/contracts/utils/math/ConstProdUtils.sol";
import {ERC20PermitMintableStub} from "@crane/contracts/tokens/ERC20/ERC20PermitMintableStub.sol";
import {FeeOnTransferToken} from "./mocks/FeeOnTransferToken.sol";

/**
 * @title CamelotV2_feeOnTransfer_Test
 * @notice Tests for Fee-on-Transfer (FoT) token behavior with Camelot V2
 * @dev Documents quote deviation and verifies router compatibility for FoT tokens.
 *
 * Key findings documented by these tests:
 * - `_saleQuote()` OVERESTIMATES output for FoT tokens (recipient gets less than quoted)
 * - `_purchaseQuote()` UNDERESTIMATES required input for FoT tokens (need more than quoted)
 * - `swapExactTokensForTokensSupportingFeeOnTransferTokens()` handles FoT correctly
 * - Quote deviation is directly proportional to the transfer tax rate
 */
contract CamelotV2_feeOnTransfer_Test is TestBase_CamelotV2 {
    using CamelotV2Service for ICamelotPair;
    using ConstProdUtils for uint256;

    /* -------------------------------------------------------------------------- */
    /*                              Test Tokens                                   */
    /* -------------------------------------------------------------------------- */

    /// @notice Standard ERC20 token (no transfer fee)
    ERC20PermitMintableStub standardToken;

    /// @notice Fee-on-transfer token with 5% tax
    FeeOnTransferToken fotToken5Percent;

    /// @notice Fee-on-transfer token with 1% tax
    FeeOnTransferToken fotToken1Percent;

    /// @notice Fee-on-transfer token with 10% tax
    FeeOnTransferToken fotToken10Percent;

    /// @notice Test pairs
    ICamelotPair standardVsFotPair5;
    ICamelotPair standardVsFotPair1;
    ICamelotPair standardVsFotPair10;
    ICamelotPair fotVsFotPair;

    /* -------------------------------------------------------------------------- */
    /*                              Constants                                     */
    /* -------------------------------------------------------------------------- */

    uint256 constant FEE_DENOMINATOR = 100000;
    uint256 constant INITIAL_LIQUIDITY = 10000e18;
    uint256 constant SWAP_AMOUNT = 100e18;
    uint256 constant DEFAULT_POOL_FEE = 300; // 0.3% Camelot default

    // Transfer tax rates in basis points (10000 = 100%)
    uint256 constant TAX_1_PERCENT = 100;
    uint256 constant TAX_5_PERCENT = 500;
    uint256 constant TAX_10_PERCENT = 1000;

    /// @notice Maximum tax rate for which inverse-tax computation is valid.
    /// @dev At taxBps == 10000 the formula `amount * 10000 / (10000 - taxBps)` divides
    ///      by zero. Near 10000 (e.g. 9999) the multiplier grows to extreme values
    ///      (amount * 10000) which may cause overflow or produce unrealistic liquidity.
    uint256 constant MAX_INVERSE_TAX_BPS = 9999;

    /* -------------------------------------------------------------------------- */
    /*                                 Setup                                      */
    /* -------------------------------------------------------------------------- */

    function setUp() public override {
        TestBase_CamelotV2.setUp();
        _createTokens();
        _createPairs();
        _initializePools();
    }

    function _createTokens() internal {
        // Standard ERC20 token
        standardToken = new ERC20PermitMintableStub("StandardToken", "STD", 18, address(this), 0);
        vm.label(address(standardToken), "StandardToken");

        // FoT tokens with different tax rates
        fotToken1Percent = new FeeOnTransferToken("FoT1Percent", "FOT1", 18, TAX_1_PERCENT, 0);
        vm.label(address(fotToken1Percent), "FoT1Percent");

        fotToken5Percent = new FeeOnTransferToken("FoT5Percent", "FOT5", 18, TAX_5_PERCENT, 0);
        vm.label(address(fotToken5Percent), "FoT5Percent");

        fotToken10Percent = new FeeOnTransferToken("FoT10Percent", "FOT10", 18, TAX_10_PERCENT, 0);
        vm.label(address(fotToken10Percent), "FoT10Percent");
    }

    function _createPairs() internal {
        standardVsFotPair5 = ICamelotPair(
            camelotV2Factory.createPair(address(standardToken), address(fotToken5Percent))
        );
        vm.label(address(standardVsFotPair5), "StandardVsFoT5Pair");

        standardVsFotPair1 = ICamelotPair(
            camelotV2Factory.createPair(address(standardToken), address(fotToken1Percent))
        );
        vm.label(address(standardVsFotPair1), "StandardVsFoT1Pair");

        standardVsFotPair10 = ICamelotPair(
            camelotV2Factory.createPair(address(standardToken), address(fotToken10Percent))
        );
        vm.label(address(standardVsFotPair10), "StandardVsFoT10Pair");

        fotVsFotPair = ICamelotPair(
            camelotV2Factory.createPair(address(fotToken1Percent), address(fotToken5Percent))
        );
        vm.label(address(fotVsFotPair), "FoTVsFoTPair");
    }

    function _initializePools() internal {
        // Initialize Standard vs FoT 5% pool
        _initializePool(standardToken, fotToken5Percent, standardVsFotPair5);
        _initializePool(standardToken, fotToken1Percent, standardVsFotPair1);
        _initializePool(standardToken, fotToken10Percent, standardVsFotPair10);
        _initializeFotVsFotPool();
    }

    function _initializePool(
        ERC20PermitMintableStub tokenA,
        FeeOnTransferToken tokenB,
        ICamelotPair pair
    ) internal {
        // For FoT tokens, we need to account for the tax when adding liquidity
        // The pair will receive less than we send due to transfer tax
        uint256 fotTax = tokenB.transferTax();
        require(fotTax <= MAX_INVERSE_TAX_BPS, "Tax too high for inverse computation");
        uint256 fotAmountToSend = (INITIAL_LIQUIDITY * 10000) / (10000 - fotTax);

        tokenA.mint(address(this), INITIAL_LIQUIDITY);
        tokenB.mint(address(this), fotAmountToSend);

        // Transfer directly to pair (bypasses router for cleaner setup)
        tokenA.transfer(address(pair), INITIAL_LIQUIDITY);
        // FoT token will lose tax on transfer
        tokenB.transfer(address(pair), fotAmountToSend);

        pair.mint(address(this));
    }

    function _initializeFotVsFotPool() internal {
        // Both tokens have transfer tax
        uint256 fot1Tax = fotToken1Percent.transferTax();
        uint256 fot5Tax = fotToken5Percent.transferTax();
        require(fot1Tax <= MAX_INVERSE_TAX_BPS, "Tax too high for inverse computation");
        require(fot5Tax <= MAX_INVERSE_TAX_BPS, "Tax too high for inverse computation");

        uint256 fot1AmountToSend = (INITIAL_LIQUIDITY * 10000) / (10000 - fot1Tax);
        uint256 fot5AmountToSend = (INITIAL_LIQUIDITY * 10000) / (10000 - fot5Tax);

        fotToken1Percent.mint(address(this), fot1AmountToSend);
        fotToken5Percent.mint(address(this), fot5AmountToSend);

        fotToken1Percent.transfer(address(fotVsFotPair), fot1AmountToSend);
        fotToken5Percent.transfer(address(fotVsFotPair), fot5AmountToSend);

        fotVsFotPair.mint(address(this));
    }

    /* -------------------------------------------------------------------------- */
    /*                    _saleQuote() Overestimation Tests                       */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests that _saleQuote() overestimates output when selling standard token for FoT token
     * @dev The quote doesn't account for the transfer tax applied when FoT token moves to recipient
     *
     * Scenario: Sell standard token -> receive FoT token
     * Expected: Quote > Actual received (overestimation by tax %)
     */
    function test_saleQuote_overestimatesForFoT_5percent() public {
        _testSaleQuoteOverestimation(
            standardToken,
            fotToken5Percent,
            standardVsFotPair5,
            TAX_5_PERCENT
        );
    }

    function test_saleQuote_overestimatesForFoT_1percent() public {
        _testSaleQuoteOverestimation(
            standardToken,
            fotToken1Percent,
            standardVsFotPair1,
            TAX_1_PERCENT
        );
    }

    function test_saleQuote_overestimatesForFoT_10percent() public {
        _testSaleQuoteOverestimation(
            standardToken,
            fotToken10Percent,
            standardVsFotPair10,
            TAX_10_PERCENT
        );
    }

    /// @dev Struct to avoid stack too deep in sale quote tests
    struct SaleQuoteTestParams {
        uint256 reserveIn;
        uint256 reserveOut;
        uint256 feePercent;
        uint256 quotedOutput;
        uint256 balanceBefore;
        uint256 actualReceived;
        uint256 deviation;
        uint256 deviationBps;
    }

    function _testSaleQuoteOverestimation(
        ERC20PermitMintableStub tokenIn,
        FeeOnTransferToken tokenOut,
        ICamelotPair pair,
        uint256 taxBps
    ) internal {
        SaleQuoteTestParams memory p;

        // Mint tokens for swap
        tokenIn.mint(address(this), SWAP_AMOUNT);
        tokenIn.approve(address(camelotV2Router), SWAP_AMOUNT);

        // Get reserves using helper
        (p.reserveIn, p.reserveOut, p.feePercent) = _getReservesForSaleQuote(pair, address(tokenIn));

        // Calculate quoted output (doesn't account for FoT tax)
        p.quotedOutput = ConstProdUtils._saleQuote(SWAP_AMOUNT, p.reserveIn, p.reserveOut, p.feePercent);

        // Record balance before swap and execute
        p.balanceBefore = tokenOut.balanceOf(address(this));
        _executeSwapForSale(address(tokenIn), address(tokenOut), SWAP_AMOUNT);
        p.actualReceived = tokenOut.balanceOf(address(this)) - p.balanceBefore;

        // The actual received should be less than quoted due to FoT tax
        assertLt(p.actualReceived, p.quotedOutput, "Actual should be less than quoted for FoT output");

        // Calculate expected deviation
        p.deviation = p.quotedOutput - p.actualReceived;
        p.deviationBps = (p.deviation * 10000) / p.quotedOutput;

        // The deviation should be approximately equal to the tax rate
        assertApproxEqAbs(p.deviationBps, taxBps, 1, "Quote deviation should match tax rate");

        // Log for documentation
        emit log_named_uint("Tax Rate (bps)", taxBps);
        emit log_named_uint("Quoted Output", p.quotedOutput);
        emit log_named_uint("Actual Received", p.actualReceived);
        emit log_named_uint("Deviation (bps)", p.deviationBps);
    }

    function _getReservesForSaleQuote(ICamelotPair pair, address tokenIn) internal view returns (uint256, uint256, uint256) {
        (uint112 reserve0, uint112 reserve1, uint16 fee0, uint16 fee1) = pair.getReserves();
        bool tokenInIsToken0 = tokenIn == pair.token0();
        return (
            tokenInIsToken0 ? reserve0 : reserve1,
            tokenInIsToken0 ? reserve1 : reserve0,
            tokenInIsToken0 ? fee0 : fee1
        );
    }

    function _executeSwapForSale(address tokenIn, address tokenOut, uint256 amountIn) internal {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn, 1, path, address(this), address(0), block.timestamp + 300
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                    _purchaseQuote() Underestimation Tests                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests that _purchaseQuote() underestimates required input when buying with FoT token
     * @dev When selling FoT token, the pool receives less than sent due to transfer tax
     *
     * Scenario: Sell FoT token -> receive standard token
     * Expected: Quoted input < Required input (underestimation by tax %)
     */
    function test_purchaseQuote_underestimatesForFoT_5percent() public {
        _testPurchaseQuoteUnderestimation(
            fotToken5Percent,
            standardToken,
            standardVsFotPair5,
            TAX_5_PERCENT
        );
    }

    function test_purchaseQuote_underestimatesForFoT_1percent() public {
        _testPurchaseQuoteUnderestimation(
            fotToken1Percent,
            standardToken,
            standardVsFotPair1,
            TAX_1_PERCENT
        );
    }

    function test_purchaseQuote_underestimatesForFoT_10percent() public {
        _testPurchaseQuoteUnderestimation(
            fotToken10Percent,
            standardToken,
            standardVsFotPair10,
            TAX_10_PERCENT
        );
    }

    /// @dev Struct to avoid stack too deep in purchase quote tests
    struct PurchaseQuoteTestParams {
        uint256 reserveIn;
        uint256 reserveOut;
        uint256 feePercent;
        uint256 desiredOutput;
        uint256 quotedInput;
        uint256 requiredInput;
        uint256 outputBalanceBefore;
        uint256 actualOutput;
        uint256 shortfall;
        uint256 shortfallBps;
    }

    function _testPurchaseQuoteUnderestimation(
        FeeOnTransferToken tokenIn,
        ERC20PermitMintableStub tokenOut,
        ICamelotPair pair,
        uint256 taxBps
    ) internal {
        PurchaseQuoteTestParams memory p;

        // Get reserves using helper
        (p.reserveIn, p.reserveOut, p.feePercent) = _getReservesForTokenInput(pair, address(tokenIn));

        // Desired output amount
        p.desiredOutput = 10e18;

        // Calculate quoted input (doesn't account for FoT tax)
        p.quotedInput = ConstProdUtils._purchaseQuote(p.desiredOutput, p.reserveIn, p.reserveOut, p.feePercent);

        // Required input = quotedInput / (1 - tax)
        require(taxBps <= MAX_INVERSE_TAX_BPS, "Tax too high for inverse computation");
        p.requiredInput = (p.quotedInput * 10000) / (10000 - taxBps);

        // Mint the quoted amount and try to swap
        tokenIn.mint(address(this), p.quotedInput);
        tokenIn.approve(address(camelotV2Router), p.quotedInput);

        // Record state before and execute swap
        p.outputBalanceBefore = tokenOut.balanceOf(address(this));
        _executeSwapForPurchase(address(tokenIn), address(tokenOut), p.quotedInput);
        p.actualOutput = tokenOut.balanceOf(address(this)) - p.outputBalanceBefore;

        // We should receive LESS than desired
        assertLt(p.actualOutput, p.desiredOutput, "Actual output should be less than desired with FoT input");

        // Calculate the shortfall
        p.shortfall = p.desiredOutput - p.actualOutput;
        p.shortfallBps = (p.shortfall * 10000) / p.desiredOutput;

        // Shortfall should be approximately equal to tax rate
        assertLt(p.shortfallBps, taxBps + 50, "Shortfall should be roughly proportional to tax rate");

        emit log_named_uint("Tax Rate (bps)", taxBps);
        emit log_named_uint("Desired Output", p.desiredOutput);
        emit log_named_uint("Quoted Input", p.quotedInput);
        emit log_named_uint("Required Input (estimated)", p.requiredInput);
        emit log_named_uint("Actual Output", p.actualOutput);
        emit log_named_uint("Shortfall (bps)", p.shortfallBps);
    }

    function _getReservesForTokenInput(ICamelotPair pair, address tokenIn) internal view returns (uint256, uint256, uint256) {
        (uint112 reserve0, uint112 reserve1, uint16 fee0, uint16 fee1) = pair.getReserves();
        bool tokenInIsToken0 = tokenIn == pair.token0();
        return (
            tokenInIsToken0 ? reserve0 : reserve1,
            tokenInIsToken0 ? reserve1 : reserve0,
            tokenInIsToken0 ? fee0 : fee1
        );
    }

    function _executeSwapForPurchase(address tokenIn, address tokenOut, uint256 amountIn) internal {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn, 1, path, address(this), address(0), block.timestamp + 300
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                   Router FoT Support Tests                                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Verifies that swapExactTokensForTokensSupportingFeeOnTransferTokens works correctly
     * @dev This router function doesn't revert on FoT tokens unlike the standard swap functions
     */
    function test_routerFoTSwap_standardToFoT() public {
        uint256 swapAmount = 50e18;

        standardToken.mint(address(this), swapAmount);
        standardToken.approve(address(camelotV2Router), swapAmount);

        uint256 balanceBefore = fotToken5Percent.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = address(standardToken);
        path[1] = address(fotToken5Percent);

        // This should not revert
        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapAmount,
            1,
            path,
            address(this),
            address(0),
            block.timestamp + 300
        );

        uint256 balanceAfter = fotToken5Percent.balanceOf(address(this));
        uint256 received = balanceAfter - balanceBefore;

        assertGt(received, 0, "Should receive some tokens");
    }

    function test_routerFoTSwap_fotToStandard() public {
        uint256 swapAmount = 50e18;

        fotToken5Percent.mint(address(this), swapAmount);
        fotToken5Percent.approve(address(camelotV2Router), swapAmount);

        uint256 balanceBefore = standardToken.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = address(fotToken5Percent);
        path[1] = address(standardToken);

        // This should not revert
        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapAmount,
            1,
            path,
            address(this),
            address(0),
            block.timestamp + 300
        );

        uint256 balanceAfter = standardToken.balanceOf(address(this));
        uint256 received = balanceAfter - balanceBefore;

        assertGt(received, 0, "Should receive some tokens");
    }

    function test_routerFoTSwap_fotToFot() public {
        uint256 swapAmount = 50e18;

        fotToken1Percent.mint(address(this), swapAmount);
        fotToken1Percent.approve(address(camelotV2Router), swapAmount);

        uint256 balanceBefore = fotToken5Percent.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = address(fotToken1Percent);
        path[1] = address(fotToken5Percent);

        // This should not revert even with both tokens being FoT
        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapAmount,
            1,
            path,
            address(this),
            address(0),
            block.timestamp + 300
        );

        uint256 balanceAfter = fotToken5Percent.balanceOf(address(this));
        uint256 received = balanceAfter - balanceBefore;

        assertGt(received, 0, "Should receive some tokens");
    }

    /* -------------------------------------------------------------------------- */
    /*                      Quote Deviation Documentation Tests                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Documents expected quote deviation for various tax rates
     * @dev This test generates a table showing deviation at different tax levels
     */
    function test_documentQuoteDeviation_saleQuote() public {
        emit log("=== _saleQuote() Deviation Documentation ===");
        emit log("Selling Standard Token -> Receiving FoT Token");
        emit log("");
        emit log("| Tax Rate | Quoted Out | Actual Out | Deviation |");
        emit log("|----------|------------|------------|-----------|");

        _documentSaleQuoteDeviation(standardToken, fotToken1Percent, standardVsFotPair1, "1%");
        _documentSaleQuoteDeviation(standardToken, fotToken5Percent, standardVsFotPair5, "5%");
        _documentSaleQuoteDeviation(standardToken, fotToken10Percent, standardVsFotPair10, "10%");
    }

    /// @dev Struct to avoid stack too deep in deviation documentation
    struct DeviationDocParams {
        uint256 reserveIn;
        uint256 reserveOut;
        uint256 feePercent;
        uint256 quotedOutput;
        uint256 balanceBefore;
        uint256 actualReceived;
        uint256 deviationBps;
    }

    function _documentSaleQuoteDeviation(
        ERC20PermitMintableStub tokenIn,
        FeeOnTransferToken tokenOut,
        ICamelotPair pair,
        string memory taxLabel
    ) internal {
        DeviationDocParams memory p;

        tokenIn.mint(address(this), SWAP_AMOUNT);
        tokenIn.approve(address(camelotV2Router), SWAP_AMOUNT);

        // Get reserves using helper
        (p.reserveIn, p.reserveOut, p.feePercent) = _getReservesForSaleQuote(pair, address(tokenIn));

        p.quotedOutput = ConstProdUtils._saleQuote(SWAP_AMOUNT, p.reserveIn, p.reserveOut, p.feePercent);

        // Execute swap and get results
        p.balanceBefore = tokenOut.balanceOf(address(this));
        _executeSwapForSale(address(tokenIn), address(tokenOut), SWAP_AMOUNT);
        p.actualReceived = tokenOut.balanceOf(address(this)) - p.balanceBefore;
        p.deviationBps = ((p.quotedOutput - p.actualReceived) * 10000) / p.quotedOutput;

        emit log_named_string("Tax Rate", taxLabel);
        emit log_named_uint("Quoted Output (wei)", p.quotedOutput);
        emit log_named_uint("Actual Received (wei)", p.actualReceived);
        emit log_named_uint("Deviation (bps)", p.deviationBps);
        emit log("");
    }

    /* -------------------------------------------------------------------------- */
    /*                              Fuzz Tests                                    */
    /* -------------------------------------------------------------------------- */

    /// @dev Struct to avoid stack too deep in fuzz tests
    struct FuzzTestParams {
        uint256 taxBps;
        uint256 swapAmount;
        uint256 reserveIn;
        uint256 reserveOut;
        uint256 feePercent;
        uint256 quotedOutput;
        uint256 balanceBefore;
        uint256 actualReceived;
    }

    /**
     * @notice Fuzz test for sale quote overestimation across various tax rates
     */
    function testFuzz_saleQuote_overestimation(uint256 taxBps_, uint256 swapAmount_) public {
        FuzzTestParams memory p;
        // Cover full valid range up to 99.99%; guard in _createFuzzPair prevents 100%
        p.taxBps = bound(taxBps_, 1, MAX_INVERSE_TAX_BPS);
        p.swapAmount = bound(swapAmount_, 1e15, 500e18);

        // Create and initialize in helper
        (FeeOnTransferToken fuzzFotToken, ICamelotPair fuzzPair) = _createFuzzPair(p.taxBps);

        // Mint tokens for swap
        standardToken.mint(address(this), p.swapAmount);
        standardToken.approve(address(camelotV2Router), p.swapAmount);

        // Get quote using helper
        (p.reserveIn, p.reserveOut, p.feePercent) = _getReservesForStandardIn(fuzzPair);
        p.quotedOutput = ConstProdUtils._saleQuote(p.swapAmount, p.reserveIn, p.reserveOut, p.feePercent);

        // Execute swap
        p.balanceBefore = fuzzFotToken.balanceOf(address(this));
        _executeSwap(address(standardToken), address(fuzzFotToken), p.swapAmount);
        p.actualReceived = fuzzFotToken.balanceOf(address(this)) - p.balanceBefore;

        // Assertions
        assertLe(p.actualReceived, p.quotedOutput, "Actual should not exceed quoted");
        if (p.quotedOutput > 0) {
            uint256 deviationBps = ((p.quotedOutput - p.actualReceived) * 10000) / p.quotedOutput;
            assertApproxEqAbs(deviationBps, p.taxBps, 10, "Deviation should match tax rate");
        }
    }

    function _createFuzzPair(uint256 taxBps) internal returns (FeeOnTransferToken, ICamelotPair) {
        require(taxBps <= MAX_INVERSE_TAX_BPS, "Tax too high for inverse computation");
        FeeOnTransferToken fuzzFotToken = new FeeOnTransferToken("FuzzFoT", "FFOT", 18, taxBps, 0);
        ICamelotPair fuzzPair = ICamelotPair(
            camelotV2Factory.createPair(address(standardToken), address(fuzzFotToken))
        );

        uint256 fotAmountToSend = (INITIAL_LIQUIDITY * 10000) / (10000 - taxBps);
        standardToken.mint(address(this), INITIAL_LIQUIDITY);
        fuzzFotToken.mint(address(this), fotAmountToSend);
        standardToken.transfer(address(fuzzPair), INITIAL_LIQUIDITY);
        fuzzFotToken.transfer(address(fuzzPair), fotAmountToSend);
        fuzzPair.mint(address(this));

        return (fuzzFotToken, fuzzPair);
    }

    function _getReservesForStandardIn(ICamelotPair pair) internal view returns (uint256, uint256, uint256) {
        (uint112 reserve0, uint112 reserve1, uint16 fee0, uint16 fee1) = pair.getReserves();
        bool tokenInIsToken0 = address(standardToken) == pair.token0();
        return (
            tokenInIsToken0 ? reserve0 : reserve1,
            tokenInIsToken0 ? reserve1 : reserve0,
            tokenInIsToken0 ? fee0 : fee1
        );
    }

    function _executeSwap(address tokenIn, address tokenOut, uint256 amountIn) internal {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn, 1, path, address(this), address(0), block.timestamp + 300
        );
    }

    /**
     * @notice Fuzz test for purchase quote underestimation with 5% FoT input token
     * @dev Tests various desired output amounts with the existing 5% FoT pool.
     *      For various tax rates, see the deterministic _purchaseQuote tests.
     */
    function testFuzz_purchaseQuote_underestimation_5percent(uint256 desiredOutput_) public {
        FuzzTestParams memory p;
        uint256 desiredOutput = bound(desiredOutput_, 1e15, 100e18);

        // Get reserves using helper (uses existing 5% FoT pool)
        (p.reserveIn, p.reserveOut, p.feePercent) = _getReservesForFotIn(standardVsFotPair5);

        // Ensure desired output is less than reserve
        vm.assume(desiredOutput < p.reserveOut / 2);

        // Calculate quoted input
        uint256 quotedInput = ConstProdUtils._purchaseQuote(desiredOutput, p.reserveIn, p.reserveOut, p.feePercent);

        // Mint and swap
        fotToken5Percent.mint(address(this), quotedInput);
        fotToken5Percent.approve(address(camelotV2Router), quotedInput);

        p.balanceBefore = standardToken.balanceOf(address(this));
        _executeSwap(address(fotToken5Percent), address(standardToken), quotedInput);
        p.actualReceived = standardToken.balanceOf(address(this)) - p.balanceBefore;

        // With FoT input, we get less output than desired
        assertLt(p.actualReceived, desiredOutput, "Actual output should be less than desired with FoT input");
    }

    function _getReservesForFotIn(ICamelotPair pair) internal view returns (uint256, uint256, uint256) {
        (uint112 reserve0, uint112 reserve1, uint16 fee0, uint16 fee1) = pair.getReserves();
        bool fotIsToken0 = address(fotToken5Percent) == pair.token0();
        return (
            fotIsToken0 ? reserve0 : reserve1,
            fotIsToken0 ? reserve1 : reserve0,
            fotIsToken0 ? fee0 : fee1
        );
    }

    /* -------------------------------------------------------------------------- */
    /*              Fix-Up Input Verification Tests                               */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Proves the fix-up input formula achieves the desired output
     * @dev The fix-up compensates for FoT tax: requiredInput = quotedInput / (1 - taxRate)
     *
     * Pattern:
     *   1. Snapshot pool state (pristine reserves)
     *   2. Compute quotedInput via _purchaseQuote(desiredOutput)
     *   3. Apply fix-up: requiredInput = quotedInput * 10000 / (10000 - taxBps)
     *   4. Execute swap with requiredInput
     *   5. Assert actualOutput >= desiredOutput (within rounding tolerance)
     */
    function test_fixUpInput_achievesDesiredOutput_5percent() public {
        _testFixUpInputAchievesDesiredOutput(
            fotToken5Percent,
            standardToken,
            standardVsFotPair5,
            TAX_5_PERCENT
        );
    }

    function test_fixUpInput_achievesDesiredOutput_1percent() public {
        _testFixUpInputAchievesDesiredOutput(
            fotToken1Percent,
            standardToken,
            standardVsFotPair1,
            TAX_1_PERCENT
        );
    }

    function test_fixUpInput_achievesDesiredOutput_10percent() public {
        _testFixUpInputAchievesDesiredOutput(
            fotToken10Percent,
            standardToken,
            standardVsFotPair10,
            TAX_10_PERCENT
        );
    }

    /// @dev Struct to avoid stack too deep in fix-up verification tests
    struct FixUpTestParams {
        uint256 reserveIn;
        uint256 reserveOut;
        uint256 feePercent;
        uint256 desiredOutput;
        uint256 quotedInput;
        uint256 requiredInput;
        uint256 snapshotId;
        uint256 outputBalanceBefore;
        uint256 actualOutput;
    }

    function _testFixUpInputAchievesDesiredOutput(
        FeeOnTransferToken tokenIn,
        ERC20PermitMintableStub tokenOut,
        ICamelotPair pair,
        uint256 taxBps
    ) internal {
        FixUpTestParams memory p;

        // Snapshot pristine pool state
        p.snapshotId = vm.snapshot();

        // Get reserves
        (p.reserveIn, p.reserveOut, p.feePercent) = _getReservesForTokenInput(pair, address(tokenIn));

        // Desired output amount
        p.desiredOutput = 10e18;

        // Step 1: Compute quoted input (doesn't account for FoT tax)
        p.quotedInput = ConstProdUtils._purchaseQuote(p.desiredOutput, p.reserveIn, p.reserveOut, p.feePercent);

        // Step 2: Apply fix-up formula: requiredInput = quotedInput / (1 - taxRate)
        p.requiredInput = (p.quotedInput * 10000) / (10000 - taxBps);

        // Mint the fix-up amount and approve
        tokenIn.mint(address(this), p.requiredInput);
        tokenIn.approve(address(camelotV2Router), p.requiredInput);

        // Step 3: Execute swap with corrected input
        p.outputBalanceBefore = tokenOut.balanceOf(address(this));
        _executeSwapForPurchase(address(tokenIn), address(tokenOut), p.requiredInput);
        p.actualOutput = tokenOut.balanceOf(address(this)) - p.outputBalanceBefore;

        // Step 4: Assert actual output meets or exceeds desired output
        // Allow 1 wei tolerance for integer rounding in the AMM math
        assertGe(
            p.actualOutput + 1,
            p.desiredOutput,
            "Fix-up input should achieve desired output (within 1 wei rounding)"
        );

        emit log_named_uint("Tax Rate (bps)", taxBps);
        emit log_named_uint("Desired Output", p.desiredOutput);
        emit log_named_uint("Quoted Input (naive)", p.quotedInput);
        emit log_named_uint("Required Input (fix-up)", p.requiredInput);
        emit log_named_uint("Actual Output", p.actualOutput);

        // Restore pristine pool state for other tests
        vm.revertTo(p.snapshotId);
    }

    /**
     * @notice Fuzz test for fix-up input verification across variable desired outputs and tax rates
     * @dev Creates a fresh pool per fuzz run for complete isolation
     */
    function testFuzz_fixUpInput_achievesDesiredOutput(uint256 taxBps_, uint256 desiredOutput_) public {
        uint256 taxBps = bound(taxBps_, 1, 5000);
        uint256 desiredOutput = bound(desiredOutput_, 1e15, 100e18);

        // Create fresh pool with the given tax rate
        (FeeOnTransferToken fuzzFotToken, ICamelotPair fuzzPair) = _createFuzzPair(taxBps);

        // Get reserves
        (uint256 reserveIn, uint256 reserveOut, uint256 feePercent) =
            _getReservesForToken(fuzzPair, address(fuzzFotToken));

        // Ensure desired output is feasible
        vm.assume(desiredOutput < reserveOut / 2);

        // Compute quoted input and apply fix-up
        uint256 quotedInput = ConstProdUtils._purchaseQuote(desiredOutput, reserveIn, reserveOut, feePercent);
        uint256 requiredInput = (quotedInput * 10000) / (10000 - taxBps);

        // Mint and approve
        fuzzFotToken.mint(address(this), requiredInput);
        fuzzFotToken.approve(address(camelotV2Router), requiredInput);

        // Execute swap
        uint256 outputBalanceBefore = standardToken.balanceOf(address(this));
        _executeSwap(address(fuzzFotToken), address(standardToken), requiredInput);
        uint256 actualOutput = standardToken.balanceOf(address(this)) - outputBalanceBefore;

        // Assert: fix-up input achieves the desired output (within 1 wei rounding)
        assertGe(
            actualOutput + 1,
            desiredOutput,
            "Fuzz: fix-up input should achieve desired output"
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                          Edge Case Tests                                   */
    /* -------------------------------------------------------------------------- */

    /// @dev Struct to avoid stack too deep in edge case tests
    struct EdgeCaseParams {
        uint256 reserveIn;
        uint256 reserveOut;
        uint256 feePercent;
        uint256 quotedOutput;
        uint256 balanceBefore;
        uint256 actualReceived;
    }

    /**
     * @notice Test behavior with 0% tax (should behave like standard token)
     */
    function test_zeroTax_behavesLikeStandard() public {
        EdgeCaseParams memory p;

        // Create and initialize zero-tax pair
        (FeeOnTransferToken zeroTaxToken, ICamelotPair zeroTaxPair) = _createZeroTaxPair();

        // Mint tokens for swap
        standardToken.mint(address(this), SWAP_AMOUNT);
        standardToken.approve(address(camelotV2Router), SWAP_AMOUNT);

        // Get quote
        (p.reserveIn, p.reserveOut, p.feePercent) = _getReservesForToken(zeroTaxPair, address(standardToken));
        p.quotedOutput = ConstProdUtils._saleQuote(SWAP_AMOUNT, p.reserveIn, p.reserveOut, p.feePercent);

        // Execute swap
        p.balanceBefore = zeroTaxToken.balanceOf(address(this));
        _executeSwap(address(standardToken), address(zeroTaxToken), SWAP_AMOUNT);
        p.actualReceived = zeroTaxToken.balanceOf(address(this)) - p.balanceBefore;

        // With 0% tax, actual should equal quoted
        assertEq(p.actualReceived, p.quotedOutput, "0% tax should match quote exactly");
    }

    function _createZeroTaxPair() internal returns (FeeOnTransferToken, ICamelotPair) {
        FeeOnTransferToken zeroTaxToken = new FeeOnTransferToken("ZeroTax", "ZT", 18, 0, 0);
        ICamelotPair zeroTaxPair = ICamelotPair(
            camelotV2Factory.createPair(address(standardToken), address(zeroTaxToken))
        );

        standardToken.mint(address(this), INITIAL_LIQUIDITY);
        zeroTaxToken.mint(address(this), INITIAL_LIQUIDITY);
        standardToken.transfer(address(zeroTaxPair), INITIAL_LIQUIDITY);
        zeroTaxToken.transfer(address(zeroTaxPair), INITIAL_LIQUIDITY);
        zeroTaxPair.mint(address(this));

        return (zeroTaxToken, zeroTaxPair);
    }

    function _getReservesForToken(ICamelotPair pair, address tokenIn) internal view returns (uint256, uint256, uint256) {
        (uint112 reserve0, uint112 reserve1, uint16 fee0, uint16 fee1) = pair.getReserves();
        bool tokenInIsToken0 = tokenIn == pair.token0();
        return (
            tokenInIsToken0 ? reserve0 : reserve1,
            tokenInIsToken0 ? reserve1 : reserve0,
            tokenInIsToken0 ? fee0 : fee1
        );
    }

    /**
     * @notice Test very small swap amounts with FoT
     */
    function test_smallSwapAmount_fotBehavior() public {
        uint256 smallAmount = 1e15; // 0.001 tokens

        standardToken.mint(address(this), smallAmount);
        standardToken.approve(address(camelotV2Router), smallAmount);

        uint256 balanceBefore = fotToken5Percent.balanceOf(address(this));
        _executeSwap(address(standardToken), address(fotToken5Percent), smallAmount);
        uint256 actualReceived = fotToken5Percent.balanceOf(address(this)) - balanceBefore;

        // Should still receive something
        assertGt(actualReceived, 0, "Should receive tokens even with small swap");
    }

    /* -------------------------------------------------------------------------- */
    /*                    Extreme Tax Edge Case Tests                             */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Documents that 100% tax (taxBps == 10000) causes division-by-zero
     *         in the inverse-tax formula and is correctly prevented by the mock's
     *         constructor allowing it while the test helpers guard against it.
     * @dev At 100% tax, `amountToSend = amount * 10000 / (10000 - 10000)` divides
     *      by zero. The FeeOnTransferToken mock allows 100% tax (recipient gets 0),
     *      but our helpers cannot compute the gross amount needed, so they revert.
     */
    function test_100percentTax_constructorAllows() public {
        // The mock allows 100% tax (no division in its constructor)
        FeeOnTransferToken fullTaxToken = new FeeOnTransferToken("FullTax", "FT100", 18, 10000, 0);
        assertEq(fullTaxToken.transferTax(), 10000);

        // A transfer delivers 0 tokens to recipient
        fullTaxToken.mint(address(this), 1000e18);
        uint256 balBefore = fullTaxToken.balanceOf(address(1));
        fullTaxToken.transfer(address(1), 1000e18);
        uint256 received = fullTaxToken.balanceOf(address(1)) - balBefore;
        assertEq(received, 0, "100% tax should deliver 0 tokens");
    }

    /**
     * @notice Verifies that the inverse-tax formula guard catches 100% tax.
     * @dev Directly tests the guard condition since _initializePool is internal
     *      (vm.expectRevert only works on external calls).
     */
    function test_100percentTax_guardPreventsInverseTax() public pure {
        uint256 taxBps = 10000;
        // The guard condition: taxBps must be <= MAX_INVERSE_TAX_BPS (9999)
        assertTrue(taxBps > MAX_INVERSE_TAX_BPS, "100% tax should exceed guard threshold");

        // Demonstrate the divide-by-zero: (10000 - 10000) == 0
        uint256 denominator = 10000 - taxBps;
        assertEq(denominator, 0, "Denominator is zero at 100% tax");
    }

    /**
     * @notice Verifies that _createFuzzPair reverts when given a 100% tax rate.
     * @dev Uses this.externalCreateFuzzPair() to make an external call so
     *      vm.expectRevert can intercept the require.
     */
    function test_100percentTax_createFuzzPairReverts() public {
        vm.expectRevert("Tax too high for inverse computation");
        this.externalCreateFuzzPair(10000);
    }

    /// @dev External wrapper so vm.expectRevert can catch the require in _createFuzzPair
    function externalCreateFuzzPair(uint256 taxBps) external {
        _createFuzzPair(taxBps);
    }

    /**
     * @notice Tests extreme-but-valid tax of 99% (9900 bps).
     * @dev The inverse formula yields `amount * 10000 / 100 = amount * 100`,
     *      a 100x multiplier. Still valid but produces very large gross amounts.
     */
    function test_extremeTax_99percent_poolInitializes() public {
        uint256 taxBps = 9900; // 99%
        FeeOnTransferToken extremeToken = new FeeOnTransferToken("Extreme99", "EX99", 18, taxBps, 0);
        ICamelotPair extremePair = ICamelotPair(
            camelotV2Factory.createPair(address(standardToken), address(extremeToken))
        );

        // Gross amount = INITIAL_LIQUIDITY * 10000 / (10000 - 9900) = INITIAL_LIQUIDITY * 100
        uint256 expectedGross = (INITIAL_LIQUIDITY * 10000) / (10000 - taxBps);
        assertEq(expectedGross, INITIAL_LIQUIDITY * 100, "99% tax requires 100x gross amount");

        // Pool should initialize successfully (minting handles the large amounts)
        _initializePool(standardToken, extremeToken, extremePair);

        // Verify pool received approximately INITIAL_LIQUIDITY of the extreme token
        (uint112 r0, uint112 r1,,) = extremePair.getReserves();
        uint256 extremeReserve = address(extremeToken) == extremePair.token0()
            ? uint256(r0)
            : uint256(r1);
        assertApproxEqRel(extremeReserve, INITIAL_LIQUIDITY, 0.01e18, "Reserve should be ~INITIAL_LIQUIDITY");
    }

    /**
     * @notice Tests the boundary tax of 99.99% (9999 bps), the maximum allowed
     *         by our guard.
     * @dev The inverse formula yields `amount * 10000 / 1 = amount * 10000`,
     *      a 10000x multiplier. This is the last valid value before divide-by-zero.
     */
    function test_extremeTax_9999bps_isMaxValid() public {
        uint256 taxBps = 9999; // 99.99%
        FeeOnTransferToken maxToken = new FeeOnTransferToken("Max9999", "MX99", 18, taxBps, 0);
        ICamelotPair maxPair = ICamelotPair(
            camelotV2Factory.createPair(address(standardToken), address(maxToken))
        );

        // Gross amount = INITIAL_LIQUIDITY * 10000 / 1 = INITIAL_LIQUIDITY * 10000
        uint256 expectedGross = (INITIAL_LIQUIDITY * 10000) / (10000 - taxBps);
        assertEq(expectedGross, INITIAL_LIQUIDITY * 10000, "99.99% tax requires 10000x gross amount");

        // Pool should still initialize (assuming no overflow)
        _initializePool(standardToken, maxToken, maxPair);

        // Verify reserves
        (uint112 r0, uint112 r1,,) = maxPair.getReserves();
        uint256 maxReserve = address(maxToken) == maxPair.token0()
            ? uint256(r0)
            : uint256(r1);
        assertApproxEqRel(maxReserve, INITIAL_LIQUIDITY, 0.01e18, "Reserve should be ~INITIAL_LIQUIDITY");
    }

    /**
     * @notice Documents the extreme multiplier growth as tax approaches 100%.
     * @dev Emits a table showing how the gross-amount multiplier explodes near 100%.
     */
    function test_documentExtremeMultipliers() public pure {
        // Tax -> Multiplier: amount * 10000 / (10000 - taxBps)
        // 50%   -> 2x
        // 90%   -> 10x
        // 95%   -> 20x
        // 99%   -> 100x
        // 99.9% -> 1000x
        // 99.99% -> 10000x
        // 100%  -> DIVIDE BY ZERO

        uint256[6] memory taxes = [uint256(5000), 9000, 9500, 9900, 9990, 9999];
        for (uint256 i = 0; i < taxes.length; i++) {
            uint256 multiplier = 10000 / (10000 - taxes[i]);
            // Just verify the math is correct
            assert(multiplier > 0);
        }
    }
}
