// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {ShortString, ShortStrings} from "@crane/contracts/utils/ShortStrings.sol";

import {EIP712_TYPE_HASH} from "@crane/contracts/constants/Constants.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {MessageHashUtils} from "@crane/contracts/utils/cryptography/hash/MessageHashUtils.sol";

// tag::EIP712Repo[]
/**
 * @title EIP712Repo - Storage library for EIP-712 domain separator and typed data hashing (for permits, meta-transactions, signatures in Diamond/upgradeable context).
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Storage library (Repo) for EIP-712 state: domain separator caches, hashed name/version, ShortString optimized name/version with fallbacks.
 * @dev Provides dual (parameterized + default) overloads for _initialize, _domainSeparatorV4, _hashTypedDataV4, _EIP712Name, _EIP712Version and supporting builders.
 * @dev Follows the gold standard from ERC4626Repo, Permit2AwareRepo, AerodromeRouterAwareRepo, DiamondPackageCallBackFactoryAwareRepo, Create3FactoryAwareRepo, OperableRepo, ERC2535Repo
 *      (rich NatSpec, exact // tag:: / end:: include tags, @dev "The Storage struct to operate on.", ERC1967 slot).
 * @dev Used by permit extensions (ERC20PermitDFPkg, ERC2612, ERC4626Permit), Balancer pool tokens, and EIP712-aware Diamond targets for structured data hashing.
 */
library EIP712Repo {
    using BetterEfficientHashLib for bytes;
    using EIP712Repo for bytes32;
    using ShortStrings for *;

    // tag::STORAGE_SLOT[]
    /**
     * @dev ERC1967-compliant storage slot.
     *      Computed as bytes32(uint256(keccak256(abi.encode("eip.eip.712"))) - 1).
     *      This follows the canonical pattern used by ERC2535Repo (eip.erc.2535), ERC4626Repo (eip.erc.4626), OperableRepo, MultiStepOwnableRepo,
     *      DeployedAddressesRepo, and other gold-standard Repos for collision-resistant deterministic storage binding.
     */
    bytes32 internal constant STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("eip.eip.712"))) - 1);

    // end::STORAGE_SLOT[]

    // tag::Storage[]
    /**
     * @dev Standardized storage layout for EIP-712 domain data.
     *      _cachedDomainSeparator: cached separator for current chain/this to avoid recompute.
     *      _cachedChainId: cached chainid for domain separator validity.
     *      _cachedThis: cached address(this) for domain separator validity.
     *      _hashedName: keccak256 of the EIP712 name.
     *      _hashedVersion: keccak256 of the EIP712 version.
     *      _name: ShortString optimized name (or fallback).
     *      _version: ShortString optimized version (or fallback).
     *      _nameFallback: fallback full string for name when >31 bytes.
     *      _versionFallback: fallback full string for version when >31 bytes.
     */
    struct Storage {
        bytes32 _cachedDomainSeparator;
        uint256 _cachedChainId;
        address _cachedThis;
        bytes32 _hashedName;
        bytes32 _hashedVersion;
        ShortString _name;
        ShortString _version;
        string _nameFallback;
        string _versionFallback;
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

    // tag::_initialize(Storage-string-string)[]
    /**
     * @dev Argumented version of _initialize to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param name The user readable name of the signing domain (EIP-712).
     * @param version The current major version of the signing domain (EIP-712).
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _initialize(Storage storage layoutStruct, string memory name, string memory version) internal {
        layoutStruct._name = name.toShortStringWithFallback(layoutStruct._nameFallback);
        layoutStruct._version = version.toShortStringWithFallback(layoutStruct._versionFallback);
        layoutStruct._hashedName = keccak256(bytes(name));
        layoutStruct._hashedVersion = keccak256(bytes(version));

        layoutStruct._cachedChainId = block.chainid;
        layoutStruct._cachedDomainSeparator = _buildDomainSeparator(layoutStruct);
        layoutStruct._cachedThis = address(this);
    }

    // end::_initialize(Storage-string-string)[]

    // tag::_initialize(string-string)[]
    /**
     * @dev Default version of _initialize binding to the standard STORAGE_SLOT.
     * @param name The user readable name of the signing domain (EIP-712).
     * @param version The current major version of the signing domain (EIP-712).
     */
    function _initialize(string memory name, string memory version) internal {
        _initialize(_layoutStruct(), name, version);
    }

    // end::_initialize(string-string)[]

    // tag::_domainSeparatorV4(Storage)[]
    /**
     * @dev Argumented version of _domainSeparatorV4 to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return The domain separator for the current chain (uses cache if valid).
     */
    function _domainSeparatorV4(Storage storage layoutStruct) internal view returns (bytes32) {
        if (address(this) == layoutStruct._cachedThis && block.chainid == layoutStruct._cachedChainId) {
            return layoutStruct._cachedDomainSeparator;
        } else {
            return _buildDomainSeparator(layoutStruct);
        }
    }

    // end::_domainSeparatorV4(Storage)[]

    // tag::_domainSeparatorV4()[]
    /**
     * @dev Default version of _domainSeparatorV4 binding to the standard STORAGE_SLOT.
     * @return The domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _domainSeparatorV4(_layoutStruct());
    }

    // end::_domainSeparatorV4()[]

    // tag::_buildDomainSeparator(Storage)[]
    /**
     * @dev Argumented version of _buildDomainSeparator (internal builder) allowing direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return The computed EIP712 domain separator.
     */
    function _buildDomainSeparator(Storage storage layoutStruct) private view returns (bytes32) {
        // return keccak256(abi.encode(TYPE_HASH, layoutStruct._hashedName, layoutStruct._hashedVersion, block.chainid, address(this)));
        return abi.encode(
                EIP712_TYPE_HASH, layoutStruct._hashedName, layoutStruct._hashedVersion, block.chainid, address(this)
            )._hash();
    }

    // end::_buildDomainSeparator(Storage)[]

    // tag::_buildDomainSeparator()[]
    /**
     * @dev Default version of _buildDomainSeparator binding to the standard STORAGE_SLOT.
     * @return The computed EIP712 domain separator.
     */
    function _buildDomainSeparator() private view returns (bytes32) {
        return _buildDomainSeparator(_layoutStruct());
    }

    // end::_buildDomainSeparator()[]

    // tag::_hashTypedDataV4(Storage-bytes32)[]
    /**
     * @dev Argumented version of _hashTypedDataV4 to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param structHash The already hashed struct (per EIP-712 hashStruct).
     * @return The fully encoded EIP712 typed data hash (digest) for signing/recover.
     */
    function _hashTypedDataV4(Storage storage layoutStruct, bytes32 structHash) internal view returns (bytes32) {
        return MessageHashUtils._toTypedDataHash(_domainSeparatorV4(layoutStruct), structHash);
    }

    // end::_hashTypedDataV4(Storage-bytes32)[]

    // tag::_hashTypedDataV4(bytes32)[]
    /**
     * @dev Default version of _hashTypedDataV4 binding to the standard STORAGE_SLOT.
     * @param structHash The already hashed struct (per EIP-712 hashStruct).
     * @return The fully encoded EIP712 typed data hash (digest) for signing/recover.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view returns (bytes32) {
        return _hashTypedDataV4(_layoutStruct(), structHash);
    }

    // end::_hashTypedDataV4(bytes32)[]

    // tag::_EIP712Name(Storage)[]
    /**
     * @dev Argumented version of _EIP712Name to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return The name parameter for the EIP712 domain.
     *
     * NOTE: By default this function reads _name which is an immutable value.
     * It only reads from storage if necessary (in case the value is too large to fit in a ShortString).
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _EIP712Name(Storage storage layoutStruct) internal view returns (string memory) {
        return layoutStruct._name.toStringWithFallback(layoutStruct._nameFallback);
    }

    // end::_EIP712Name(Storage)[]

    // tag::_EIP712Name()[]
    /**
     * @dev Default version of _EIP712Name binding to the standard STORAGE_SLOT.
     * @return The name parameter for the EIP712 domain.
     */
    function _EIP712Name() internal view returns (string memory) {
        return _EIP712Name(_layoutStruct());
    }

    // end::_EIP712Name()[]

    // tag::_EIP712Version(Storage)[]
    /**
     * @dev Argumented version of _EIP712Version to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return The version parameter for the EIP712 domain.
     *
     * NOTE: By default this function reads _version which is an immutable value.
     * It only reads from storage if necessary (in case the value is too large to fit in a ShortString).
     */
    // solhint-disable-next-line func-name-mixedcase
    /// forge-lint: disable-next-line(mixed-case-function)
    function _EIP712Version(Storage storage layoutStruct) internal view returns (string memory) {
        return layoutStruct._version.toStringWithFallback(layoutStruct._versionFallback);
    }

    // end::_EIP712Version(Storage)[]

    // tag::_EIP712Version()[]
    /**
     * @dev Default version of _EIP712Version binding to the standard STORAGE_SLOT.
     * @return The version parameter for the EIP712 domain.
     */
    function _EIP712Version() internal view returns (string memory) {
        return _EIP712Version(_layoutStruct());
    }
    // end::_EIP712Version()[]
}
// end::EIP712Repo[]
