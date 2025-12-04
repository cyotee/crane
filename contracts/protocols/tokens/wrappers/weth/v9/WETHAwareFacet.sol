// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IWETH} from "@balancer-labs/v3-interfaces/contracts/solidity-utils/misc/IWETH.sol";
import {IWETHAware} from "@crane/contracts/interfaces/IWETHAware.sol";
import {WETHAwareRepo} from "@crane/contracts/protocols/tokens/wrappers/weth/v9/WETHAwareRepo.sol";

contract WETHAwareFacet is IWETHAware, IFacet {
    function facetName() public pure returns (string memory name) {
        return type(WETHAwareFacet).name;
    }

    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IWETHAware).interfaceId;
        return interfaces;
    }

    function facetFuncs() public pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](1);
        funcs[0] = IWETHAware.weth.selector;
        return funcs;
    }

    function facetMetadata()
        external
        pure
        returns (string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }

    function weth() external view returns (IWETH) {
        return WETHAwareRepo._weth();
    }
}
