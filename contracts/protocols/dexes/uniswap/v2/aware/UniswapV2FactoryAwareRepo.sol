// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IUniswapV2Factory} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Factory.sol";

// tag::UniswapV2FactoryAwareRepo[]
/**
 * @title UniswapV2FactoryAwareRepo - Storage library for Uniswap V2 factory dependency injection (Aware pattern).
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Storage library (Repo) for holding a reference to the Uniswap V2 IUniswapV2Factory.
 * @dev Provides dual (parameterized + default) overloads for initialization and getter.
 * @dev Follows the gold standard from DeployedAddressesRepo, OperableRepo, MultiStepOwnableRepo, ERC2535Repo, Create3FactoryAwareRepo, DiamondPackageFactoryAwareRepo, BalancerV3VaultAwareRepo, CamelotV2FactoryAwareRepo
 *      (rich NatSpec, exact // tag:: / end:: include tags, @dev "The Storage struct to operate on.", ERC1967 slot).
 * @dev Used by Uniswap V2 protocol ports (services, test bases, etc.) for dependency injection of the Uniswap V2 factory.
 */
library UniswapV2FactoryAwareRepo {
    // tag::STORAGE_SLOT[]
    /**
     * @dev ERC1967-compliant storage slot.
     *      Computed as bytes32(uint256(keccak256(abi.encode("protocols.dexes.uniswap.v2.factory.aware"))) - 1).
     *      This follows the canonical pattern used by OperableRepo, ERC2535Repo, MultiStepOwnableRepo, DeployedAddressesRepo, Create3FactoryAwareRepo, DiamondPackageFactoryAwareRepo, BalancerV3VaultAwareRepo, CamelotV2FactoryAwareRepo and other
     *      gold-standard Repos for collision-resistant deterministic storage binding.
     */
    bytes32 internal constant STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("protocols.dexes.uniswap.v2.factory.aware"))) - 1);
    // end::STORAGE_SLOT[]

    // tag::Storage[]
    /**
     * @dev Standardized storage layout for uniswap v2 factory reference (Aware).
     *      factory: reference to IUniswapV2Factory.
     */
    struct Storage {
        IUniswapV2Factory factory;
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

    // tag::_initialize(Storage-IUniswapV2Factory)[]
    /**
     * @dev Argumented version of _initialize to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param factory_ The IUniswapV2Factory instance to inject.
     */
    function _initialize(Storage storage layoutStruct, IUniswapV2Factory factory_) internal {
        layoutStruct.factory = factory_;
    }
    // end::_initialize(Storage-IUniswapV2Factory)[]

    // tag::_initialize(IUniswapV2Factory)[]
    /**
     * @dev Default version of _initialize binding to the standard STORAGE_SLOT.
     * @param factory_ The IUniswapV2Factory instance to inject.
     */
    function _initialize(IUniswapV2Factory factory_) internal {
        _initialize(_layoutStruct(), factory_);
    }
    // end::_initialize(IUniswapV2Factory)[]

    // tag::_uniswapV2Factory(Storage)[]
    /**
     * @dev Argumented version of _uniswapV2Factory to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return factory_ The stored IUniswapV2Factory (or zero if not initialized).
     */
    function _uniswapV2Factory(Storage storage layoutStruct)
        internal
        view
        returns (IUniswapV2Factory factory_)
    {
        return layoutStruct.factory;
    }
    // end::_uniswapV2Factory(Storage)[]

    // tag::_uniswapV2Factory()[]
    /**
     * @dev Default version of _uniswapV2Factory binding to the standard STORAGE_SLOT.
     * @return factory_ The stored IUniswapV2Factory.
     */
    function _uniswapV2Factory() internal view returns (IUniswapV2Factory factory_) {
        return _uniswapV2Factory(_layoutStruct());
    }
    // end::_uniswapV2Factory()[]
}
// end::UniswapV2FactoryAwareRepo[]
