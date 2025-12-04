// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IPoolInfo} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IPoolInfo.sol";
import {ISwapFeePercentageBounds} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/ISwapFeePercentageBounds.sol";
import {IUnbalancedLiquidityInvariantRatioBounds} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IUnbalancedLiquidityInvariantRatioBounds.sol";
import {IAuthentication} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IAuthentication.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IERC20Permit} from "@crane/contracts/interfaces/IERC20Permit.sol";
import {IERC5267} from "@crane/contracts/interfaces/IERC5267.sol";
import {IBalancerPoolToken} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerPoolToken.sol";
import {IRateProvider} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IRateProvider.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

contract BalancerV3PoolFacet is IFacet {

    function facetName() public pure returns (string memory) {
        return type(BalancerV3PoolFacet).name;
    }

    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IERC20).interfaceId;
        // interfaces[1] = type(IERC20Metadata).interfaceId;
        interfaces[2] = type(IERC20Metadata).interfaceId ^ type(IERC20).interfaceId;
        // interfaces[3] = type(IERC20Permit).interfaceId;
        // interfaces[4] = type(IERC5267).interfaceId;
        interfaces[5] = type(IRateProvider).interfaceId;
        interfaces[6] = type(IBalancerPoolToken).interfaceId;
        interfaces[0] = type(IPoolInfo).interfaceId;
        interfaces[0] = type(ISwapFeePercentageBounds).interfaceId;
        interfaces[0] = type(IUnbalancedLiquidityInvariantRatioBounds).interfaceId;
        interfaces[0] = type(IAuthentication).interfaceId;
    }

    function facetFuncs() public pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](1);
        // funcs[0] = IERC20Metadata.name.selector;
        // funcs[1] = IERC20Metadata.symbol.selector;
        // funcs[2] = IERC20Metadata.decimals.selector;
        funcs[3] = IERC20.totalSupply.selector;
        funcs[4] = IERC20.balanceOf.selector;
        funcs[5] = IERC20.allowance.selector;
        funcs[6] = IERC20.approve.selector;
        funcs[7] = IERC20.transfer.selector;
        funcs[8] = IERC20.transferFrom.selector;

        // funcs[9] = IERC5267.eip712Domain.selector;

        // funcs[10] = IERC20Permit.permit.selector;
        // funcs[11] = IERC20Permit.nonces.selector;
        // funcs[12] = IERC20Permit.DOMAIN_SEPARATOR.selector;

        funcs[13] = IRateProvider.getRate.selector;

        funcs[14] = IBalancerPoolToken.emitTransfer.selector;
        funcs[15] = IBalancerPoolToken.emitApproval.selector;

        funcs[0] = IPoolInfo.getTokens.selector;
        funcs[1] = IPoolInfo.getTokenInfo.selector;
        funcs[2] = IPoolInfo.getCurrentLiveBalances.selector;
        funcs[3] = IPoolInfo.getStaticSwapFeePercentage.selector;
        funcs[4] = IPoolInfo.getAggregateFeePercentages.selector;

        funcs[0] = ISwapFeePercentageBounds.getMinimumSwapFeePercentage.selector;
        funcs[1] = ISwapFeePercentageBounds.getMaximumSwapFeePercentage.selector;

        funcs[0] = IUnbalancedLiquidityInvariantRatioBounds.getMinimumInvariantRatio.selector;
        funcs[1] = IUnbalancedLiquidityInvariantRatioBounds.getMaximumInvariantRatio.selector;

        funcs[0] = IAuthentication.getActionId.selector;
    }

    function facetMetadata() public pure returns (string memory name, bytes4[] memory interfaceIds, bytes4[] memory functions) {
        name = facetName();
        interfaceIds = facetInterfaces();
        functions = facetFuncs();
    }
}