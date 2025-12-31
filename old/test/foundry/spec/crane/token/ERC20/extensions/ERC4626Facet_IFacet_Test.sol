// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {TestBase_IFacet} from "contracts/crane/test/bases/TestBase_IFacet.sol";
import {IFacet} from "contracts/crane/interfaces/IFacet.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {ERC4626Facet} from "contracts/crane/token/ERC20/extensions/ERC4626Facet.sol";

contract ERC4626Facet_IFacet_Test is TestBase_IFacet {
    function facetTestInstance() public override returns (IFacet) {
        return IFacet(
            address(
                ERC4626Facet(
                    factory()
                        .create3(type(ERC4626Facet).creationCode, "", keccak256(abi.encode(type(ERC4626Facet).name)))
                )
            )
        );
    }

    function controlFacetInterfaces() public pure override returns (bytes4[] memory controlInterfaces) {
        controlInterfaces = new bytes4[](1);
        controlInterfaces[0] = type(IERC4626).interfaceId;
    }

    function controlFacetFuncs() public pure override returns (bytes4[] memory controlFuncs) {
        controlFuncs = new bytes4[](16);
        controlFuncs[0] = IERC4626.asset.selector;
        controlFuncs[1] = IERC4626.totalAssets.selector;
        controlFuncs[2] = IERC4626.convertToShares.selector;
        controlFuncs[3] = IERC4626.convertToAssets.selector;
        controlFuncs[4] = IERC4626.maxDeposit.selector;
        controlFuncs[5] = IERC4626.maxMint.selector;
        controlFuncs[6] = IERC4626.maxWithdraw.selector;
        controlFuncs[7] = IERC4626.maxRedeem.selector;
        controlFuncs[8] = IERC4626.previewDeposit.selector;
        controlFuncs[9] = IERC4626.previewMint.selector;
        controlFuncs[10] = IERC4626.previewWithdraw.selector;
        controlFuncs[11] = IERC4626.previewRedeem.selector;
        controlFuncs[12] = IERC4626.deposit.selector;
        controlFuncs[13] = IERC4626.mint.selector;
        controlFuncs[14] = IERC4626.withdraw.selector;
        controlFuncs[15] = IERC4626.redeem.selector;
    }
}
