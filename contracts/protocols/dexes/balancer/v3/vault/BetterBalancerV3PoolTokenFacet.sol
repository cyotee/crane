// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC5267} from "@openzeppelin/contracts/interfaces/IERC5267.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {IRateProvider} from "@balancer-labs/v3-interfaces/contracts/solidity-utils/helpers/IRateProvider.sol";

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
import {BalancerV3VaultGuardModifiers} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultGuardModifiers.sol";
// import {Create3AwareContract} from "contracts/crane/factories/create2/aware/Create3AwareContract.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ERC20Repo} from "@crane/contracts/tokens/ERC20/ERC20Repo.sol";
import {ERC2612Repo} from "@crane/contracts/tokens/ERC2612/ERC2612Repo.sol";
import {EIP712Repo} from "@crane/contracts/utils/cryptography/EIP712/EIP712Repo.sol";
import {BalancerV3VaultAwareRepo} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareRepo.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {BalancerV3VaultGuardModifiers} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultGuardModifiers.sol";
import {EIP712Layout, EIP712Repo} from "@crane/contracts/utils/cryptography/EIP712/EIP712Repo.sol";

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

    function facetName() public pure returns (string memory name_) {
        return type(BalancerV3PoolTokenFacet).name;
    }

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

    function facetMetadata()
        external
        pure
        returns (string memory name_, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name_ = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
    /* -------------------------------------------------------------------------- */
    /*                          IERC20Metadata Functions                          */
    /* -------------------------------------------------------------------------- */

    /**
     * @inheritdoc IERC20Metadata
     */
    function name() external view returns (string memory) {
        return ERC20Repo._name();
    }

    /**
     * @inheritdoc IERC20Metadata
     */
    function symbol() external view returns (string memory) {
        return ERC20Repo._symbol();
    }

    /**
     * @inheritdoc IERC20Metadata
     */
    function decimals() external view returns (uint8) {
        return 18;
    }

    /**
     * @inheritdoc IERC20
     */
    function totalSupply() external view returns (uint256) {
        return BalancerV3VaultAwareRepo._balancerV3Vault().totalSupply(address(this));
    }

    /**
     * @inheritdoc IERC20
     */
    function balanceOf(address account) external view returns (uint256) {
        return BalancerV3VaultAwareRepo._balancerV3Vault().balanceOf(address(this), account);
    }

    // tag::transfer[]
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override(IERC20)
        returns (bool result)
    {
        BalancerV3VaultAwareRepo._balancerV3Vault().transfer(msg.sender, recipient, amount);
        return true;
    }
    // end::transfer[]

    /**
     * @inheritdoc IERC20
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return BalancerV3VaultAwareRepo._balancerV3Vault().allowance(address(this), owner, spender);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        BalancerV3VaultAwareRepo._balancerV3Vault().approve(msg.sender, spender, amount);
        return true;
    }

    // tag::transferFrom[]
    function transferFrom(address sender, address recipient, uint256 amount)
        public
        virtual
        override(IERC20)
        returns (bool result)
    {
        BalancerV3VaultAwareRepo._balancerV3Vault().transferFrom(msg.sender, sender, recipient, amount);
        return true;
    }
    // end::transferFrom[]

    /// @dev Emit the Transfer event. This function can only be called by the MultiToken.
    function emitTransfer(address from, address to, uint256 amount) external onlyBalancerV3Vault {
        emit IERC20.Transfer(from, to, amount);
    }

    /// @dev Emit the Approval event. This function can only be called by the MultiToken.
    function emitApproval(address owner, address spender, uint256 amount) external onlyBalancerV3Vault {
        emit IERC20.Approval(owner, spender, amount);
    }

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

    /**
     * @inheritdoc IERC20Permit
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

    /**
     * @dev See {IERC-5267}.
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
        EIP712Layout storage layout = EIP712Repo._layout();
        return (
            hex"0f", // 01111
            EIP712Repo._EIP712Name(layout),
            EIP712Repo._EIP712Version(layout),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }
}
