// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ERC165Facet} from "@crane/contracts/introspection/ERC165/ERC165Facet.sol";

library CodeLib_ERC165Facet {
    function initCode() external pure returns (bytes memory) {
        return type(ERC165Facet).creationCode;
    }
}
