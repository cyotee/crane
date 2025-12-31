// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC8109Introspection} from "@crane/contracts/interfaces/IERC8109Introspection.sol";
import {ERC2535Repo} from "@crane/contracts/introspection/ERC2535/ERC2535Repo.sol";
import {ERC8109Repo} from "contracts/introspection/ERC8109/ERC8109Repo.sol";

contract ERC8109IntrospectionTarget is IERC8109Introspection {
    /** 
     * @inheritdoc IERC8109Introspection
     */
    function facetAddress(bytes4 _functionSelector) external view returns (address) {
        return ERC2535Repo._facetAddress(_functionSelector);
    }
 
    /** 
     * @inheritdoc IERC8109Introspection
     */
    function functionFacetPairs() external view returns(FunctionFacetPair[] memory pairs) {
        return ERC8109Repo._functionFacetPairs();
    }

}