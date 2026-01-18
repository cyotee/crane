// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TokenConfig, TokenType} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import {IRateProvider} from "@balancer-labs/v3-interfaces/contracts/solidity-utils/helpers/IRateProvider.sol";

import {TokenConfigUtils} from "@crane/contracts/protocols/dexes/balancer/v3/utils/TokenConfigUtils.sol";

/**
 * @title TokenConfigUtils_Test
 * @notice Comprehensive tests for TokenConfigUtils sorting functionality.
 * @dev Tests verify sorting correctness, struct field alignment preservation,
 *      and edge cases with 2, 3, and 4 token configurations.
 *
 * NOTE: A previous bug in _sort() only swapped the `token` field, not the full
 * TokenConfig struct. This was fixed in commit 0acfd35. These tests verify that
 * all struct fields (token, tokenType, rateProvider, paysYieldFees) remain
 * correctly aligned after sorting.
 */
contract TokenConfigUtils_Test is Test {
    using TokenConfigUtils for TokenConfig[];

    // Mock addresses for testing
    address internal constant TOKEN_A = address(0xA);
    address internal constant TOKEN_B = address(0xB);
    address internal constant TOKEN_C = address(0xC);
    address internal constant TOKEN_D = address(0xD);

    address internal constant RATE_PROVIDER_A = address(0xAA);
    address internal constant RATE_PROVIDER_B = address(0xBB);
    address internal constant RATE_PROVIDER_C = address(0xCC);
    address internal constant RATE_PROVIDER_D = address(0xDD);

    /* ---------------------------------------------------------------------- */
    /*                       2-Token Sorting Tests                            */
    /* ---------------------------------------------------------------------- */

    function test_sort_twoTokens_alreadySorted() public pure {
        TokenConfig[] memory configs = new TokenConfig[](2);
        configs[0] = TokenConfig({
            token: IERC20(TOKEN_A),
            tokenType: TokenType.STANDARD,
            rateProvider: IRateProvider(RATE_PROVIDER_A),
            paysYieldFees: false
        });
        configs[1] = TokenConfig({
            token: IERC20(TOKEN_B),
            tokenType: TokenType.WITH_RATE,
            rateProvider: IRateProvider(RATE_PROVIDER_B),
            paysYieldFees: true
        });

        TokenConfig[] memory sorted = configs._sort();

        // Should remain in same order (A < B)
        assertEq(address(sorted[0].token), TOKEN_A, "First token should be A");
        assertEq(address(sorted[1].token), TOKEN_B, "Second token should be B");
    }

    function test_sort_twoTokens_needsSwap() public pure {
        TokenConfig[] memory configs = new TokenConfig[](2);
        configs[0] = TokenConfig({
            token: IERC20(TOKEN_B),
            tokenType: TokenType.WITH_RATE,
            rateProvider: IRateProvider(RATE_PROVIDER_B),
            paysYieldFees: true
        });
        configs[1] = TokenConfig({
            token: IERC20(TOKEN_A),
            tokenType: TokenType.STANDARD,
            rateProvider: IRateProvider(RATE_PROVIDER_A),
            paysYieldFees: false
        });

        TokenConfig[] memory sorted = configs._sort();

        // Tokens should be swapped (A < B)
        assertEq(address(sorted[0].token), TOKEN_A, "First token should be A after sort");
        assertEq(address(sorted[1].token), TOKEN_B, "Second token should be B after sort");
    }

    function test_sort_twoTokens_preservesFieldAlignment() public pure {
        TokenConfig[] memory configs = new TokenConfig[](2);
        // B is first (will be swapped to second position)
        configs[0] = TokenConfig({
            token: IERC20(TOKEN_B),
            tokenType: TokenType.WITH_RATE,
            rateProvider: IRateProvider(RATE_PROVIDER_B),
            paysYieldFees: true
        });
        // A is second (will be swapped to first position)
        configs[1] = TokenConfig({
            token: IERC20(TOKEN_A),
            tokenType: TokenType.STANDARD,
            rateProvider: IRateProvider(RATE_PROVIDER_A),
            paysYieldFees: false
        });

        TokenConfig[] memory sorted = configs._sort();

        _assertConfigMatches(sorted[0], TOKEN_A, TokenType.STANDARD, RATE_PROVIDER_A, false);
        _assertConfigMatches(sorted[1], TOKEN_B, TokenType.WITH_RATE, RATE_PROVIDER_B, true);
    }

    /* ---------------------------------------------------------------------- */
    /*                       3-Token Sorting Tests                            */
    /* ---------------------------------------------------------------------- */

    function test_sort_threeTokens_alreadySorted() public pure {
        TokenConfig[] memory configs = new TokenConfig[](3);
        configs[0] = _createConfig(TOKEN_A, TokenType.STANDARD, RATE_PROVIDER_A, false);
        configs[1] = _createConfig(TOKEN_B, TokenType.WITH_RATE, RATE_PROVIDER_B, true);
        configs[2] = _createConfig(TOKEN_C, TokenType.STANDARD, RATE_PROVIDER_C, false);

        TokenConfig[] memory sorted = configs._sort();

        assertEq(address(sorted[0].token), TOKEN_A, "First should be A");
        assertEq(address(sorted[1].token), TOKEN_B, "Second should be B");
        assertEq(address(sorted[2].token), TOKEN_C, "Third should be C");
    }

    function test_sort_threeTokens_reverseOrder() public pure {
        TokenConfig[] memory configs = new TokenConfig[](3);
        configs[0] = _createConfig(TOKEN_C, TokenType.STANDARD, RATE_PROVIDER_C, false);
        configs[1] = _createConfig(TOKEN_B, TokenType.WITH_RATE, RATE_PROVIDER_B, true);
        configs[2] = _createConfig(TOKEN_A, TokenType.STANDARD, RATE_PROVIDER_A, false);

        TokenConfig[] memory sorted = configs._sort();

        assertEq(address(sorted[0].token), TOKEN_A, "First should be A");
        assertEq(address(sorted[1].token), TOKEN_B, "Second should be B");
        assertEq(address(sorted[2].token), TOKEN_C, "Third should be C");
    }

    function test_sort_threeTokens_partiallyOrdered() public pure {
        // Order: B, A, C -> should become A, B, C
        TokenConfig[] memory configs = new TokenConfig[](3);
        configs[0] = _createConfig(TOKEN_B, TokenType.WITH_RATE, RATE_PROVIDER_B, true);
        configs[1] = _createConfig(TOKEN_A, TokenType.STANDARD, RATE_PROVIDER_A, false);
        configs[2] = _createConfig(TOKEN_C, TokenType.STANDARD, RATE_PROVIDER_C, false);

        TokenConfig[] memory sorted = configs._sort();

        assertEq(address(sorted[0].token), TOKEN_A, "First should be A");
        assertEq(address(sorted[1].token), TOKEN_B, "Second should be B");
        assertEq(address(sorted[2].token), TOKEN_C, "Third should be C");
    }

    function test_sort_threeTokens_preservesFieldAlignment() public pure {
        TokenConfig[] memory configs = new TokenConfig[](3);
        // Original order: C, B, A (indices 0, 1, 2)
        configs[0] = _createConfig(TOKEN_C, TokenType.STANDARD, RATE_PROVIDER_C, false);
        configs[1] = _createConfig(TOKEN_B, TokenType.WITH_RATE, RATE_PROVIDER_B, true);
        configs[2] = _createConfig(TOKEN_A, TokenType.STANDARD, RATE_PROVIDER_A, true);

        TokenConfig[] memory sorted = configs._sort();

        _assertConfigMatches(sorted[0], TOKEN_A, TokenType.STANDARD, RATE_PROVIDER_A, true);
        _assertConfigMatches(sorted[1], TOKEN_B, TokenType.WITH_RATE, RATE_PROVIDER_B, true);
        _assertConfigMatches(sorted[2], TOKEN_C, TokenType.STANDARD, RATE_PROVIDER_C, false);
    }

    /* ---------------------------------------------------------------------- */
    /*                       4-Token Sorting Tests                            */
    /* ---------------------------------------------------------------------- */

    function test_sort_fourTokens_alreadySorted() public pure {
        TokenConfig[] memory configs = new TokenConfig[](4);
        configs[0] = _createConfig(TOKEN_A, TokenType.STANDARD, RATE_PROVIDER_A, false);
        configs[1] = _createConfig(TOKEN_B, TokenType.WITH_RATE, RATE_PROVIDER_B, true);
        configs[2] = _createConfig(TOKEN_C, TokenType.STANDARD, RATE_PROVIDER_C, false);
        configs[3] = _createConfig(TOKEN_D, TokenType.WITH_RATE, RATE_PROVIDER_D, true);

        TokenConfig[] memory sorted = configs._sort();

        assertEq(address(sorted[0].token), TOKEN_A);
        assertEq(address(sorted[1].token), TOKEN_B);
        assertEq(address(sorted[2].token), TOKEN_C);
        assertEq(address(sorted[3].token), TOKEN_D);
    }

    function test_sort_fourTokens_reverseOrder() public pure {
        TokenConfig[] memory configs = new TokenConfig[](4);
        configs[0] = _createConfig(TOKEN_D, TokenType.WITH_RATE, RATE_PROVIDER_D, true);
        configs[1] = _createConfig(TOKEN_C, TokenType.STANDARD, RATE_PROVIDER_C, false);
        configs[2] = _createConfig(TOKEN_B, TokenType.WITH_RATE, RATE_PROVIDER_B, true);
        configs[3] = _createConfig(TOKEN_A, TokenType.STANDARD, RATE_PROVIDER_A, false);

        TokenConfig[] memory sorted = configs._sort();

        assertEq(address(sorted[0].token), TOKEN_A);
        assertEq(address(sorted[1].token), TOKEN_B);
        assertEq(address(sorted[2].token), TOKEN_C);
        assertEq(address(sorted[3].token), TOKEN_D);
    }

    function test_sort_fourTokens_randomOrder() public pure {
        // Order: C, A, D, B -> should become A, B, C, D
        TokenConfig[] memory configs = new TokenConfig[](4);
        configs[0] = _createConfig(TOKEN_C, TokenType.STANDARD, RATE_PROVIDER_C, false);
        configs[1] = _createConfig(TOKEN_A, TokenType.STANDARD, RATE_PROVIDER_A, false);
        configs[2] = _createConfig(TOKEN_D, TokenType.WITH_RATE, RATE_PROVIDER_D, true);
        configs[3] = _createConfig(TOKEN_B, TokenType.WITH_RATE, RATE_PROVIDER_B, true);

        TokenConfig[] memory sorted = configs._sort();

        assertEq(address(sorted[0].token), TOKEN_A);
        assertEq(address(sorted[1].token), TOKEN_B);
        assertEq(address(sorted[2].token), TOKEN_C);
        assertEq(address(sorted[3].token), TOKEN_D);
    }

    function test_sort_fourTokens_preservesFieldAlignment() public pure {
        TokenConfig[] memory configs = new TokenConfig[](4);
        // Original order: D, B, C, A (indices 0, 1, 2, 3)
        configs[0] = _createConfig(TOKEN_D, TokenType.WITH_RATE, RATE_PROVIDER_D, true);
        configs[1] = _createConfig(TOKEN_B, TokenType.WITH_RATE, RATE_PROVIDER_B, false);
        configs[2] = _createConfig(TOKEN_C, TokenType.STANDARD, RATE_PROVIDER_C, true);
        configs[3] = _createConfig(TOKEN_A, TokenType.STANDARD, RATE_PROVIDER_A, false);

        TokenConfig[] memory sorted = configs._sort();

        _assertConfigMatches(sorted[0], TOKEN_A, TokenType.STANDARD, RATE_PROVIDER_A, false);
        _assertConfigMatches(sorted[1], TOKEN_B, TokenType.WITH_RATE, RATE_PROVIDER_B, false);
        _assertConfigMatches(sorted[2], TOKEN_C, TokenType.STANDARD, RATE_PROVIDER_C, true);
        _assertConfigMatches(sorted[3], TOKEN_D, TokenType.WITH_RATE, RATE_PROVIDER_D, true);
    }

    /* ---------------------------------------------------------------------- */
    /*                       Edge Case Tests                                  */
    /* ---------------------------------------------------------------------- */

    function test_sort_singleToken_noChange() public pure {
        TokenConfig[] memory configs = new TokenConfig[](1);
        configs[0] = _createConfig(TOKEN_A, TokenType.STANDARD, RATE_PROVIDER_A, false);

        TokenConfig[] memory sorted = configs._sort();

        assertEq(sorted.length, 1, "Length should be 1");
        assertEq(address(sorted[0].token), TOKEN_A, "Token should be unchanged");
    }

    function test_sort_emptyArray_noRevert() public pure {
        TokenConfig[] memory configs = new TokenConfig[](0);
        TokenConfig[] memory sorted = configs._sort();
        assertEq(sorted.length, 0, "Empty array should remain empty");
    }

    function test_sort_idempotent_sortingTwice() public pure {
        TokenConfig[] memory configs = new TokenConfig[](3);
        configs[0] = _createConfig(TOKEN_C, TokenType.STANDARD, RATE_PROVIDER_C, false);
        configs[1] = _createConfig(TOKEN_A, TokenType.STANDARD, RATE_PROVIDER_A, true);
        configs[2] = _createConfig(TOKEN_B, TokenType.WITH_RATE, RATE_PROVIDER_B, false);

        TokenConfig[] memory sorted1 = configs._sort();
        TokenConfig[] memory sorted2 = sorted1._sort();

        // Sorting twice should produce same result
        for (uint256 i = 0; i < sorted1.length; i++) {
            assertEq(address(sorted1[i].token), address(sorted2[i].token), "Tokens should match after double sort");
        }
    }

    function test_sort_sameAddresses_noSwap() public pure {
        // All tokens have same address (edge case)
        TokenConfig[] memory configs = new TokenConfig[](2);
        configs[0] = _createConfig(TOKEN_A, TokenType.STANDARD, RATE_PROVIDER_A, false);
        configs[1] = _createConfig(TOKEN_A, TokenType.WITH_RATE, RATE_PROVIDER_B, true);

        TokenConfig[] memory sorted = configs._sort();

        // With same addresses, no swap should occur
        assertEq(address(sorted[0].token), TOKEN_A);
        assertEq(address(sorted[1].token), TOKEN_A);
    }

    /* ---------------------------------------------------------------------- */
    /*                       Fuzz Tests                                       */
    /* ---------------------------------------------------------------------- */

    function testFuzz_sort_twoTokens_alwaysSorted(address tokenA, address tokenB) public pure {
        vm.assume(tokenA != address(0) && tokenB != address(0));
        vm.assume(tokenA != tokenB);

        TokenConfig[] memory configs = new TokenConfig[](2);
        configs[0] = _createConfig(tokenA, TokenType.STANDARD, address(0), false);
        configs[1] = _createConfig(tokenB, TokenType.STANDARD, address(0), false);

        TokenConfig[] memory sorted = configs._sort();

        // First token should have lower address
        assertTrue(
            address(sorted[0].token) < address(sorted[1].token),
            "Tokens should be sorted by address"
        );
    }

    function testFuzz_sort_threeTokens_alwaysSorted(address tokenA, address tokenB, address tokenC) public pure {
        vm.assume(tokenA != address(0) && tokenB != address(0) && tokenC != address(0));
        vm.assume(tokenA != tokenB && tokenB != tokenC && tokenA != tokenC);

        TokenConfig[] memory configs = new TokenConfig[](3);
        configs[0] = _createConfig(tokenA, TokenType.STANDARD, address(0), false);
        configs[1] = _createConfig(tokenB, TokenType.STANDARD, address(0), false);
        configs[2] = _createConfig(tokenC, TokenType.STANDARD, address(0), false);

        TokenConfig[] memory sorted = configs._sort();

        // Verify ascending order
        assertTrue(address(sorted[0].token) < address(sorted[1].token), "0 < 1");
        assertTrue(address(sorted[1].token) < address(sorted[2].token), "1 < 2");
    }

    function testFuzz_sort_fourTokens_alwaysSorted(
        address tokenA,
        address tokenB,
        address tokenC,
        address tokenD
    ) public pure {
        vm.assume(tokenA != address(0) && tokenB != address(0));
        vm.assume(tokenC != address(0) && tokenD != address(0));
        vm.assume(tokenA != tokenB && tokenA != tokenC && tokenA != tokenD);
        vm.assume(tokenB != tokenC && tokenB != tokenD);
        vm.assume(tokenC != tokenD);

        TokenConfig[] memory configs = new TokenConfig[](4);
        configs[0] = _createConfig(tokenA, TokenType.STANDARD, address(0), false);
        configs[1] = _createConfig(tokenB, TokenType.STANDARD, address(0), false);
        configs[2] = _createConfig(tokenC, TokenType.STANDARD, address(0), false);
        configs[3] = _createConfig(tokenD, TokenType.STANDARD, address(0), false);

        TokenConfig[] memory sorted = configs._sort();

        // Verify ascending order
        assertTrue(address(sorted[0].token) < address(sorted[1].token), "0 < 1");
        assertTrue(address(sorted[1].token) < address(sorted[2].token), "1 < 2");
        assertTrue(address(sorted[2].token) < address(sorted[3].token), "2 < 3");
    }

    function testFuzz_sort_preservesLength(uint8 length) public pure {
        length = uint8(bound(length, 0, 4)); // Max 4 tokens for Balancer pools

        TokenConfig[] memory configs = new TokenConfig[](length);
        for (uint256 i = 0; i < length; i++) {
            configs[i] = _createConfig(
                address(uint160(i + 1) * 0x1111), // Different addresses
                TokenType.STANDARD,
                address(0),
                false
            );
        }

        TokenConfig[] memory sorted = configs._sort();

        assertEq(sorted.length, length, "Length should be preserved");
    }

    /**
     * @notice Fuzz test that verifies field alignment is preserved after sorting.
     * @dev Assigns distinct per-token metadata derived deterministically from the token address,
     *      then asserts that after sorting, each token still maps to its original metadata.
     *      This directly guards against regressions of the "swap only token address" bug class.
     */
    function testFuzz_sort_preservesFieldAlignment_twoTokens(
        address tokenA,
        address tokenB
    ) public pure {
        vm.assume(tokenA != address(0) && tokenB != address(0));
        vm.assume(tokenA != tokenB);

        // Generate distinct metadata from token addresses
        TokenConfig[] memory configs = new TokenConfig[](2);
        configs[0] = _createConfigWithDerivedMetadata(tokenA);
        configs[1] = _createConfigWithDerivedMetadata(tokenB);

        TokenConfig[] memory sorted = configs._sort();

        // Verify each token still has its original metadata
        for (uint256 i = 0; i < sorted.length; i++) {
            _assertConfigHasDerivedMetadata(sorted[i]);
        }
    }

    /**
     * @notice Fuzz test for 3-token field alignment preservation.
     */
    function testFuzz_sort_preservesFieldAlignment_threeTokens(
        address tokenA,
        address tokenB,
        address tokenC
    ) public pure {
        vm.assume(tokenA != address(0) && tokenB != address(0) && tokenC != address(0));
        vm.assume(tokenA != tokenB && tokenB != tokenC && tokenA != tokenC);

        TokenConfig[] memory configs = new TokenConfig[](3);
        configs[0] = _createConfigWithDerivedMetadata(tokenA);
        configs[1] = _createConfigWithDerivedMetadata(tokenB);
        configs[2] = _createConfigWithDerivedMetadata(tokenC);

        TokenConfig[] memory sorted = configs._sort();

        for (uint256 i = 0; i < sorted.length; i++) {
            _assertConfigHasDerivedMetadata(sorted[i]);
        }
    }

    /**
     * @notice Fuzz test for 4-token field alignment preservation.
     */
    function testFuzz_sort_preservesFieldAlignment_fourTokens(
        address tokenA,
        address tokenB,
        address tokenC,
        address tokenD
    ) public pure {
        vm.assume(tokenA != address(0) && tokenB != address(0));
        vm.assume(tokenC != address(0) && tokenD != address(0));
        vm.assume(tokenA != tokenB && tokenA != tokenC && tokenA != tokenD);
        vm.assume(tokenB != tokenC && tokenB != tokenD);
        vm.assume(tokenC != tokenD);

        TokenConfig[] memory configs = new TokenConfig[](4);
        configs[0] = _createConfigWithDerivedMetadata(tokenA);
        configs[1] = _createConfigWithDerivedMetadata(tokenB);
        configs[2] = _createConfigWithDerivedMetadata(tokenC);
        configs[3] = _createConfigWithDerivedMetadata(tokenD);

        TokenConfig[] memory sorted = configs._sort();

        for (uint256 i = 0; i < sorted.length; i++) {
            _assertConfigHasDerivedMetadata(sorted[i]);
        }
    }

    /* ---------------------------------------------------------------------- */
    /*                       Helper Functions                                  */
    /* ---------------------------------------------------------------------- */

    /**
     * @notice Creates a TokenConfig with metadata deterministically derived from the token address.
     * @dev Uses XOR to derive rateProvider and bit extraction for tokenType and paysYieldFees.
     *      This ensures each token has unique, predictable metadata that can be verified after sorting.
     */
    function _createConfigWithDerivedMetadata(address token) internal pure returns (TokenConfig memory) {
        uint160 tokenVal = uint160(token);
        // Derive rateProvider by XOR with a constant
        address rateProvider = address(tokenVal ^ 0x1234);
        // Derive tokenType from bit 0: 0 = STANDARD, 1 = WITH_RATE
        TokenType tokenType = (tokenVal & 1 == 0) ? TokenType.STANDARD : TokenType.WITH_RATE;
        // Derive paysYieldFees from bit 1
        bool paysYieldFees = (tokenVal & 2) != 0;

        return TokenConfig({
            token: IERC20(token),
            tokenType: tokenType,
            rateProvider: IRateProvider(rateProvider),
            paysYieldFees: paysYieldFees
        });
    }

    /**
     * @notice Asserts that a TokenConfig has metadata correctly derived from its token address.
     * @dev Recomputes expected metadata from the token address and compares against actual values.
     */
    function _assertConfigHasDerivedMetadata(TokenConfig memory config) internal pure {
        address token = address(config.token);
        uint160 tokenVal = uint160(token);

        // Recompute expected values
        address expectedRateProvider = address(tokenVal ^ 0x1234);
        TokenType expectedTokenType = (tokenVal & 1 == 0) ? TokenType.STANDARD : TokenType.WITH_RATE;
        bool expectedPaysYieldFees = (tokenVal & 2) != 0;

        // Assert alignment
        assertEq(
            address(config.rateProvider),
            expectedRateProvider,
            string.concat("rateProvider mismatch for token ", vm.toString(token))
        );
        assertTrue(
            config.tokenType == expectedTokenType,
            string.concat("tokenType mismatch for token ", vm.toString(token))
        );
        assertEq(
            config.paysYieldFees,
            expectedPaysYieldFees,
            string.concat("paysYieldFees mismatch for token ", vm.toString(token))
        );
    }

    function _createConfig(
        address token,
        TokenType tokenType,
        address rateProvider,
        bool paysYieldFees
    ) internal pure returns (TokenConfig memory) {
        return TokenConfig({
            token: IERC20(token),
            tokenType: tokenType,
            rateProvider: IRateProvider(rateProvider),
            paysYieldFees: paysYieldFees
        });
    }

    function _assertConfigMatches(
        TokenConfig memory config,
        address expectedToken,
        TokenType expectedType,
        address expectedRateProvider,
        bool expectedPaysYieldFees
    ) internal pure {
        assertEq(address(config.token), expectedToken, "Token mismatch");
        assertTrue(config.tokenType == expectedType, "TokenType mismatch");
        assertEq(address(config.rateProvider), expectedRateProvider, "RateProvider mismatch");
        assertEq(config.paysYieldFees, expectedPaysYieldFees, "paysYieldFees mismatch");
    }
}
