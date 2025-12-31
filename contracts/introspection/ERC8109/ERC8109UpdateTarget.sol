// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC8109Update} from "@crane/contracts/interfaces/IERC8109Update.sol";
import {ERC8109Repo} from "@crane/contracts/introspection/ERC8109/ERC8109Repo.sol";

contract ERC8109UpdateTarget is IERC8109Update {
    function upgradeDiamond(
        FacetFunctions[] calldata _addFunctions,
        FacetFunctions[] calldata _replaceFunctions,
        bytes4[] calldata _removeFunctions,           
        address _delegate,
        bytes calldata _functionCall,
        bytes32 _tag,
        bytes calldata _metadata
    ) external {
        ERC8109Repo._processDiamondUpgrade(
            _addFunctions,
            _replaceFunctions,
            _removeFunctions,
            _delegate,
            _functionCall,
            _tag,
            _metadata
        );
    }
}