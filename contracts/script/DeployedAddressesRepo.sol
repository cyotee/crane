// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// import {Vm} from "forge-std/Vm.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "@crane/contracts/constants/FoundryConstants.sol";
import {AddressSet, AddressSetRepo} from "@crane/contracts/utils/collections/sets/AddressSetRepo.sol";

// tag::DeployedAddressesRepo[]
/**
 * @title DeployedAddressesRepo - Storage library for tracking deployed contract addresses by chain and instance ID.
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Storage library (Repo) implementing tracking of deployed addresses.
 * @dev Provides dual (parameterized + default) overloads for all accessors and mutators.
 * @dev Follows the gold standard from OperableRepo.sol, ERC2535Repo.sol, EIP712Repo.sol, ERC4626Repo.sol
 *      (rich NatSpec, exact // tag::Name(params)[] / end:: , @dev "The Storage struct to operate on.", ERC1967 STORAGE_SLOT + DEFAULT_SLOT form).
 * @dev STORAGE_SLOT naming uses hierarchical "crane.script.deployed.addresses".
 * @dev Intended for use in scripts and dev environments (e.g. via BetterScript/InitDev patterns) to
 *      record and retrieve addresses using deterministic instanceId (e.g. derived from salt or name).
 */
library DeployedAddressesRepo {
    using AddressSetRepo for AddressSet;
    /// forge-lint: disable-next-line(screaming-snake-case-const)
    // Vm constant vm = Vm(VM_ADDRESS);

    // tag::DEFAULT_SLOT[]
    /**
     * @dev ERC1967-compliant default storage slot.
     *      Computed as bytes32(uint256(keccak256(abi.encode("crane.script.deployed.addresses"))) - 1).
     *      This follows the exact ERC1967 pattern specified in PRD LR-6 (DEFAULT_SLOT form) and AGENTS.md.
     *      Used by canonical examples (FacetRegistryRepo, DiamondFactoryPackageRegistryRepo) and aliased for
     *      STORAGE_SLOT compatibility with OperableRepo, ERC2535Repo, EIP712Repo, ERC4626Repo, MultiStepOwnableRepo.
     */
    bytes32 internal constant DEFAULT_SLOT = bytes32(uint256(keccak256(abi.encode("crane.script.deployed.addresses"))) - 1);

    // end::DEFAULT_SLOT[]

    // tag::STORAGE_SLOT[]
    /**
     * @dev Alias providing STORAGE_SLOT = DEFAULT_SLOT.
     *      Preserves compatibility for all dual _layoutStruct and internal references while using canonical ERC1967 derivation.
     */
    bytes32 internal constant STORAGE_SLOT = DEFAULT_SLOT;
    // end::STORAGE_SLOT[]

    // tag::Storage[]
    /**
     * @dev Standardized storage layout for deployed addresses tracking.
     *      deployedAddresses: AddressSet of all registered deployed contract addresses.
     *      deployedAddressOfInstanceId: chainId -> instanceId (bytes32) -> deployed address.
     */
    struct Storage {
        AddressSet deployedAddresses;
        mapping(uint256 chainId => mapping(bytes32 instanceId => address deployedAddress)) deployedAddressOfInstanceId;
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
     * @dev Default _layoutStruct binding to the canonical ERC1967 form (STORAGE_SLOT aliasing DEFAULT_SLOT).
     * @return layoutStruct The Storage struct bound to STORAGE_SLOT (== DEFAULT_SLOT).
     */
    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }
    // end::_layoutStruct()[]

    // tag::_registerDeployedAddress(Storage-address-uint256-bytes32)[]
    /**
     * @dev Argumented (full) version of _registerDeployedAddress to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param deployedAddress_ The address of the deployed contract instance.
     * @param chainId_ The EVM chain ID.
     * @param instanceId_ Deterministic identifier for the deployed instance (e.g. salt hash or type-derived).
     */
    function _registerDeployedAddress(
        Storage storage layoutStruct,
        address deployedAddress_,
        uint256 chainId_,
        bytes32 instanceId_
    ) internal {
        layoutStruct.deployedAddresses._add(deployedAddress_);
        layoutStruct.deployedAddressOfInstanceId[chainId_][instanceId_] = deployedAddress_;
    }
    // end::_registerDeployedAddress(Storage-address-uint256-bytes32)[]

    // tag::_registerDeployedAddress(address-uint256-bytes32)[]
    /**
     * @dev Default version of _registerDeployedAddress (full params) binding to the standard STORAGE_SLOT (== DEFAULT_SLOT).
     * @param deployedAddress_ The address of the deployed contract instance.
     * @param chainId_ The EVM chain ID.
     * @param instanceId_ Deterministic identifier for the deployed instance.
     */
    function _registerDeployedAddress(address deployedAddress_, uint256 chainId_, bytes32 instanceId_) internal {
        _registerDeployedAddress(_layoutStruct(), deployedAddress_, chainId_, instanceId_);
    }
    // end::_registerDeployedAddress(address-uint256-bytes32)[]

    // tag::_registerDeployedAddress(Storage-address-bytes32)[]
    /**
     * @dev Argumented version of _registerDeployedAddress (chainId defaults to block.chainid) to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param deployedAddress_ The address of the deployed contract instance.
     * @param instanceId_ Deterministic identifier for the deployed instance.
     */
    function _registerDeployedAddress(Storage storage layoutStruct, address deployedAddress_, bytes32 instanceId_)
        internal
    {
        _registerDeployedAddress(layoutStruct, deployedAddress_, block.chainid, instanceId_);
    }
    // end::_registerDeployedAddress(Storage-address-bytes32)[]

    // tag::_registerDeployedAddress(address-bytes32)[]
    /**
     * @dev Default version of _registerDeployedAddress (chainId defaults to block.chainid) binding to the standard STORAGE_SLOT (== DEFAULT_SLOT).
     * @param deployedAddress_ The address of the deployed contract instance.
     * @param instanceId_ Deterministic identifier for the deployed instance.
     */
    function _registerDeployedAddress(address deployedAddress_, bytes32 instanceId_) internal {
        _registerDeployedAddress(_layoutStruct(), deployedAddress_, instanceId_);
    }
    // end::_registerDeployedAddress(address-bytes32)[]

    // tag::_deployedAddress(Storage-uint256-bytes32)[]
    /**
     * @dev Argumented (full) version of _deployedAddress to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param chainId The EVM chain ID.
     * @param instanceId_ Deterministic identifier for the deployed instance.
     * @return deployedAddress_ The registered address for the (chainId, instanceId_), or address(0) if none.
     */
    function _deployedAddress(Storage storage layoutStruct, uint256 chainId, bytes32 instanceId_)
        internal
        view
        returns (address)
    {
        return layoutStruct.deployedAddressOfInstanceId[chainId][instanceId_];
    }
    // end::_deployedAddress(Storage-uint256-bytes32)[]

    // tag::_deployedAddress(uint256-bytes32)[]
    /**
     * @dev Default version of _deployedAddress (full params) binding to the standard STORAGE_SLOT (== DEFAULT_SLOT).
     * @param chainId The EVM chain ID.
     * @param instanceId_ Deterministic identifier for the deployed instance.
     * @return deployedAddress_ The registered address for the (chainId, instanceId_), or address(0) if none.
     */
    function _deployedAddress(uint256 chainId, bytes32 instanceId_) internal view returns (address) {
        return _deployedAddress(_layoutStruct(), chainId, instanceId_);
    }
    // end::_deployedAddress(uint256-bytes32)[]

    // tag::_deployedAddress(Storage-bytes32)[]
    /**
     * @dev Argumented version of _deployedAddress (chainId defaults to block.chainid) to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param instanceId_ Deterministic identifier for the deployed instance.
     * @return deployedAddress_ The registered address for the (block.chainid, instanceId_), or address(0) if none.
     */
    function _deployedAddress(Storage storage layoutStruct, bytes32 instanceId_) internal view returns (address) {
        return _deployedAddress(layoutStruct, block.chainid, instanceId_);
    }
    // end::_deployedAddress(Storage-bytes32)[]

    // tag::_deployedAddress(bytes32)[]
    /**
     * @dev Default version of _deployedAddress (chainId defaults to block.chainid) binding to the standard STORAGE_SLOT (== DEFAULT_SLOT).
     * @param instanceId_ Deterministic identifier for the deployed instance.
     * @return deployedAddress_ The registered address for the (block.chainid, instanceId_), or address(0) if none.
     */
    function _deployedAddress(bytes32 instanceId_) internal view returns (address) {
        return _deployedAddress(_layoutStruct(), instanceId_);
    }
    // end::_deployedAddress(bytes32)[]
}
// end::DeployedAddressesRepo[]
