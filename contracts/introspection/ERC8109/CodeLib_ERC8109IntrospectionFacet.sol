// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ERC8109IntrospectionFacet} from "@crane/contracts/introspection/ERC8109/ERC8109IntrospectionFacet.sol";

library CodeLib_ERC8109IntrospectionFacet {
    function initCode() external pure returns (bytes memory) {
        return type(ERC8109IntrospectionFacet).creationCode;
    }
}
