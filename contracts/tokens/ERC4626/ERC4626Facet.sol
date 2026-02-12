// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IERC4626} from "@crane/contracts/interfaces/IERC4626.sol";
import {ERC4626Target} from "@crane/contracts/tokens/ERC4626/ERC4626Target.sol";

contract ERC4626Facet is ERC4626Target, IFacet {
    function facetName() public pure returns (string memory name) {
        return type(ERC4626Facet).name;
    }

    function facetInterfaces()
        public
        pure
        virtual
        returns (
            // override
            bytes4[] memory interfaces
        )
    {
        interfaces = new bytes4[](1);

        interfaces[0] = type(IERC4626).interfaceId;
    }

    function facetFuncs()
        public
        pure
        virtual
        returns (
            // override
            bytes4[] memory funcs
        )
    {
        funcs = new bytes4[](16);

        funcs[0] = IERC4626.asset.selector;
        funcs[1] = IERC4626.totalAssets.selector;
        funcs[2] = IERC4626.convertToShares.selector;
        funcs[3] = IERC4626.convertToAssets.selector;
        funcs[4] = IERC4626.maxDeposit.selector;
        funcs[5] = IERC4626.previewDeposit.selector;
        funcs[6] = IERC4626.deposit.selector;
        funcs[7] = IERC4626.maxMint.selector;
        funcs[8] = IERC4626.previewMint.selector;
        funcs[9] = IERC4626.mint.selector;
        funcs[10] = IERC4626.maxWithdraw.selector;
        funcs[11] = IERC4626.previewWithdraw.selector;
        funcs[12] = IERC4626.withdraw.selector;
        funcs[13] = IERC4626.maxRedeem.selector;
        funcs[14] = IERC4626.previewRedeem.selector;
        funcs[15] = IERC4626.redeem.selector;
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