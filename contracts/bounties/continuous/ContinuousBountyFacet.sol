// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ContinuousBountyTarget} from "@crane/contracts/bounties/continuous/ContinuousBountyTarget.sol";
import {IContinuousBounty} from "@crane/contracts/bounties/continuous/IContinuousBounty.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {FacetBase} from "@crane/contracts/factories/diamondPkg/FacetBase.sol";

contract ContinuousBountyFacet is ContinuousBountyTarget, FacetBase {
    function facetName() public pure override returns (string memory name) {
        return type(ContinuousBountyFacet).name;
    }

    function facetInterfaces() public pure override returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IContinuousBounty).interfaceId;
    }

    function facetFuncs() public pure override returns (bytes4[] memory funcs) {
        funcs = new bytes4[](3);
        funcs[0] = IContinuousBounty.createContinuousBounty.selector;
        funcs[1] = IContinuousBounty.submitDelivery.selector;
        funcs[2] = IContinuousBounty.approveDelivery.selector;
    }
}
