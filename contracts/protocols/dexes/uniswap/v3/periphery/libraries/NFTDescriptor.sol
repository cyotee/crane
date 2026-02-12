// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../../interfaces/IUniswapV3Pool.sol";
import "../../libraries/TickMath.sol";
import "../../libraries/BitMath.sol";
import "../../libraries/FullMath.sol";
import {Strings} from "@crane/contracts/utils/Strings.sol";
import {Base64} from "@crane/contracts/utils/Base64.sol";
import "./HexStrings.sol";
import "./NFTSVG.sol";

library NFTDescriptor {
    using Strings for uint256;
    using HexStrings for uint256;

    uint256 constant sqrt10X128 = 1076067327063303206878105757264492625226;

    struct ConstructTokenURIParams {
        uint256 tokenId;
        address quoteTokenAddress;
        address baseTokenAddress;
        string quoteTokenSymbol;
        string baseTokenSymbol;
        uint8 quoteTokenDecimals;
        uint8 baseTokenDecimals;
        bool flipRatio;
        int24 tickLower;
        int24 tickUpper;
        int24 tickCurrent;
        int24 tickSpacing;
        uint24 fee;
        address poolAddress;
    }

    function constructTokenURI(ConstructTokenURIParams memory params) public pure returns (string memory) {
        // Pre-compute strings in blocks to limit stack depth
        string memory name;
        string memory descPartOne;
        string memory descPartTwo;
        {
            string memory feeTier = feeToPercentString(params.fee);
            name = generateName(params, feeTier);
            descPartOne = generateDescriptionPartOne(
                escapeQuotes(params.quoteTokenSymbol),
                escapeQuotes(params.baseTokenSymbol),
                addressToString(params.poolAddress)
            );
            descPartTwo = generateDescriptionPartTwo(
                params.tokenId.toString(),
                escapeQuotes(params.baseTokenSymbol),
                addressToString(params.quoteTokenAddress),
                addressToString(params.baseTokenAddress),
                feeTier
            );
        }

        // Build JSON in stages
        bytes memory jsonContent;
        {
            bytes memory jp1 = abi.encodePacked('{"name":"', name, '", "description":"');
            bytes memory jp2 = abi.encodePacked(descPartOne, descPartTwo);
            bytes memory jp3 = abi.encodePacked('", "image": "data:image/svg+xml;base64,');
            string memory image = Base64.encode(bytes(generateSVGImage(params)));
            jsonContent = abi.encodePacked(jp1, jp2, jp3, image, '"}');
        }

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(jsonContent)
        ));
    }

    function escapeQuotes(string memory symbol) internal pure returns (string memory) {
        bytes memory symbolBytes = bytes(symbol);
        uint256 quotesCount = 0;
        for (uint256 i = 0; i < symbolBytes.length; i++) {
            if (symbolBytes[i] == '"') {
                quotesCount++;
            }
        }
        if (quotesCount > 0) {
            bytes memory escapedBytes = new bytes(symbolBytes.length + quotesCount);
            uint256 index;
            for (uint256 i = 0; i < symbolBytes.length; i++) {
                if (symbolBytes[i] == '"') {
                    escapedBytes[index++] = "\\";
                }
                escapedBytes[index++] = symbolBytes[i];
            }
            return string(escapedBytes);
        }
        return symbol;
    }

    function generateDescriptionPartOne(
        string memory quoteTokenSymbol,
        string memory baseTokenSymbol,
        string memory poolAddress
    ) private pure returns (string memory) {
        // Split into smaller abi.encodePacked calls (max 5 args each)
        bytes memory p1 = abi.encodePacked(
            "This NFT represents a liquidity position in a Uniswap V3 ",
            quoteTokenSymbol, "-", baseTokenSymbol, " pool. "
        );
        bytes memory p2 = abi.encodePacked(
            "The owner of this NFT can modify or redeem the position.\\n",
            "\\nPool Address: ", poolAddress, "\\n", quoteTokenSymbol
        );
        return string(abi.encodePacked(p1, p2));
    }

    function generateDescriptionPartTwo(
        string memory tokenId,
        string memory baseTokenSymbol,
        string memory quoteTokenAddress,
        string memory baseTokenAddress,
        string memory feeTier
    ) private pure returns (string memory) {
        // Split into smaller abi.encodePacked calls (max 5 args each)
        bytes memory p1 = abi.encodePacked(
            " Address: ", quoteTokenAddress, "\\n", baseTokenSymbol, " Address: "
        );
        bytes memory p2 = abi.encodePacked(
            baseTokenAddress, "\\nFee Tier: ", feeTier, "\\nToken ID: ", tokenId
        );
        bytes memory p3 = abi.encodePacked(
            "\\n\\n",
            unicode"⚠️ DISCLAIMER: Due diligence is imperative when assessing this NFT. Make sure token addresses match the expected tokens, as token symbols may be imitated."
        );
        return string(abi.encodePacked(p1, p2, p3));
    }

    function generateName(ConstructTokenURIParams memory params, string memory feeTier)
        private
        pure
        returns (string memory)
    {
        // Pre-compute tick strings to avoid deep function nesting
        string memory tickLowerStr = tickToDecimalString(
            !params.flipRatio ? params.tickLower : params.tickUpper,
            params.tickSpacing, params.baseTokenDecimals, params.quoteTokenDecimals, params.flipRatio
        );
        string memory tickUpperStr = tickToDecimalString(
            !params.flipRatio ? params.tickUpper : params.tickLower,
            params.tickSpacing, params.baseTokenDecimals, params.quoteTokenDecimals, params.flipRatio
        );
        // Split into smaller abi.encodePacked calls
        bytes memory p1 = abi.encodePacked(
            "Uniswap - ", feeTier, " - ", escapeQuotes(params.quoteTokenSymbol), "/"
        );
        bytes memory p2 = abi.encodePacked(
            escapeQuotes(params.baseTokenSymbol), " - ", tickLowerStr, "<>", tickUpperStr
        );
        return string(abi.encodePacked(p1, p2));
    }

    struct DecimalStringParams {
        // significant figures of decimal
        uint256 sigfigs;
        // length of decimal string
        uint8 bufferLength;
        // ending index for significant figures (funtion works backwards when copying sigfigs)
        uint8 sigfigIndex;
        // index of decimal place (0 if no decimal)
        uint8 decimalIndex;
        // start index for trailing/leading 0's for very small/large numbers
        uint8 zerosStartIndex;
        // end index for trailing/leading 0's for very small/large numbers
        uint8 zerosEndIndex;
        // true if decimal number is less than one
        bool isLessThanOne;
        // true if string should include "%"
        bool isPercent;
    }

    function generateDecimalString(DecimalStringParams memory params) private pure returns (string memory) {
        bytes memory buffer = new bytes(params.bufferLength);
        if (params.isPercent) {
            buffer[buffer.length - 1] = "%";
        }
        if (params.isLessThanOne) {
            buffer[0] = "0";
            buffer[1] = ".";
        }

        // add leading/trailing 0's
        for (uint256 zerosCursor = params.zerosStartIndex; zerosCursor < uint256(params.zerosEndIndex) + 1; zerosCursor++) {
            buffer[zerosCursor] = bytes1(uint8(48));
        }
        // add sigfigs
        while (params.sigfigs > 0) {
            if (params.decimalIndex > 0 && params.sigfigIndex == params.decimalIndex) {
                buffer[params.sigfigIndex--] = ".";
            }
            buffer[params.sigfigIndex--] = bytes1(uint8(48 + (params.sigfigs % 10)));
            params.sigfigs /= 10;
        }
        return string(buffer);
    }

    function tickToDecimalString(
        int24 tick,
        int24 tickSpacing,
        uint8 baseTokenDecimals,
        uint8 quoteTokenDecimals,
        bool flipRatio
    ) internal pure returns (string memory) {
        if (tick == (TickMath.MIN_TICK / tickSpacing) * tickSpacing) {
            return !flipRatio ? "MIN" : "MAX";
        } else if (tick == (TickMath.MAX_TICK / tickSpacing) * tickSpacing) {
            return !flipRatio ? "MAX" : "MIN";
        } else {
            uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);
            if (flipRatio) {
                sqrtRatioX96 = uint160((1 << 192) / sqrtRatioX96);
            }
            return fixedPointToDecimalString(sqrtRatioX96, baseTokenDecimals, quoteTokenDecimals);
        }
    }

    function sigfigsRounded(uint256 value, uint8 digits) private pure returns (uint256, bool) {
        bool extraDigit;
        if (digits > 5) {
            value = value / (10 ** (digits - 5));
        }
        bool roundUp = value % 10 > 4;
        value = value / 10;
        if (roundUp) {
            value = value + 1;
        }
        // 99999 -> 100000 gives an extra sigfig
        if (value == 100000) {
            value /= 10;
            extraDigit = true;
        }
        return (value, extraDigit);
    }

    function adjustForDecimalPrecision(
        uint160 sqrtRatioX96,
        uint8 baseTokenDecimals,
        uint8 quoteTokenDecimals
    ) private pure returns (uint256 adjustedSqrtRatioX96) {
        uint256 difference = abs(int256(uint256(baseTokenDecimals)) - int256(uint256(quoteTokenDecimals)));
        if (difference > 0 && difference <= 18) {
            if (baseTokenDecimals > quoteTokenDecimals) {
                adjustedSqrtRatioX96 = uint256(sqrtRatioX96) * (10 ** (difference / 2));
                if (difference % 2 == 1) {
                    adjustedSqrtRatioX96 = FullMath.mulDiv(adjustedSqrtRatioX96, sqrt10X128, 1 << 128);
                }
            } else {
                adjustedSqrtRatioX96 = uint256(sqrtRatioX96) / (10 ** (difference / 2));
                if (difference % 2 == 1) {
                    adjustedSqrtRatioX96 = FullMath.mulDiv(adjustedSqrtRatioX96, 1 << 128, sqrt10X128);
                }
            }
        } else {
            adjustedSqrtRatioX96 = uint256(sqrtRatioX96);
        }
    }

    function abs(int256 x) private pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }

    // @notice Returns string that includes first 5 significant figures of a decimal number
    // @param sqrtRatioX96 a sqrt price
    function fixedPointToDecimalString(
        uint160 sqrtRatioX96,
        uint8 baseTokenDecimals,
        uint8 quoteTokenDecimals
    ) internal pure returns (string memory) {
        uint256 adjustedSqrtRatioX96 = adjustForDecimalPrecision(sqrtRatioX96, baseTokenDecimals, quoteTokenDecimals);
        uint256 value = FullMath.mulDiv(adjustedSqrtRatioX96, adjustedSqrtRatioX96, 1 << 64);

        bool priceBelow1 = adjustedSqrtRatioX96 < 2 ** 96;
        if (priceBelow1) {
            // 10 ** 43 is precision needed to retreive 5 sigfigs of smallest possible price + 1 for rounding
            value = FullMath.mulDiv(value, 10 ** 44, 1 << 128);
        } else {
            // leave precision for 4 decimal places + 1 place for rounding
            value = FullMath.mulDiv(value, 10 ** 5, 1 << 128);
        }

        // get digit count
        uint256 temp = value;
        uint8 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        // don't count extra digit kept for rounding
        digits = digits - 1;

        // address rounding
        (uint256 sigfigs, bool extraDigit) = sigfigsRounded(value, digits);
        if (extraDigit) {
            digits++;
        }

        DecimalStringParams memory params;
        if (priceBelow1) {
            // 7 bytes ( "0." and 5 sigfigs) + leading 0's bytes
            params.bufferLength = uint8(7 + (43 - digits));
            params.zerosStartIndex = 2;
            params.zerosEndIndex = uint8(43 - digits + 1);
            params.sigfigIndex = uint8(params.bufferLength - 1);
        } else if (digits >= 9) {
            // no decimal in price string
            params.bufferLength = uint8(digits - 4);
            params.zerosStartIndex = 5;
            params.zerosEndIndex = uint8(params.bufferLength - 1);
            params.sigfigIndex = 4;
        } else {
            // 5 sigfigs surround decimal
            params.bufferLength = 6;
            params.sigfigIndex = 5;
            params.decimalIndex = uint8(digits - 5 + 1);
        }
        params.sigfigs = sigfigs;
        params.isLessThanOne = priceBelow1;
        params.isPercent = false;

        return generateDecimalString(params);
    }

    // @notice Returns string as decimal percentage of fee amount.
    // @param fee fee amount
    function feeToPercentString(uint24 fee) internal pure returns (string memory) {
        if (fee == 0) {
            return "0%";
        }
        uint24 temp = fee;
        uint256 digits;
        uint8 numSigfigs;
        while (temp != 0) {
            if (numSigfigs > 0) {
                // count all digits preceding least significant figure
                numSigfigs++;
            } else if (temp % 10 != 0) {
                numSigfigs++;
            }
            digits++;
            temp /= 10;
        }

        DecimalStringParams memory params;
        uint256 nZeros;
        if (digits >= 5) {
            // if decimal > 1 (5th digit is the ones place)
            uint256 decimalPlace = digits - numSigfigs >= 4 ? 0 : 1;
            nZeros = digits - 5 < (numSigfigs - 1) ? 0 : digits - 5 - (numSigfigs - 1);
            params.zerosStartIndex = numSigfigs;
            params.zerosEndIndex = uint8(params.zerosStartIndex + nZeros - 1);
            params.sigfigIndex = uint8(params.zerosStartIndex - 1 + decimalPlace);
            params.bufferLength = uint8(nZeros + numSigfigs + 1 + decimalPlace);
        } else {
            // else if decimal < 1
            nZeros = 5 - digits;
            params.zerosStartIndex = 2;
            params.zerosEndIndex = uint8(nZeros + params.zerosStartIndex - 1);
            params.bufferLength = uint8(nZeros + numSigfigs + 2);
            params.sigfigIndex = uint8((params.bufferLength) - 2);
            params.isLessThanOne = true;
        }
        params.sigfigs = uint256(fee) / (10 ** (digits - numSigfigs));
        params.isPercent = true;
        params.decimalIndex = digits > 4 ? uint8(digits - 4) : 0;

        return generateDecimalString(params);
    }

    function addressToString(address addr) internal pure returns (string memory) {
        return Strings.toHexString(uint256(uint160(addr)), 20);
    }

    /// @dev Sets basic token/pool info on SVGParams
    function _setSVGBasicInfo(NFTSVG.SVGParams memory s, ConstructTokenURIParams memory p) public pure {
        s.quoteToken = addressToString(p.quoteTokenAddress);
        s.baseToken = addressToString(p.baseTokenAddress);
        s.poolAddress = p.poolAddress;
        s.quoteTokenSymbol = p.quoteTokenSymbol;
        s.baseTokenSymbol = p.baseTokenSymbol;
        s.feeTier = feeToPercentString(p.fee);
    }

    /// @dev Sets tick info on SVGParams
    function _setSVGTickInfo(NFTSVG.SVGParams memory s, ConstructTokenURIParams memory p) public pure {
        s.tickLower = p.tickLower;
        s.tickUpper = p.tickUpper;
        s.tickSpacing = p.tickSpacing;
        s.overRange = overRange(p.tickLower, p.tickUpper, p.tickCurrent);
        s.tokenId = p.tokenId;
    }

    /// @dev Sets color fields on SVGParams
    function _setSVGColors(NFTSVG.SVGParams memory s, address quote, address base) public pure {
        uint256 q = uint256(uint160(quote));
        uint256 b = uint256(uint160(base));
        s.color0 = tokenToColorHex(q, 136);
        s.color1 = tokenToColorHex(b, 136);
        s.color2 = tokenToColorHex(q, 0);
        s.color3 = tokenToColorHex(b, 0);
    }

    /// @dev Sets circle coordinate fields on SVGParams
    function _setSVGCircleCoords(NFTSVG.SVGParams memory s, address quote, address base, uint256 tid) public pure {
        uint256 q = uint256(uint160(quote));
        uint256 b = uint256(uint160(base));
        s.x1 = scale(getCircleCoord(q, 16, tid), 0, 255, 16, 274);
        s.y1 = scale(getCircleCoord(b, 16, tid), 0, 255, 100, 484);
        s.x2 = scale(getCircleCoord(q, 32, tid), 0, 255, 16, 274);
        s.y2 = scale(getCircleCoord(b, 32, tid), 0, 255, 100, 484);
        s.x3 = scale(getCircleCoord(q, 48, tid), 0, 255, 16, 274);
        s.y3 = scale(getCircleCoord(b, 48, tid), 0, 255, 100, 484);
    }

    function generateSVGImage(ConstructTokenURIParams memory params) internal pure returns (string memory svg) {
        NFTSVG.SVGParams memory svgParams;
        _setSVGBasicInfo(svgParams, params);
        _setSVGTickInfo(svgParams, params);
        _setSVGColors(svgParams, params.quoteTokenAddress, params.baseTokenAddress);
        _setSVGCircleCoords(svgParams, params.quoteTokenAddress, params.baseTokenAddress, params.tokenId);
        return NFTSVG.generateSVG(svgParams);
    }

    function overRange(
        int24 tickLower,
        int24 tickUpper,
        int24 tickCurrent
    ) private pure returns (int8) {
        if (tickCurrent < tickLower) {
            return -1;
        } else if (tickCurrent > tickUpper) {
            return 1;
        } else {
            return 0;
        }
    }

    function scale(
        uint256 n,
        uint256 inMn,
        uint256 inMx,
        uint256 outMn,
        uint256 outMx
    ) private pure returns (string memory) {
        return ((n - inMn) * (outMx - outMn) / (inMx - inMn) + outMn).toString();
    }

    function tokenToColorHex(uint256 token, uint256 offset) internal pure returns (string memory str) {
        return string((token >> offset).toHexStringNoPrefix(3));
    }

    function getCircleCoord(
        uint256 tokenAddress,
        uint256 offset,
        uint256 tokenId
    ) internal pure returns (uint256) {
        return (sliceTokenHex(tokenAddress, offset) * tokenId) % 255;
    }

    function sliceTokenHex(uint256 token, uint256 offset) internal pure returns (uint256) {
        return uint256(uint8(token >> offset));
    }
}
