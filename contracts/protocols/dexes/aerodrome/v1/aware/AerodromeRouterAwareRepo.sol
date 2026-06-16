// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IRouter} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IRouter.sol";

// tag::AerodromeRouterAwareRepo[]
/**
 * @title AerodromeRouterAwareRepo - Storage library for Aerodrome V1 router dependency injection (Aware pattern).
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Storage library (Repo) for holding a reference to the Aerodrome V1 IRouter.
 * @dev Provides dual (parameterized + default) overloads for initialization and getter.
 * @dev Follows the gold standard from DeployedAddressesRepo, OperableRepo, MultiStepOwnableRepo, ERC2535Repo, Create3FactoryAwareRepo, DiamondPackageFactoryAwareRepo, BalancerV3VaultAwareRepo, CamelotV2RouterAwareRepo, UniswapV2FactoryAwareRepo, UniswapV2RouterAwareRepo
 *      (rich NatSpec, exact // tag:: / end:: include tags, @dev "The Storage struct to operate on.", ERC1967 slot).
 * @dev Used by Aerodrome V1 protocol ports (services, test bases, etc.) for dependency injection of the Aerodrome V1 router.
 */
library AerodromeRouterAwareRepo {
    // tag::STORAGE_SLOT[]
    /**
     * @dev ERC1967-compliant storage slot.
     *      Computed as bytes32(uint256(keccak256(abi.encode("protocols.dexes.aerodrome.v1.router.aware"))) - 1).
     *      This follows the canonical pattern used by OperableRepo, ERC2535Repo, MultiStepOwnableRepo, DeployedAddressesRepo, Create3FactoryAwareRepo, DiamondPackageFactoryAwareRepo, BalancerV3VaultAwareRepo, CamelotV2RouterAwareRepo and other
     *      gold-standard Repos for collision-resistant deterministic storage binding.
     */
    bytes32 internal constant STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("protocols.dexes.aerodrome.v1.router.aware"))) - 1);
    // end::STORAGE_SLOT[]

    // tag::Storage[]
    /**
     * @dev Standardized storage layout for aerodrome v1 router reference (Aware).
     *      router: reference to IRouter.
     */
    struct Storage {
        IRouter router;
    }
    // end::Storage[]

    // tag::_layoutStruct(bytes32)[]
    /**
     * @dev Argumented version of _layoutStruct to allow for custom storage slot usage.
     * @param slot_ The storage slot to bind.
     * @return layoutStruct The Storage struct bound to the provided slot.
     */
    function _layoutStruct(bytes32 slot_) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot_
        }
    }
    // end::_layoutStruct(bytes32)[]

    // tag::_layoutStruct()[]
    /**
     * @dev Default _layoutStruct binding to the canonical ERC1967 STORAGE_SLOT.
     * @return layoutStruct The Storage struct bound to STORAGE_SLOT.
     */
    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }
    // end::_layoutStruct()[]

    // tag::_initialize(Storage-IRouter)[]
    /**
     * @dev Argumented version of _initialize to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param router_ The IRouter instance to inject.
     */
    function _initialize(Storage storage layoutStruct, IRouter router_) internal {
        layoutStruct.router = router_;
    }
    // end::_initialize(Storage-IRouter)[]

    // tag::_initialize(IRouter)[]
    /**
     * @dev Default version of _initialize binding to the standard STORAGE_SLOT.
     * @param router_ The IRouter instance to inject.
     */
    function _initialize(IRouter router_) internal {
        _initialize(_layoutStruct(), router_);
    }
    // end::_initialize(IRouter)[]

    // tag::_aerodromeRouter(Storage)[]
    /**
     * @dev Argumented version of _aerodromeRouter to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return router_ The stored IRouter (or zero if not initialized).
     */
    function _aerodromeRouter(Storage storage layoutStruct)
        internal
        view
        returns (IRouter router_)
    {
        return layoutStruct.router;
    }
    // end::_aerodromeRouter(Storage)[]

    // tag::_aerodromeRouter()[]
    /**
     * @dev Default version of _aerodromeRouter binding to the standard STORAGE_SLOT.
     * @return router_ The stored IRouter.
     */
    function _aerodromeRouter() internal view returns (IRouter router_) {
        return _aerodromeRouter(_layoutStruct());
    }
    // end::_aerodromeRouter()[]
}
// end::AerodromeRouterAwareRepo[]
