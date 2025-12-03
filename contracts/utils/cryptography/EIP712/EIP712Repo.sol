// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {ShortString, ShortStrings} from "@openzeppelin/contracts/utils/ShortStrings.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {EIP721_TYPE_HASH} from "contracts/constants/Constants.sol";
import {BetterEfficientHashLib} from "contracts/utils/BetterEfficientHashLib.sol";
import {MessageHashUtils} from "contracts/utils/cryptography/hash/MessageHashUtils.sol";

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

    // tag::_layout[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(bytes32 slot_) internal pure returns (EIP712Layout storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }
    // end::_layout[]

    function _layout() internal pure returns (EIP712Layout storage layout) {
        return _layout(STORAGE_SLOT);
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
    function _initialize(EIP712Layout storage layout, string memory name, string memory version) internal {
        layout._name = name.toShortStringWithFallback(layout._nameFallback);
        layout._version = version.toShortStringWithFallback(layout._versionFallback);
        layout._hashedName = keccak256(bytes(name));
        layout._hashedVersion = keccak256(bytes(version));

        layout._cachedChainId = block.chainid;
        layout._cachedDomainSeparator = _buildDomainSeparator(layout);
        layout._cachedThis = address(this);
    }

    function _initialize(string memory name, string memory version) internal {
        _initialize(_layout(), name, version);
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4(EIP712Layout storage layout) internal view returns (bytes32) {
        if (address(this) == layout._cachedThis && block.chainid == layout._cachedChainId) {
            return layout._cachedDomainSeparator;
        } else {
            return _buildDomainSeparator(layout);
        }
    }

    function _domainSeparatorV4() internal view returns (bytes32) {
        _domainSeparatorV4(_layout());
    }

    function _buildDomainSeparator(EIP712Layout storage layout) private view returns (bytes32) {
        // return keccak256(abi.encode(TYPE_HASH, layout._hashedName, layout._hashedVersion, block.chainid, address(this)));
        return
            abi.encode(EIP721_TYPE_HASH, layout._hashedName, layout._hashedVersion, block.chainid, address(this))
                ._hash();
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return _buildDomainSeparator(_layout());
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
    function _hashTypedDataV4(EIP712Layout storage layout, bytes32 structHash) internal view returns (bytes32) {
        return MessageHashUtils._toTypedDataHash(_domainSeparatorV4(layout), structHash);
    }

    function _hashTypedDataV4(bytes32 structHash) internal view returns (bytes32) {
        return _hashTypedDataV4(_layout(), structHash);
    }

    /**
     * @dev The name parameter for the EIP712 domain.
     *
     * NOTE: By default this function reads _name which is an immulayout value.
     * It only reads from storage if necessary (in case the value is too large to fit in a ShortString).
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _EIP712Name(EIP712Layout storage layout) internal view returns (string memory) {
        return layout._name.toStringWithFallback(layout._nameFallback);
    }

    function _EIP712Name() internal view returns (string memory) {
        return _EIP712Name(_layout());
    }

    /**
     * @dev The version parameter for the EIP712 domain.
     *
     * NOTE: By default this function reads _version which is an immulayout value.
     * It only reads from storage if necessary (in case the value is too large to fit in a ShortString).
     */
    // solhint-disable-next-line func-name-mixedcase
    /// forge-lint: disable-next-line(mixed-case-function)
    function _EIP712Version(EIP712Layout storage layout) internal view returns (string memory) {
        return layout._version.toStringWithFallback(layout._versionFallback);
    }

    function _EIP712Version() internal view returns (string memory) {
        return _EIP712Version(_layout());
    }
}
