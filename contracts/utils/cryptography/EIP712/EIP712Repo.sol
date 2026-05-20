// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {ShortString, ShortStrings} from "@crane/contracts/utils/ShortStrings.sol";

import {EIP712_TYPE_HASH} from "@crane/contracts/constants/Constants.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {MessageHashUtils} from "@crane/contracts/utils/cryptography/hash/MessageHashUtils.sol";

/// forge-lint: disable-next-line(pascal-case-struct)
struct EIP712Layout {
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

library EIP712Repo {
    using BetterEfficientHashLib for bytes;
    using EIP712Repo for bytes32;
    using ShortStrings for *;

    bytes32 internal constant STORAGE_SLOT = keccak256(abi.encode("eip.eip.712"));

    // tag::_layoutStruct[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layoutStruct_ A struct from a Layout library bound to the provided slot.
     */
    function _layoutStruct(bytes32 slot_) internal pure returns (EIP712Layout storage layoutStruct_) {
        assembly {
            layoutStruct_.slot := slot_
        }
    }
    // end::_layoutStruct[]

    function _layoutStruct() internal pure returns (EIP712Layout storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _initialize(EIP712Layout storage layoutStruct, string memory name, string memory version) internal {
        layoutStruct._name = name.toShortStringWithFallback(layoutStruct._nameFallback);
        layoutStruct._version = version.toShortStringWithFallback(layoutStruct._versionFallback);
        layoutStruct._hashedName = keccak256(bytes(name));
        layoutStruct._hashedVersion = keccak256(bytes(version));

        layoutStruct._cachedChainId = block.chainid;
        layoutStruct._cachedDomainSeparator = _buildDomainSeparator(layoutStruct);
        layoutStruct._cachedThis = address(this);
    }

    function _initialize(string memory name, string memory version) internal {
        _initialize(_layoutStruct(), name, version);
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4(EIP712Layout storage layoutStruct) internal view returns (bytes32) {
        if (address(this) == layoutStruct._cachedThis && block.chainid == layoutStruct._cachedChainId) {
            return layoutStruct._cachedDomainSeparator;
        } else {
            return _buildDomainSeparator(layoutStruct);
        }
    }

    function _domainSeparatorV4() internal view returns (bytes32) {
        return _domainSeparatorV4(_layoutStruct());
    }

    function _buildDomainSeparator(EIP712Layout storage layoutStruct) private view returns (bytes32) {
        // return keccak256(abi.encode(TYPE_HASH, layoutStruct._hashedName, layoutStruct._hashedVersion, block.chainid, address(this)));
        return
            abi.encode(EIP712_TYPE_HASH, layoutStruct._hashedName, layoutStruct._hashedVersion, block.chainid, address(this))
                ._hash();
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return _buildDomainSeparator(_layoutStruct());
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
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
    function _hashTypedDataV4(EIP712Layout storage layoutStruct, bytes32 structHash) internal view returns (bytes32) {
        return MessageHashUtils._toTypedDataHash(_domainSeparatorV4(layoutStruct), structHash);
    }

    function _hashTypedDataV4(bytes32 structHash) internal view returns (bytes32) {
        return _hashTypedDataV4(_layoutStruct(), structHash);
    }

    /**
     * @dev The name parameter for the EIP712 domain.
     *
     * NOTE: By default this function reads _name which is an immulayoutStruct value.
     * It only reads from storage if necessary (in case the value is too large to fit in a ShortString).
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _EIP712Name(EIP712Layout storage layoutStruct) internal view returns (string memory) {
        return layoutStruct._name.toStringWithFallback(layoutStruct._nameFallback);
    }

    function _EIP712Name() internal view returns (string memory) {
        return _EIP712Name(_layoutStruct());
    }

    /**
     * @dev The version parameter for the EIP712 domain.
     *
     * NOTE: By default this function reads _version which is an immulayoutStruct value.
     * It only reads from storage if necessary (in case the value is too large to fit in a ShortString).
     */
    // solhint-disable-next-line func-name-mixedcase
    /// forge-lint: disable-next-line(mixed-case-function)
    function _EIP712Version(EIP712Layout storage layoutStruct) internal view returns (string memory) {
        return layoutStruct._version.toStringWithFallback(layoutStruct._versionFallback);
    }

    function _EIP712Version() internal view returns (string memory) {
        return _EIP712Version(_layoutStruct());
    }
}
