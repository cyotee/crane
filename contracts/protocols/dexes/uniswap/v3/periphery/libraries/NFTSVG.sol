// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Strings} from "@crane/contracts/utils/Strings.sol";
import {Base64} from "@crane/contracts/utils/Base64.sol";
import "../../libraries/BitMath.sol";

/// @title NFTSVG
/// @notice Provides a function for generating an SVG associated with a Uniswap NFT
library NFTSVG {
    using Strings for uint256;

    string constant curve1 = "M1 1C41 41 105 105 145 145";
    string constant curve2 = "M1 1C33 49 97 113 145 145";
    string constant curve3 = "M1 1C33 57 89 113 145 145";
    string constant curve4 = "M1 1C25 65 81 121 145 145";
    string constant curve5 = "M1 1C17 73 73 129 145 145";
    string constant curve6 = "M1 1C9 81 65 137 145 145";
    string constant curve7 = "M1 1C1 89 57.5 145 145 145";
    string constant curve8 = "M1 1C1 97 49 145 145 145";

    struct SVGParams {
        string quoteToken;
        string baseToken;
        address poolAddress;
        string quoteTokenSymbol;
        string baseTokenSymbol;
        string feeTier;
        int24 tickLower;
        int24 tickUpper;
        int24 tickSpacing;
        int8 overRange;
        uint256 tokenId;
        string color0;
        string color1;
        string color2;
        string color3;
        string x1;
        string y1;
        string x2;
        string y2;
        string x3;
        string y3;
    }

    function generateSVG(SVGParams memory params) public pure returns (string memory svg) {
        /*
        address: "0xe8ab59d3bcde16a29912de83a90eb39628cfc163",
        msg: "Forged in SVG for Uniswap in 2021 by 0xe8ab59d3bcde16a29912de83a90eb39628cfc163",
        sig: "0x2df0e99d9cbfec33a705d83f75666d98b22dea7c1af412c584f7d626d83f02875993df740dc87563b9c73378f8462426da572d7989de88079a382ad96c57b68d1b",
        version: "2"
        */
        // Generate parts in separate scopes to reduce stack depth
        string memory defs;
        string memory borderText;
        {
            defs = generateSVGDefs(params);
            borderText = generateSVGBorderText(
                params.quoteToken,
                params.baseToken,
                params.quoteTokenSymbol,
                params.baseTokenSymbol
            );
        }

        string memory cardMantle;
        string memory curve;
        {
            cardMantle = generateSVGCardMantle(params.quoteTokenSymbol, params.baseTokenSymbol, params.feeTier);
            curve = generageSvgCurve(params.tickLower, params.tickUpper, params.tickSpacing, params.overRange);
        }

        string memory positionData;
        string memory rareSparkle;
        {
            positionData = generateSVGPositionDataAndLocationCurve(
                params.tokenId.toString(),
                params.tickLower,
                params.tickUpper
            );
            rareSparkle = generateSVGRareSparkle(params.tokenId, params.poolAddress);
        }

        return string(abi.encodePacked(defs, borderText, cardMantle, curve, positionData, rareSparkle, "</svg>"));
    }

    /// @dev Generates Base64 encoded SVG for background rectangle
    function _genP0(string memory color0) private pure returns (string memory) {
        return Base64.encode(
            bytes(
                abi.encodePacked(
                    "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><rect width='290px' height='500px' fill='#",
                    color0,
                    "'/></svg>"
                )
            )
        );
    }

    /// @dev Generates Base64 encoded SVG for circle 1
    function _genP1(string memory x1, string memory y1, string memory color1) private pure returns (string memory) {
        return Base64.encode(
            bytes(
                abi.encodePacked(
                    "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><circle cx='",
                    x1, "' cy='", y1, "' r='120px' fill='#", color1, "'/></svg>"
                )
            )
        );
    }

    /// @dev Generates Base64 encoded SVG for circle 2
    function _genP2(string memory x2, string memory y2, string memory color2) private pure returns (string memory) {
        return Base64.encode(
            bytes(
                abi.encodePacked(
                    "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><circle cx='",
                    x2, "' cy='", y2, "' r='120px' fill='#", color2, "'/></svg>"
                )
            )
        );
    }

    /// @dev Generates Base64 encoded SVG for circle 3
    function _genP3(string memory x3, string memory y3, string memory color3) private pure returns (string memory) {
        return Base64.encode(
            bytes(
                abi.encodePacked(
                    "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><circle cx='",
                    x3, "' cy='", y3, "' r='100px' fill='#", color3, "'/></svg>"
                )
            )
        );
    }

    /// @dev Generates the filter section with feImage elements
    function _genFilterDefs(SVGParams memory params) private pure returns (string memory) {
        string memory p0;
        string memory p1;
        {
            p0 = _genP0(params.color0);
            p1 = _genP1(params.x1, params.y1, params.color1);
        }
        string memory p2;
        string memory p3;
        {
            p2 = _genP2(params.x2, params.y2, params.color2);
            p3 = _genP3(params.x3, params.y3, params.color3);
        }

        bytes memory part1 = abi.encodePacked(
            '<svg width="290" height="500" viewBox="0 0 290 500" xmlns="http://www.w3.org/2000/svg"',
            " xmlns:xlink='http://www.w3.org/1999/xlink'>",
            "<defs>",
            '<filter id="f1"><feImage result="p0" xlink:href="data:image/svg+xml;base64,',
            p0,
            '"/><feImage result="p1" xlink:href="data:image/svg+xml;base64,',
            p1
        );

        bytes memory part2 = abi.encodePacked(
            '"/><feImage result="p2" xlink:href="data:image/svg+xml;base64,',
            p2,
            '" />',
            '<feImage result="p3" xlink:href="data:image/svg+xml;base64,',
            p3,
            '" /><feBlend mode="overlay" in="p0" in2="p1" /><feBlend mode="exclusion" in2="p2" /><feBlend mode="overlay" in2="p3" result="blendOut" /><feGaussianBlur ',
            'in="blendOut" stdDeviation="42" /></filter>'
        );

        return string(abi.encodePacked(part1, part2));
    }

    /// @dev Generates static SVG definitions (paths, gradients, masks)
    function _genStaticDefs() private pure returns (string memory) {
        bytes memory part1 = abi.encodePacked(
            ' <clipPath id="corners"><rect width="290" height="500" rx="42" ry="42" /></clipPath>',
            '<path id="text-path-a" d="M40 12 H250 A28 28 0 0 1 278 40 V460 A28 28 0 0 1 250 488 H40 A28 28 0 0 1 12 460 V40 A28 28 0 0 1 40 12 z" />',
            '<path id="minimap" d="M234 444C234 457.949 242.21 463 253 463" />',
            '<filter id="top-region-blur"><feGaussianBlur in="SourceGraphic" stdDeviation="24" /></filter>'
        );

        bytes memory part2 = abi.encodePacked(
            '<linearGradient id="grad-up" x1="1" x2="0" y1="1" y2="0"><stop offset="0.0" stop-color="white" stop-opacity="1" />',
            '<stop offset=".9" stop-color="white" stop-opacity="0" /></linearGradient>',
            '<linearGradient id="grad-down" x1="0" x2="1" y1="0" y2="1"><stop offset="0.0" stop-color="white" stop-opacity="1" /><stop offset="0.9" stop-color="white" stop-opacity="0" /></linearGradient>'
        );

        bytes memory part3 = abi.encodePacked(
            '<mask id="fade-up" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="url(#grad-up)" /></mask>',
            '<mask id="fade-down" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="url(#grad-down)" /></mask>',
            '<mask id="none" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="white" /></mask>'
        );

        bytes memory part4 = abi.encodePacked(
            '<linearGradient id="grad-symbol"><stop offset="0.7" stop-color="white" stop-opacity="1" /><stop offset=".95" stop-color="white" stop-opacity="0" /></linearGradient>',
            '<mask id="fade-symbol" maskContentUnits="userSpaceOnUse"><rect width="290px" height="200px" fill="url(#grad-symbol)" /></mask></defs>'
        );

        return string(abi.encodePacked(part1, part2, part3, part4));
    }

    /// @dev Generates the background group with filters
    function _genBackgroundGroup(string memory color0) private pure returns (string memory) {
        return string(abi.encodePacked(
            '<g clip-path="url(#corners)">',
            '<rect fill="', color0, '" x="0px" y="0px" width="290px" height="500px" />',
            '<rect style="filter: url(#f1)" x="0px" y="0px" width="290px" height="500px" />',
            ' <g style="filter:url(#top-region-blur); transform:scale(1.5); transform-origin:center top;">',
            '<rect fill="none" x="0px" y="0px" width="290px" height="500px" />',
            '<ellipse cx="50%" cy="0px" rx="180px" ry="120px" fill="#000" opacity="0.85" /></g>',
            '<rect x="0" y="0" width="290" height="500" rx="42" ry="42" fill="rgba(0,0,0,0)" stroke="rgba(255,255,255,0.2)" /></g>'
        ));
    }

    function generateSVGDefs(SVGParams memory params) private pure returns (string memory svg) {
        string memory filterDefs = _genFilterDefs(params);
        string memory staticDefs = _genStaticDefs();
        string memory bgGroup = _genBackgroundGroup(params.color0);
        return string(abi.encodePacked(filterDefs, staticDefs, bgGroup));
    }

    function generateSVGBorderText(
        string memory quoteToken,
        string memory baseToken,
        string memory quoteTokenSymbol,
        string memory baseTokenSymbol
    ) private pure returns (string memory svg) {
        // Split into smaller parts to avoid stack-too-deep
        bytes memory part1;
        {
            part1 = abi.encodePacked(
                "<text text-rendering=\"optimizeSpeed\">",
                "<textPath startOffset=\"-100%\" fill=\"white\" font-family=\"'Courier New', monospace\" font-size=\"10px\" xlink:href=\"#text-path-a\">",
                baseToken,
                unicode" • ",
                baseTokenSymbol,
                ' <animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" />'
            );
        }
        bytes memory part2;
        {
            part2 = abi.encodePacked(
                "</textPath> <textPath startOffset=\"0%\" fill=\"white\" font-family=\"'Courier New', monospace\" font-size=\"10px\" xlink:href=\"#text-path-a\">",
                baseToken,
                unicode" • ",
                baseTokenSymbol,
                ' <animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /> </textPath>'
            );
        }
        bytes memory part3;
        {
            part3 = abi.encodePacked(
                "<textPath startOffset=\"50%\" fill=\"white\" font-family=\"'Courier New', monospace\" font-size=\"10px\" xlink:href=\"#text-path-a\">",
                quoteToken,
                unicode" • ",
                quoteTokenSymbol,
                ' <animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s"'
            );
        }
        bytes memory part4;
        {
            part4 = abi.encodePacked(
                " repeatCount=\"indefinite\" /></textPath><textPath startOffset=\"-50%\" fill=\"white\" font-family=\"'Courier New', monospace\" font-size=\"10px\" xlink:href=\"#text-path-a\">",
                quoteToken,
                unicode" • ",
                quoteTokenSymbol,
                ' <animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /></textPath></text>'
            );
        }
        svg = string(abi.encodePacked(part1, part2, part3, part4));
    }

    function generateSVGCardMantle(
        string memory quoteTokenSymbol,
        string memory baseTokenSymbol,
        string memory feeTier
    ) private pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                "<g mask=\"url(#fade-symbol)\"><rect fill=\"none\" x=\"0px\" y=\"0px\" width=\"290px\" height=\"200px\" /> <text y=\"70px\" x=\"32px\" fill=\"white\" font-family=\"'Courier New', monospace\" font-weight=\"200\" font-size=\"36px\">",
                quoteTokenSymbol,
                "/",
                baseTokenSymbol,
                "</text><text y=\"115px\" x=\"32px\" fill=\"white\" font-family=\"'Courier New', monospace\" font-weight=\"200\" font-size=\"36px\">",
                feeTier,
                "</text></g>",
                '<rect x="16" y="16" width="258" height="468" rx="26" ry="26" fill="rgba(0,0,0,0)" stroke="rgba(255,255,255,0.2)" />'
            )
        );
    }

    function generageSvgCurve(
        int24 tickLower,
        int24 tickUpper,
        int24 tickSpacing,
        int8 overRange
    ) private pure returns (string memory svg) {
        string memory fade = overRange == 1 ? "#fade-up" : overRange == -1 ? "#fade-down" : "#none";
        string memory curve = getCurve(tickLower, tickUpper, tickSpacing);
        svg = string(
            abi.encodePacked(
                "<g mask=\"url(",
                fade,
                ")\"",
                ' style="transform:translate(72px,189px)">'
                '<rect x="-16px" y="-16px" width="180px" height="180px" fill="none" />'
                '<path d="',
                curve,
                '" stroke="rgba(0,0,0,0.3)" stroke-width="32px" fill="none" stroke-linecap="round" />',
                "</g><g mask=\"url(",
                fade,
                ")\"",
                ' style="transform:translate(72px,189px)">',
                '<rect x="-16px" y="-16px" width="180px" height="180px" fill="none" />',
                '<path d="',
                curve,
                '" stroke="rgba(255,255,255,1)" fill="none" stroke-linecap="round" /></g>',
                generateSVGCurveCircle(overRange)
            )
        );
    }

    function getCurve(
        int24 tickLower,
        int24 tickUpper,
        int24 tickSpacing
    ) internal pure returns (string memory curve) {
        int24 tickRange = (tickUpper - tickLower) / tickSpacing;
        if (tickRange <= 4) {
            curve = curve1;
        } else if (tickRange <= 8) {
            curve = curve2;
        } else if (tickRange <= 16) {
            curve = curve3;
        } else if (tickRange <= 32) {
            curve = curve4;
        } else if (tickRange <= 64) {
            curve = curve5;
        } else if (tickRange <= 128) {
            curve = curve6;
        } else if (tickRange <= 256) {
            curve = curve7;
        } else {
            curve = curve8;
        }
    }

    function generateSVGCurveCircle(int8 overRange) internal pure returns (string memory svg) {
        string memory curvex1 = "73";
        string memory curvey1 = "190";
        string memory curvex2 = "217";
        string memory curvey2 = "334";
        if (overRange == 1 || overRange == -1) {
            svg = string(
                abi.encodePacked(
                    '<circle cx="',
                    overRange == -1 ? curvex1 : curvex2,
                    'px" cy="',
                    overRange == -1 ? curvey1 : curvey2,
                    'px" r="4px" fill="white" /><circle cx="',
                    overRange == -1 ? curvex1 : curvex2,
                    'px" cy="',
                    overRange == -1 ? curvey1 : curvey2,
                    'px" r="24px" fill="none" stroke="white" />'
                )
            );
        } else {
            svg = string(
                abi.encodePacked(
                    '<circle cx="',
                    curvex1,
                    'px" cy="',
                    curvey1,
                    'px" r="4px" fill="white" />',
                    '<circle cx="',
                    curvex2,
                    'px" cy="',
                    curvey2,
                    'px" r="4px" fill="white" />'
                )
            );
        }
    }

    /// @dev Generates a position data box (ID, Min Tick, or Max Tick)
    function _genPositionBox(
        string memory yPos,
        string memory label,
        string memory value,
        uint256 strLength
    ) private pure returns (string memory) {
        return string(abi.encodePacked(
            ' <g style="transform:translate(29px, ', yPos, 'px)">',
            '<rect width="',
            (7 * (strLength + 4)).toString(),
            'px" height="26px" rx="8px" ry="8px" fill="rgba(0,0,0,0.6)" />',
            "<text x=\"12px\" y=\"17px\" font-family=\"'Courier New', monospace\" font-size=\"12px\" fill=\"white\"><tspan fill=\"rgba(255,255,255,0.6)\">",
            label,
            "</tspan>",
            value,
            "</text></g>"
        ));
    }

    /// @dev Generates the location curve minimap
    function _genLocationCurve(string memory xCoord, string memory yCoord) private pure returns (string memory) {
        return string(abi.encodePacked(
            '<g style="transform:translate(226px, 433px)">',
            '<rect width="36px" height="36px" rx="8px" ry="8px" fill="none" stroke="rgba(255,255,255,0.2)" />',
            '<path stroke-linecap="round" d="M8 9C8.00004 22.9494 16.2099 28 27 28" fill="none" stroke="white" />',
            '<circle style="transform:translate3d(',
            xCoord,
            "px, ",
            yCoord,
            'px, 0px)" cx="0px" cy="0px" r="4px" fill="white"/></g>'
        ));
    }

    function generateSVGPositionDataAndLocationCurve(
        string memory tokenId,
        int24 tickLower,
        int24 tickUpper
    ) private pure returns (string memory svg) {
        string memory tickLowerStr = tickToString(tickLower);
        string memory tickUpperStr = tickToString(tickUpper);

        string memory idBox;
        {
            uint256 str1length = bytes(tokenId).length + 4;
            idBox = _genPositionBox("384", "ID: ", tokenId, str1length);
        }

        string memory minTickBox;
        {
            uint256 str2length = bytes(tickLowerStr).length + 10;
            minTickBox = _genPositionBox("414", "Min Tick: ", tickLowerStr, str2length);
        }

        string memory maxTickBox;
        {
            uint256 str3length = bytes(tickUpperStr).length + 10;
            maxTickBox = _genPositionBox("444", "Max Tick: ", tickUpperStr, str3length);
        }

        string memory locationCurve;
        {
            (string memory xCoord, string memory yCoord) = rangeLocation(tickLower, tickUpper);
            locationCurve = _genLocationCurve(xCoord, yCoord);
        }

        svg = string(abi.encodePacked(idBox, minTickBox, maxTickBox, locationCurve));
    }

    function tickToString(int24 tick) private pure returns (string memory) {
        string memory sign = "";
        if (tick < 0) {
            tick = tick * -1;
            sign = "-";
        }
        return string(abi.encodePacked(sign, uint256(uint24(tick)).toString()));
    }

    function rangeLocation(int24 tickLower, int24 tickUpper) internal pure returns (string memory, string memory) {
        int24 midPoint = (tickLower + tickUpper) / 2;
        if (midPoint < -125_000) {
            return ("8", "7");
        } else if (midPoint < -75_000) {
            return ("8", "10.5");
        } else if (midPoint < -25_000) {
            return ("8", "14.25");
        } else if (midPoint < -5_000) {
            return ("10", "18");
        } else if (midPoint < 0) {
            return ("11", "21");
        } else if (midPoint < 5_000) {
            return ("13", "23");
        } else if (midPoint < 25_000) {
            return ("15", "25");
        } else if (midPoint < 75_000) {
            return ("18", "26");
        } else if (midPoint < 125_000) {
            return ("21", "27");
        } else {
            return ("24", "27");
        }
    }

    function generateSVGRareSparkle(uint256 tokenId, address poolAddress) private pure returns (string memory svg) {
        if (isRare(tokenId, poolAddress)) {
            svg = string(
                abi.encodePacked(
                    '<g style="transform:translate(226px, 392px)"><rect width="36px" height="36px" rx="8px" ry="8px" fill="none" stroke="rgba(255,255,255,0.2)" />',
                    "<g><path style=\"transform:translate(6px,6px)\" d=\"M12 0L12.6522 9.56587L18 1.6077L13.7819 10.2181L22.3923 6L14.4341 ",
                    '11.3478L24 12L14.4341 12.6522L22.3923 18L13.7819 13.7819L18 22.3923L12.6522 14.4341L12 24L11.3478 14.4341L6 22.39',
                    '23L10.2181 13.7819L1.6077 18L9.56587 12.6522L0 12L9.56587 11.3478L1.6077 6L10.2181 10.2181L6 1.6077L11.3478 9.56587L12 0Z" fill="white" />',
                    '<animateTransform attributeName="transform" type="rotate" from="0 18 18" to="360 18 18" dur="10s" repeatCount="indefinite"/></g></g>'
                )
            );
        } else {
            svg = "";
        }
    }

    function isRare(uint256 tokenId, address poolAddress) internal pure returns (bool) {
        bytes32 h = keccak256(abi.encodePacked(tokenId, poolAddress));
        return uint256(h) < type(uint256).max / (1 + BitMath.mostSignificantBit(tokenId) * 2);
    }
}
