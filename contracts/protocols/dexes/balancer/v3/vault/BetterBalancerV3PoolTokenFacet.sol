// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Events} from "@crane/contracts/interfaces/IERC20Events.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IERC20Permit} from "@crane/contracts/interfaces/IERC20Permit.sol";
import {IERC5267} from "@crane/contracts/interfaces/IERC5267.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {IRateProvider} from "@crane/contracts/interfaces/protocols/dexes/balancer/common/IRateProvider.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import "@crane/contracts/constants/Constants.sol";
import {IERC20Permit, IERC2612} from "@crane/contracts/interfaces/IERC2612.sol";
// import {BetterERC20} from "contracts/crane/token/ERC20/BetterERC20.sol";
// import {ERC20Storage} from "contracts/crane/token/ERC20/utils/ERC20Storage.sol";
// import {BetterERC20Permit} from "contracts/crane/token/ERC20/extensions/BetterERC20Permit.sol";
import {IBalancerPoolToken} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerPoolToken.sol";
// import {BetterBalancerV3PoolTokenStorage} from "./vault/utils/BetterBalancerV3PoolTokenStorage.sol";
import {
    BalancerV3VaultGuardModifiers
} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultGuardModifiers.sol";
// import {Create3AwareContract} from "contracts/crane/factories/create2/aware/Create3AwareContract.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {ECDSA} from "@crane/contracts/utils/cryptography/ECDSA.sol";
import {ERC20Repo} from "@crane/contracts/tokens/ERC20/ERC20Repo.sol";
import {ERC2612Repo} from "@crane/contracts/tokens/ERC2612/ERC2612Repo.sol";
import {EIP712Repo} from "@crane/contracts/utils/cryptography/EIP712/EIP712Repo.sol";
import {
    BalancerV3VaultAwareRepo
} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareRepo.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {
    BalancerV3VaultGuardModifiers
} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultGuardModifiers.sol";
import {EIP712Repo} from "@crane/contracts/utils/cryptography/EIP712/EIP712Repo.sol";

// tag::BalancerV3PoolTokenFacet[]
/**
 * @title BalancerV3PoolTokenFacet - Reusable Diamond facet implementing Balancer V3 BPT (pool token) surface.
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Exposes IERC20 / IERC20Metadata / IERC20Permit / IBalancerPoolToken / IRateProvider / IERC5267
 *         functionality for Balancer V3 pool tokens via delegation to the BalancerV3 vault.
 * @dev Extends BalancerV3VaultGuardModifiers; delegates to BalancerV3VaultAwareRepo, ERC20Repo,
 *      ERC2612Repo and EIP712Repo. Implements IFacet for Diamond composition, DFPkgs, loupes and registries.
 *      Note contract symbol is BalancerV3PoolTokenFacet (file name contains "Better" for legacy).
 * @custom:contractlistipfs
 */
contract BalancerV3PoolTokenFacet is
    BalancerV3VaultGuardModifiers,
    IBalancerPoolToken,
    IERC20,
    IERC20Metadata,
    IERC20Permit,
    IERC2612,
    IFacet
{
    using BetterEfficientHashLib for bytes;

    /* -------------------------------------------------------------------------- */
    /*                                   IFacet                                   */
    /* -------------------------------------------------------------------------- */

    // tag::facetName()[]
    /**
     * @inheritdoc IFacet
     * @notice Declares a canonical nonunique name for the exposing facet.
     * @return name_ The name of the facet.
     * @custom:selector 0x5b6f4d01
     * @custom:signature facetName()
     */
    function facetName() public pure returns (string memory name_) {
        return type(BalancerV3PoolTokenFacet).name;
    }

    // end::facetName()[]

    // tag::facetInterfaces()[]
    /**
     * @inheritdoc IFacet
     * @notice Declares the interfaces implemented by the exposing facet for use in a composing proxy.
     * @return interfaces The interface IDs implemented by the facet.
     * @custom:selector 0x2ea80826
     * @custom:signature facetInterfaces()
     */
    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](7);
        interfaces[0] = type(IERC20).interfaceId;
        interfaces[1] = type(IERC20Metadata).interfaceId;
        interfaces[2] = type(IERC20Metadata).interfaceId ^ type(IERC20).interfaceId;
        interfaces[3] = type(IERC20Permit).interfaceId;
        interfaces[4] = type(IERC5267).interfaceId;
        interfaces[5] = type(IRateProvider).interfaceId;
        interfaces[6] = type(IBalancerPoolToken).interfaceId;
    }

    // end::facetInterfaces()[]

    // tag::facetFuncs()[]
    /**
     * @inheritdoc IFacet
     * @notice Declares the function selectors implemented by the exposing facet for use in a composing proxy.
     * @return funcs The function selectors implemented by the facet.
     * @custom:selector 0x574a4cff
     * @custom:signature facetFuncs()
     */
    function facetFuncs() public pure virtual returns (bytes4[] memory funcs) {
        funcs = new bytes4[](16);

        funcs[0] = IERC20Metadata.name.selector;
        funcs[1] = IERC20Metadata.symbol.selector;
        funcs[2] = IERC20Metadata.decimals.selector;
        funcs[3] = IERC20.totalSupply.selector;
        funcs[4] = IERC20.balanceOf.selector;
        funcs[5] = IERC20.allowance.selector;
        funcs[6] = IERC20.approve.selector;
        funcs[7] = IERC20.transfer.selector;
        funcs[8] = IERC20.transferFrom.selector;

        funcs[9] = IERC5267.eip712Domain.selector;

        funcs[10] = IERC20Permit.permit.selector;
        funcs[11] = IERC20Permit.nonces.selector;
        funcs[12] = IERC20Permit.DOMAIN_SEPARATOR.selector;

        funcs[13] = IRateProvider.getRate.selector;
        funcs[14] = IBalancerPoolToken.emitTransfer.selector;
        funcs[15] = IBalancerPoolToken.emitApproval.selector;
    }

    // end::facetFuncs()[]

    // tag::facetMetadata()[]
    /**
     * @inheritdoc IFacet
     * @notice Declares comprehensive metadata about the exposing facet.
     * @dev Exposed to allow for single call retrieval of all facet metadata.
     * @return name_ The name of the facet.
     * @return interfaces The interface IDs implemented by the facet.
     * @return functions The function selectors implemented by the facet.
     * @custom:selector 0xf10d7a75
     * @custom:signature facetMetadata()
     */
    function facetMetadata()
        external
        pure
        returns (string memory name_, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name_ = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }

    // end::facetMetadata()[]

    /* -------------------------------------------------------------------------- */
    /*                          IERC20Metadata Functions                          */
    /* -------------------------------------------------------------------------- */

    // tag::name()[]
    /**
     * @inheritdoc IERC20Metadata
     * @notice Returns the name of the token.
     * @dev Delegates to ERC20Repo.
     * @return The token name.
     */
    function name() external view returns (string memory) {
        return ERC20Repo._name();
    }

    // end::name()[]

    // tag::symbol()[]
    /**
     * @inheritdoc IERC20Metadata
     * @notice Returns the symbol of the token.
     * @dev Delegates to ERC20Repo.
     * @return The token symbol.
     */
    function symbol() external view returns (string memory) {
        return ERC20Repo._symbol();
    }

    // end::symbol()[]

    // tag::decimals()[]
    /**
     * @inheritdoc IERC20Metadata
     * @notice Returns the number of decimals used to get user representation of a token amount.
     * @return The number of decimals (always 18 for BPT).
     */
    function decimals() external pure returns (uint8) {
        return 18;
    }

    // end::decimals()[]

    // tag::totalSupply()[]
    /**
     * @inheritdoc IERC20
     * @notice Returns the total supply of BPT for this pool (queried from Balancer V3 vault).
     * @return The total supply.
     */
    function totalSupply() external view returns (uint256) {
        return BalancerV3VaultAwareRepo._balancerV3Vault().totalSupply(address(this));
    }

    // end::totalSupply()[]

    // tag::balanceOf(address)[]
    /**
     * @inheritdoc IERC20
     * @notice Returns the balance of the specified account in this pool's BPT.
     * @param account The address to query the balance of.
     * @return The account balance.
     */
    function balanceOf(address account) external view returns (uint256) {
        return BalancerV3VaultAwareRepo._balancerV3Vault().balanceOf(address(this), account);
    }

    // end::balanceOf(address)[]

    // tag::transfer(address,uint256)[]
    function transfer(address recipient, uint256 amount) public virtual override(IERC20) returns (bool result) {
        BalancerV3VaultAwareRepo._balancerV3Vault().transfer(msg.sender, recipient, amount);
        return true;
    }

    // end::transfer(address,uint256)[]

    // tag::allowance(address,address)[]
    /**
     * @inheritdoc IERC20
     * @notice Returns the remaining allowance of a spender for an owner.
     * @param owner The address which owns the tokens.
     * @param spender The address which will spend the tokens.
     * @return The remaining allowance.
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return BalancerV3VaultAwareRepo._balancerV3Vault().allowance(address(this), owner, spender);
    }

    // end::allowance(address,address)[]

    // tag::approve(address,uint256)[]
    /**
     * @inheritdoc IERC20
     * @notice Sets the allowance for a spender.
     * @param spender The address which will spend the tokens.
     * @param amount The allowance amount.
     * @return success True on success.
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        BalancerV3VaultAwareRepo._balancerV3Vault().approve(msg.sender, spender, amount);
        return true;
    }

    // end::approve(address,uint256)[]

    // tag::transferFrom(address,address,uint256)[]
    function transferFrom(address sender, address recipient, uint256 amount)
        public
        virtual
        override(IERC20)
        returns (bool result)
    {
        BalancerV3VaultAwareRepo._balancerV3Vault().transferFrom(msg.sender, sender, recipient, amount);
        return true;
    }

    // end::transferFrom(address,address,uint256)[]

    // tag::emitTransfer(address,address,uint256)[]
    /// @dev Emit the Transfer event. This function can only be called by the MultiToken.
    function emitTransfer(address from, address to, uint256 amount) external onlyBalancerV3Vault {
        emit IERC20Events.Transfer(from, to, amount);
    }

    // end::emitTransfer(address,address,uint256)[]

    // tag::emitApproval(address,address,uint256)[]
    /// @dev Emit the Approval event. This function can only be called by the MultiToken.
    function emitApproval(address owner, address spender, uint256 amount) external onlyBalancerV3Vault {
        emit IERC20Events.Approval(owner, spender, amount);
    }

    // end::emitApproval(address,address,uint256)[]

    // tag::getRate()[]
    /**
     * @notice Get the BPT rate, which is defined as: pool invariant/total supply.
     * @dev The VaultExtension contract defines a default implementation (`getBptRate`) to calculate the rate
     * of any given pool, which should be sufficient in nearly all cases.
     *
     * @return rate Rate of the pool's BPT
     */
    function getRate() public view virtual returns (uint256) {
        return BalancerV3VaultAwareRepo._balancerV3Vault().getBptRate(address(this));
    }

    // end::getRate()[]

    // tag::permit(address,address,uint256,uint256,uint8,bytes32,bytes32)[]
    /**
     * @inheritdoc IERC20Permit
     * @notice Permits the spender to spend the owner's tokens via EIP-2612 signature.
     * @dev Reverts on expired deadline or invalid signer. Delegates approval to the Balancer V3 vault.
     * @param owner The token owner.
     * @param spender The token spender.
     * @param amount The allowance amount.
     * @param deadline The permit deadline.
     * @param v The recovery byte of the signature.
     * @param r Half of the ECDSA signature pair.
     * @param s Half of the ECDSA signature pair.
     */
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        public
        virtual
    {
        if (block.timestamp > deadline) {
            revert ERC2612ExpiredSignature(deadline);
        }

        // bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));
        bytes32 structHash =
            abi.encode(_PERMIT_TYPEHASH, owner, spender, amount, ERC2612Repo._useNonce(owner), deadline)._hash();

        bytes32 hash = EIP712Repo._hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        if (signer != owner) {
            revert ERC2612InvalidSigner(signer, owner);
        }

        BalancerV3VaultAwareRepo._balancerV3Vault().approve(owner, spender, amount);
    }

    // end::permit(address,address,uint256,uint256,uint8,bytes32,bytes32)[]

    // tag::nonces(address)[]
    /**
     * @inheritdoc IERC20Permit
     * @notice Returns the current nonce for the given owner for EIP-2612 permits.
     * @param owner The token owner address.
     * @return The current nonce.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return ERC2612Repo._nonces(owner);
    }

    // end::nonces(address)[]

    // tag::DOMAIN_SEPARATOR()[]
    /**
     * @inheritdoc IERC20Permit
     * @notice Returns the EIP-712 domain separator for this contract.
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     * @return The domain separator.
     */
    // solhint-disable-next-line func-name-mixedcase
    /// forge-lint: disable-next-line(mixed-case-function)
    function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
        return EIP712Repo._domainSeparatorV4();
    }

    // end::DOMAIN_SEPARATOR()[]

    // tag::eip712Domain()[]
    /**
     * @dev See {IERC-5267}.
     * @notice Returns the EIP-712 domain information.
     * @return fields The fields bitmap.
     * @return name_ The domain name.
     * @return version The domain version.
     * @return chainId The chain id.
     * @return verifyingContract The verifying contract address.
     * @return salt The domain salt (zero here).
     * @return extensions The extensions array (empty here).
     */
    function eip712Domain()
        public
        view
        virtual
        returns (
            bytes1 fields,
            string memory name_,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        EIP712Repo.Storage storage layoutStruct = EIP712Repo._layoutStruct();
        return (
            hex"0f", // 01111
            EIP712Repo._EIP712Name(layoutStruct),
            EIP712Repo._EIP712Version(layoutStruct),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }
    // end::eip712Domain()[]
}
// end::BalancerV3PoolTokenFacet[]
