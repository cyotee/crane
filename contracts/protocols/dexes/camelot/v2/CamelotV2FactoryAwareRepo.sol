// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ICamelotFactory} from "@crane/contracts/interfaces/protocols/dexes/camelot/v2/ICamelotFactory.sol";

library CamelotV2FactoryAwareRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("crane.camelot.v2.factory.aware");

    struct Storage {
        ICamelotFactory factory;
    }

    function _layout(bytes32 slot) internal pure returns (Storage storage layout) {
        assembly {
            layout.slot := slot
        }
    }

    function _layout() internal pure returns (Storage storage layout) {
        return _layout(STORAGE_SLOT);
    }

    function _initialize(Storage storage layout, ICamelotFactory factory_) internal {
        layout.factory = factory_;
    }

    function _initialize(ICamelotFactory factory_) internal {
        _initialize(_layout(), factory_);
    }

    function _camelotV2Factory(Storage storage layout) internal view returns (ICamelotFactory factory_) {
        return layout.factory;
    }

    function _camelotV2Factory() internal view returns (ICamelotFactory factory_) {
        return _camelotV2Factory(_layout());
    }
}