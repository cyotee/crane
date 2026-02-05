// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/ERC20Permit.sol)
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

/// forge-lint: disable-next-line(unaliased-plain-import)
import "@crane/contracts/constants/Constants.sol";
import {ECDSA} from "@crane/contracts/utils/cryptography/ECDSA.sol";
import {ERC20Target} from "@crane/contracts/tokens/ERC20/ERC20Target.sol";
import {ERC5267Target} from "@crane/contracts/utils/cryptography/ERC5267/ERC5267Target.sol";
import {IERC20Permit, IERC2612} from "@crane/contracts/interfaces/IERC2612.sol";
import {ERC2612Repo} from "@crane/contracts/tokens/ERC2612/ERC2612Repo.sol";
import {EIP712Repo} from "@crane/contracts/utils/cryptography/EIP712/EIP712Repo.sol";
import {ERC20Repo} from "@crane/contracts/tokens/ERC20/ERC20Repo.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

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
contract ERC2612Target is IERC2612 {
    using BetterEfficientHashLib for bytes;

    // bytes32 private constant PERMIT_TYPEHASH
    //     = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @inheritdoc IERC20Permit
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        public
        virtual
    {
        if (block.timestamp > deadline) {
            revert ERC2612ExpiredSignature(deadline);
        }

        // bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));
        bytes32 structHash =
            abi.encode(_PERMIT_TYPEHASH, owner, spender, value, ERC2612Repo._useNonce(owner), deadline)._hash();

        bytes32 hash = EIP712Repo._hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        if (signer != owner) {
            revert ERC2612InvalidSigner(signer, owner);
        }

        ERC20Repo._approve(owner, spender, value);
    }

    /**
     * @inheritdoc IERC20Permit
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return ERC2612Repo._nonces(owner);
    }

    /**
     * @inheritdoc IERC20Permit
     */
    // solhint-disable-next-line func-name-mixedcase
    /// forge-lint: disable-next-line(mixed-case-function)
    function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
        return EIP712Repo._domainSeparatorV4();
    }
}
