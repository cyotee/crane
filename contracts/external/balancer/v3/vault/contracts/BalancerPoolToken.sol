// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IERC20Permit} from "@crane/contracts/interfaces/IERC20Permit.sol";
import {ERC165} from "@crane/contracts/utils/introspection/ERC165.sol";
import {EIP712} from "@crane/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@crane/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Events} from "@crane/contracts/interfaces/IERC20Events.sol";
import {Nonces} from "@crane/contracts/utils/Nonces.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

import {IRateProvider} from "@crane/contracts/external/balancer/v3/interfaces/contracts/solidity-utils/helpers/IRateProvider.sol";
import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";

import {VaultGuard} from "./VaultGuard.sol";

/**
 * @notice `BalancerPoolToken` is a fully ERC20-compatible token to be used as the base contract for Balancer Pools.
 * @dev Vendored from Balancer V3 Vault.
 */
contract BalancerPoolToken is IERC20, IERC20Events, IERC20Metadata, IERC20Permit, IRateProvider, EIP712, Nonces, ERC165, VaultGuard {
    using BetterEfficientHashLib for bytes;
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @notice Operation failed due to an expired permit signature.
    error ERC2612ExpiredSignature(uint256 deadline);

    /// @notice Operation failed due to a non-matching signature.
    error ERC2612InvalidSigner(address signer, address owner);

    // EIP712 also defines _name.
    string private _bptName;
    string private _bptSymbol;

    constructor(IVault vault_, string memory bptName, string memory bptSymbol) EIP712(bptName, "1") VaultGuard(vault_) {
        _bptName = bptName;
        _bptSymbol = bptSymbol;
    }

    function name() external view returns (string memory) {
        return _bptName;
    }

    function symbol() external view returns (string memory) {
        return _bptSymbol;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _vault.totalSupply(address(this));
    }

    function getVault() public view returns (IVault) {
        return _vault;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _vault.balanceOf(address(this), account);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _vault.transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _vault.allowance(address(this), owner, spender);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _vault.approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        _vault.transferFrom(msg.sender, from, to, amount);
        return true;
    }

    function emitTransfer(address from, address to, uint256 amount) external onlyVault {
        emit Transfer(from, to, amount);
    }

    function emitApproval(address owner, address spender, uint256 amount) external onlyVault {
        emit Approval(owner, spender, amount);
    }

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp > deadline) {
            revert ERC2612ExpiredSignature(deadline);
        }

        // bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, _useNonce(owner), deadline));
        bytes32 structHash = abi.encode(PERMIT_TYPEHASH, owner, spender, amount, _useNonce(owner), deadline)._hash();
        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        if (signer != owner) {
            revert ERC2612InvalidSigner(signer, owner);
        }

        _vault.approve(owner, spender, amount);
    }

    function nonces(address owner) public view virtual override(IERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }

    function incrementNonce() external {
        _useNonce(msg.sender);
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
        return _domainSeparatorV4();
    }

    function getRate() public view virtual returns (uint256) {
        return getVault().getBptRate(address(this));
    }
}
