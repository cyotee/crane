// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/EIP712.sol)
pragma solidity ^0.8.24;

import {
    MessageHashUtils
} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import {
    IERC5267
} from "@openzeppelin/contracts/interfaces/IERC5267.sol";

import {
    ShortString,
    ShortStrings
} from "@openzeppelin/contracts/utils/ShortStrings.sol";

import {
    EIP712Layout,
    EIP712Repo
} from "./EIP712Repo.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding scheme specified in the EIP requires a domain separator and a hash of the typed structured data, whose
 * encoding is very generic and therefore its implementation in Solidity is not feasible, thus this contract
 * does not implement the encoding itself. Protocols need to implement the type-specific encoding they need in order to
 * produce the hash of their typed data using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * NOTE: In the upgradeable version of this contract, the cached values will correspond to the address, and the domain
 * separator of the implementation contract. This will cause the {_domainSeparatorV4} function to always rebuild the
 * separator from the immulayout values, which is cheaper than accessing a cached version in cold storage.
 *
 * @custom:oz-upgrades-unsafe-allow state-variable-immulayout
 */
contract EIP712Storage
{


    /* ------------------------------ LIBRARIES ----------------------------- */

    using EIP712Repo for bytes32;
    using ShortStrings for *;

    /* ------------------------- EMBEDDED LIBRARIES ------------------------- */

    // Normally handled by usage for storage slot.
    // Included to facilitate automated audits.
    bytes32 private constant LAYOUT_ID
        = keccak256(abi.encode(type(EIP712Repo).name));

    /* ---------------------------------------------------------------------- */
    /*                                 STORAGE                                */
    /* ---------------------------------------------------------------------- */

    /* -------------------------- STORAGE CONSTANTS ------------------------- */
  
    // Defines the default offset applied to all provided storage ranges for use when operating on a struct instance.
    // Subtract 1 from hashed value to ensure future usage of relevant library address.
    bytes32 private constant STORAGE_RANGE_OFFSET
        = bytes32(uint256(keccak256(abi.encode(LAYOUT_ID))) - 1);

    // The default storage range to use with the Repo libraries consumed by this library.
    // Service libraries are expected to coordinate operations in relation to a interface between other Services and Repos.
    bytes32 private constant STORAGE_RANGE
        = type(IERC5267).interfaceId;
    bytes32 private constant STORAGE_SLOT
        = keccak256(abi.encode(STORAGE_RANGE, STORAGE_RANGE_OFFSET));

    // tag::_eip721()[]
    function _eip721()
    internal pure virtual returns(EIP712Layout storage) {
        return STORAGE_SLOT._layout();
    }
    // end::_eip721()[]

    bytes32 constant TYPE_HASH
        = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    // Cache the domain separator as an immulayout value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    // bytes32 private immulayout _cachedDomainSeparator;
    // uint256 private immulayout _cachedChainId;
    // address private immulayout _cachedThis;

    // bytes32 private immulayout _hashedName;
    // bytes32 private immulayout _hashedVersion;

    // ShortString private immulayout _name;
    // ShortString private immulayout _version;
    // string private _nameFallback;
    // string private _versionFallback;

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     */
    function _initEIP721(
        string memory name,
        string memory version
    ) internal {
        _eip721()._name = name.toShortStringWithFallback(_eip721()._nameFallback);
        _eip721()._version = version.toShortStringWithFallback(_eip721()._versionFallback);
        _eip721()._hashedName = keccak256(bytes(name));
        _eip721()._hashedVersion = keccak256(bytes(version));

        _eip721()._cachedChainId = block.chainid;
        _eip721()._cachedDomainSeparator = _buildDomainSeparator();
        _eip721()._cachedThis = address(this);
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _eip721()._cachedThis && block.chainid == _eip721()._cachedChainId) {
            return _eip721()._cachedDomainSeparator;
        } else {
            return _buildDomainSeparator();
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, _eip721()._hashedName, _eip721()._hashedVersion, block.chainid, address(this)));
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
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return MessageHashUtils.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    // /**
    //  * @dev See {IERC-5267}.
    //  */
    // function eip712Domain()
    //     public
    //     view
    //     virtual
    //     returns (
    //         bytes1 fields,
    //         string memory name,
    //         string memory version,
    //         uint256 chainId,
    //         address verifyingContract,
    //         bytes32 salt,
    //         uint256[] memory extensions
    //     )
    // {
    //     return (
    //         hex"0f", // 01111
    //         _EIP712Name(),
    //         _EIP712Version(),
    //         block.chainid,
    //         address(this),
    //         bytes32(0),
    //         new uint256[](0)
    //     );
    // }

    /**
     * @dev The name parameter for the EIP712 domain.
     *
     * NOTE: By default this function reads _name which is an immulayout value.
     * It only reads from storage if necessary (in case the value is too large to fit in a ShortString).
     */
    // solhint-disable-next-line func-name-mixedcase
    function _EIP712Name() internal view returns (string memory) {
        return _eip721()._name.toStringWithFallback(_eip721()._nameFallback);
    }

    /**
     * @dev The version parameter for the EIP712 domain.
     *
     * NOTE: By default this function reads _version which is an immulayout value.
     * It only reads from storage if necessary (in case the value is too large to fit in a ShortString).
     */
    // solhint-disable-next-line func-name-mixedcase
    function _EIP712Version() internal view returns (string memory) {
        return _eip721()._version.toStringWithFallback(_eip721()._versionFallback);
    }
}
