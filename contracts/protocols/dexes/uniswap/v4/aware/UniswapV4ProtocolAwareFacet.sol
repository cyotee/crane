// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IUniswapV4ProtocolAware} from "@crane/contracts/interfaces/IUniswapV4ProtocolAware.sol";
import {UniswapV4ProtocolAwareTarget} from "./UniswapV4ProtocolAwareTarget.sol";

contract UniswapV4ProtocolAwareFacet is UniswapV4ProtocolAwareTarget, IFacet {
    function facetName() public pure returns (string memory name) {
        return type(UniswapV4ProtocolAwareFacet).name;
    }

    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IUniswapV4ProtocolAware).interfaceId;
    }

    function facetFuncs() public pure virtual returns (bytes4[] memory funcs) {
        funcs = new bytes4[](7);
        funcs[0] = IUniswapV4ProtocolAware.poolManager.selector;
        funcs[1] = IUniswapV4ProtocolAware.positionDescriptor.selector;
        funcs[2] = IUniswapV4ProtocolAware.positionManager.selector;
        funcs[3] = IUniswapV4ProtocolAware.quoter.selector;
        funcs[4] = IUniswapV4ProtocolAware.stateView.selector;
        funcs[5] = IUniswapV4ProtocolAware.reservesLens.selector;
        funcs[6] = IUniswapV4ProtocolAware.universalRouter.selector;
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
