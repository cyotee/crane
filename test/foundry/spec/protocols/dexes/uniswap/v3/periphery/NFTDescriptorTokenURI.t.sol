// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {NFTDescriptor} from "@crane/contracts/protocols/dexes/uniswap/v3/periphery/libraries/NFTDescriptor.sol";
import {Base64 as SoladyBase64} from "@crane/contracts/utils/Base64.sol";

/// @title NFT Descriptor TokenURI Shape Test
/// @notice Validates that tokenURI() returns correctly structured metadata
/// @dev Tests the NFT metadata structure refactored in CRANE-183
/// @dev Uses direct library calls to isolate tokenURI shape validation from pool infrastructure
contract NFTDescriptorTokenURITest is Test {
    /* -------------------------------------------------------------------------- */
    /*                              Constants                                     */
    /* -------------------------------------------------------------------------- */

    string internal constant JSON_PREFIX = "data:application/json;base64,";
    string internal constant SVG_IMAGE_PREFIX = "data:image/svg+xml;base64,";

    /* -------------------------------------------------------------------------- */
    /*                            Shape Validation Tests                          */
    /* -------------------------------------------------------------------------- */

    /// @notice Test that tokenURI returns the correct data URI prefix using direct library call
    function test_tokenURI_hasCorrectJsonPrefix() public pure {
        // Create controlled test parameters that are known to work
        NFTDescriptor.ConstructTokenURIParams memory params = _createTestParams();

        string memory uri = NFTDescriptor.constructTokenURI(params);

        // Verify JSON data URI prefix
        assertTrue(
            _startsWith(uri, JSON_PREFIX),
            "tokenURI must start with data:application/json;base64,"
        );
    }

    /// @notice Test that decoded JSON contains the image field with correct prefix
    function test_tokenURI_decodedJson_hasImageWithSvgPrefix() public pure {
        NFTDescriptor.ConstructTokenURIParams memory params = _createTestParams();
        string memory uri = NFTDescriptor.constructTokenURI(params);

        // Strip the JSON prefix and decode base64
        string memory base64Json = _substring(uri, bytes(JSON_PREFIX).length, bytes(uri).length);
        bytes memory jsonBytes = SoladyBase64.decode(base64Json);
        string memory json = string(jsonBytes);

        // Verify JSON contains image field with SVG data URI prefix
        assertTrue(
            _contains(json, SVG_IMAGE_PREFIX),
            "JSON must contain image field with data:image/svg+xml;base64, prefix"
        );
    }

    /// @notice Test that the decoded SVG has correct start and end tags
    function test_tokenURI_decodedSvg_hasCorrectTags() public pure {
        NFTDescriptor.ConstructTokenURIParams memory params = _createTestParams();
        string memory uri = NFTDescriptor.constructTokenURI(params);

        // Decode the JSON
        string memory base64Json = _substring(uri, bytes(JSON_PREFIX).length, bytes(uri).length);
        bytes memory jsonBytes = SoladyBase64.decode(base64Json);
        string memory json = string(jsonBytes);

        // Extract the base64 SVG from the image field
        string memory base64Svg = _extractBase64Svg(json);
        bytes memory svgBytes = SoladyBase64.decode(base64Svg);

        // Verify SVG starts with <svg
        assertTrue(
            _startsWith(string(svgBytes), "<svg"),
            "SVG must start with <svg"
        );

        // Verify SVG ends with </svg>
        assertTrue(
            _endsWith(string(svgBytes), "</svg>"),
            "SVG must end with </svg>"
        );
    }

    /// @notice Comprehensive shape validation test combining all checks
    function test_tokenURI_fullShapeValidation() public pure {
        NFTDescriptor.ConstructTokenURIParams memory params = _createTestParams();
        string memory uri = NFTDescriptor.constructTokenURI(params);

        // 1. Verify JSON prefix
        assertTrue(
            _startsWith(uri, JSON_PREFIX),
            "Step 1: URI must have JSON data prefix"
        );

        // 2. Decode JSON and verify structure
        string memory base64Json = _substring(uri, bytes(JSON_PREFIX).length, bytes(uri).length);
        bytes memory jsonBytes = SoladyBase64.decode(base64Json);
        string memory json = string(jsonBytes);

        // 3. Verify required JSON fields exist
        assertTrue(_contains(json, '"name"'), "JSON must contain name field");
        assertTrue(_contains(json, '"description"'), "JSON must contain description field");
        assertTrue(_contains(json, '"image"'), "JSON must contain image field");

        // 4. Verify image field has SVG prefix
        assertTrue(
            _contains(json, SVG_IMAGE_PREFIX),
            "Step 4: Image must have SVG data prefix"
        );

        // 5. Extract and decode SVG
        string memory base64Svg = _extractBase64Svg(json);
        bytes memory svgBytes = SoladyBase64.decode(base64Svg);
        string memory svg = string(svgBytes);

        // 6. Verify SVG tags
        assertTrue(_startsWith(svg, "<svg"), "Step 6a: SVG must start with <svg");
        assertTrue(_endsWith(svg, "</svg>"), "Step 6b: SVG must end with </svg>");
    }

    /* -------------------------------------------------------------------------- */
    /*                            Test Data Factory                               */
    /* -------------------------------------------------------------------------- */

    /// @dev Create test parameters with values known to work
    /// @notice Uses tick values that produce valid price strings
    function _createTestParams() internal pure returns (NFTDescriptor.ConstructTokenURIParams memory) {
        return NFTDescriptor.ConstructTokenURIParams({
            tokenId: 1,
            quoteTokenAddress: address(0x6B175474E89094C44Da98b954EedeAC495271d0F), // DAI
            baseTokenAddress: address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2),  // WETH
            quoteTokenSymbol: "DAI",
            baseTokenSymbol: "WETH",
            quoteTokenDecimals: 18,
            baseTokenDecimals: 18,
            flipRatio: false,
            tickLower: -887220,  // Near min tick but valid
            tickUpper: 887220,   // Near max tick but valid
            tickCurrent: 0,      // 1:1 price
            tickSpacing: 60,     // Standard for 0.3% fee tier
            fee: 3000,           // 0.3%
            poolAddress: address(0x1234567890123456789012345678901234567890)
        });
    }

    /* -------------------------------------------------------------------------- */
    /*                            Helper Functions                                */
    /* -------------------------------------------------------------------------- */

    /// @dev Check if a string starts with a prefix
    function _startsWith(string memory str, string memory prefix) internal pure returns (bool) {
        bytes memory strBytes = bytes(str);
        bytes memory prefixBytes = bytes(prefix);

        if (strBytes.length < prefixBytes.length) return false;

        for (uint256 i = 0; i < prefixBytes.length; i++) {
            if (strBytes[i] != prefixBytes[i]) return false;
        }
        return true;
    }

    /// @dev Check if a string ends with a suffix
    function _endsWith(string memory str, string memory suffix) internal pure returns (bool) {
        bytes memory strBytes = bytes(str);
        bytes memory suffixBytes = bytes(suffix);

        if (strBytes.length < suffixBytes.length) return false;

        uint256 offset = strBytes.length - suffixBytes.length;
        for (uint256 i = 0; i < suffixBytes.length; i++) {
            if (strBytes[offset + i] != suffixBytes[i]) return false;
        }
        return true;
    }

    /// @dev Check if a string contains a substring
    function _contains(string memory str, string memory substr) internal pure returns (bool) {
        bytes memory strBytes = bytes(str);
        bytes memory substrBytes = bytes(substr);

        if (substrBytes.length > strBytes.length) return false;
        if (substrBytes.length == 0) return true;

        for (uint256 i = 0; i <= strBytes.length - substrBytes.length; i++) {
            bool found = true;
            for (uint256 j = 0; j < substrBytes.length; j++) {
                if (strBytes[i + j] != substrBytes[j]) {
                    found = false;
                    break;
                }
            }
            if (found) return true;
        }
        return false;
    }

    /// @dev Extract a substring from start to end index
    function _substring(string memory str, uint256 start, uint256 end) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        require(end >= start && end <= strBytes.length, "Invalid substring range");

        bytes memory result = new bytes(end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = strBytes[i];
        }
        return string(result);
    }

    /// @dev Extract base64 SVG from JSON image field
    /// @notice Finds "data:image/svg+xml;base64," and extracts until closing quote
    function _extractBase64Svg(string memory json) internal pure returns (string memory) {
        bytes memory jsonBytes = bytes(json);
        bytes memory prefixBytes = bytes(SVG_IMAGE_PREFIX);

        // Find the SVG prefix
        uint256 prefixStart = 0;
        bool found = false;

        for (uint256 i = 0; i <= jsonBytes.length - prefixBytes.length; i++) {
            bool match_ = true;
            for (uint256 j = 0; j < prefixBytes.length; j++) {
                if (jsonBytes[i + j] != prefixBytes[j]) {
                    match_ = false;
                    break;
                }
            }
            if (match_) {
                prefixStart = i;
                found = true;
                break;
            }
        }

        require(found, "SVG prefix not found in JSON");

        // Start of base64 content (after the prefix)
        uint256 base64Start = prefixStart + prefixBytes.length;

        // Find the closing quote
        uint256 base64End = base64Start;
        for (uint256 i = base64Start; i < jsonBytes.length; i++) {
            if (jsonBytes[i] == '"') {
                base64End = i;
                break;
            }
        }

        require(base64End > base64Start, "Could not find end of base64 SVG");

        // Extract the base64 string
        bytes memory result = new bytes(base64End - base64Start);
        for (uint256 i = base64Start; i < base64End; i++) {
            result[i - base64Start] = jsonBytes[i];
        }

        return string(result);
    }
}
