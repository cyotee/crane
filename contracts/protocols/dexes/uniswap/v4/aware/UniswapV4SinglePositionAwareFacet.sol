// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IUniswapV4SinglePositionAware} from "@crane/contracts/interfaces/IUniswapV4SinglePositionAware.sol";
import {UniswapV4SinglePositionAwareTarget} from "./UniswapV4SinglePositionAwareTarget.sol";

contract UniswapV4SinglePositionAwareFacet is UniswapV4SinglePositionAwareTarget, IFacet {
    function facetName() public pure returns (string memory name) {
        return type(UniswapV4SinglePositionAwareFacet).name;
    }

    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IUniswapV4SinglePositionAware).interfaceId;
    }

    function facetFuncs() public pure virtual returns (bytes4[] memory funcs) {
        funcs = new bytes4[](5);
        funcs[0] = IUniswapV4SinglePositionAware.poolKey.selector;
        funcs[1] = IUniswapV4SinglePositionAware.tickLower.selector;
        funcs[2] = IUniswapV4SinglePositionAware.tickUpper.selector;
        funcs[3] = IUniswapV4SinglePositionAware.positionSalt.selector;
        funcs[4] = IUniswapV4SinglePositionAware.positionLiquidity.selector;
    }

    function facetMetadata()
        external
        pure
        returns (string memory name_, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name_ = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
}
