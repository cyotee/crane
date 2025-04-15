// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/ERC20Permit.sol)
pragma solidity ^0.8.20;

import {
    ECDSA
} from "../../../cryptography/ecdsa/ECDSA.sol";
import {
    ERC2612Storage
} from "../../../access/erc2612/storage/ERC2612Storage.sol";
import {
    IERC20Storage,
    ERC20Storage
} from "../../../tokens/erc20/storage/ERC20Storage.sol";
import {
    ERC20Target
} from "../../../tokens/erc20/targets/ERC20Target.sol";
import {
    ERC5267Target
} from "../../../access/erc5267/targets/ERC5267Target.sol";
import {
    IERC2612
} from "../../../access/erc2612/interfaces/IERC2612.sol";

/**
 * @title ERC2612Target - "Gasless" spending limit approval contract.
 * @author OpenZeppelin
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
contract ERC2612Target
is
ERC5267Target,
ERC20Target,
ERC2612Storage,
IERC2612
{
    bytes32 private constant PERMIT_TYPEHASH
        = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Permit deadline has expired.
     */
    error ERC2612ExpiredSignature(uint256 deadline);

    /**
     * @dev Mismatched signature.
     */
    error ERC2612InvalidSigner(address signer, address owner);

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    // constructor(string memory name_) EIP712(name_, "1") {}

    /**
     * @inheritdoc IERC2612
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (block.timestamp > deadline) {
            revert ERC2612ExpiredSignature(deadline);
        }

        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        if (signer != owner) {
            revert ERC2612InvalidSigner(signer, owner);
        }

        _approve(owner, spender, value);
    }

    /**
     * @inheritdoc IERC2612
     */
    function nonces(address owner) public view virtual override(IERC2612) returns (uint256) {
        return _permit().nonces[owner];
    }

    /**
     * @inheritdoc IERC2612
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
        return _domainSeparatorV4();
    }
}
