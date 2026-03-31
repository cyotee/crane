// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {DiamondLoupeFacet} from "@crane/contracts/introspection/ERC2535/DiamondLoupeFacet.sol";

library CodeLib_DiamondLoupeFacet {
    function initCode() external pure returns (bytes memory) {
        return type(DiamondLoupeFacet).creationCode;
    }
}
