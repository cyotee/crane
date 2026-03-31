// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {PostDeployAccountHookFacet} from "@crane/contracts/factories/diamondPkg/PostDeployAccountHookFacet.sol";

library CodeLib_PostDeployAccountHookFacet {
    function initCode() external pure returns (bytes memory) {
        return type(PostDeployAccountHookFacet).creationCode;
    }
}
