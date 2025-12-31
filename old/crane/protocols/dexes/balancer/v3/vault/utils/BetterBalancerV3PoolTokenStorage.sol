// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {IBasePool} from "@balancer-labs/v3-interfaces/contracts/vault/IBasePool.sol";
import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {AddressSet, AddressSetRepo} from "@crane/src/utils/collections/sets/AddressSetRepo.sol";
import {BetterIERC20 as IERC20} from "contracts/crane/interfaces/BetterIERC20.sol";
import {ERC20PermitStorage} from "contracts/crane/token/ERC20/extensions/utils/ERC20PermitStorage.sol";
import {
    BalancerV3VaultAwareStorage
} from "contracts/crane/protocols/dexes/balancer/v3/utils/BalancerV3VaultAwareStorage.sol";

struct BetterBalancerV3PoolTokenLayout {
    // We ensure the values are sorted in ascending order to match Balancere V2 convention.
    AddressSet tokens;
}
// mapping(address => uint256 index) idxOfToken;
// mapping(uint256 index => address token) tokenOfIdx;

library BetterBalancerV3PoolTokenRepo {
    function _layout(bytes32 slot_) internal pure returns (BetterBalancerV3PoolTokenLayout storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }
}

contract BetterBalancerV3PoolTokenStorage is ERC20PermitStorage, BalancerV3VaultAwareStorage {
    using BetterBalancerV3PoolTokenRepo for bytes32;
    using AddressSetRepo for address[];
    using AddressSetRepo for AddressSet;

    /* ---------------------------------------------------------------------- */
    /*                                 STORAGE                                */
    /* ---------------------------------------------------------------------- */

    /* -------------------------- STORAGE CONSTANTS ------------------------- */

    bytes32 private constant LAYOUT_ID = keccak256(abi.encode(type(BetterBalancerV3PoolTokenRepo).name));
    bytes32 private constant STORAGE_RANGE_OFFSET = bytes32(uint256(LAYOUT_ID) - 1);
    bytes32 private constant STORAGE_RANGE =
    // We XOR the two interfaces because the current ERC20 standard no longer states the metadata is optional.
    // https://eips.ethereum.org/EIPS/eip-20
    type(IBasePool).interfaceId;
    bytes32 private constant STORAGE_SLOT = (STORAGE_RANGE ^ STORAGE_RANGE_OFFSET);

    // tag::_balV3VaultAware()[]
    /**
     * @dev internal hook for the default storage range used by this contract.
     * @return The default storage range used with repos.
     */
    function _balV3Pool() internal pure virtual returns (BetterBalancerV3PoolTokenLayout storage) {
        return STORAGE_SLOT._layout();
    }
    // end::_balV3VaultAware()[]

    error LocaclOperationNotAllowed();

    function _initBetterBalancerV3PoolToken(IVault balV3Vault_, string memory name) internal {
        _initBalancerV3VaultAware(balV3Vault_);
        // We could enforce sorting here.
        // But most inheritors will need to ensure soreting themselves, so we presume they will sort.
        // balV3PoolTokens_ = balV3PoolTokens_._sort();
        // _balV3Pool().tokens._add(balV3PoolTokens_);
        // for (uint256 cursor = 0; cursor < balV3PoolTokens_.length; cursor++) {
        //     _balV3Pool().tokens._add(balV3PoolTokens_[cursor]);
        //     // _balV3Pool().idxOfToken[balV3PoolTokens_[cursor]] = cursor;
        //     // _balV3Pool().tokenOfIdx[cursor] = balV3PoolTokens_[cursor];
        // }
        _initERC20Permit(name, "BetterB3PT", 18, "1");
    }

    function _initBetterBalancerV3PoolToken(IVault balV3Vault_, string memory name, address[] memory balV3PoolTokens_)
        internal
    {
        _initBalancerV3VaultAware(balV3Vault_);
        // We could enforce sorting here.
        // But most inheritors will need to ensure soreting themselves, so we presume they will sort.
        // balV3PoolTokens_ = balV3PoolTokens_._sort();
        _balV3Pool().tokens._add(balV3PoolTokens_);
        // for (uint256 cursor = 0; cursor < balV3PoolTokens_.length; cursor++) {
        //     _balV3Pool().tokens._add(balV3PoolTokens_[cursor]);
        //     // _balV3Pool().idxOfToken[balV3PoolTokens_[cursor]] = cursor;
        //     // _balV3Pool().tokenOfIdx[cursor] = balV3PoolTokens_[cursor];
        // }
        _initERC20Permit(name, "BetterB3PT", 18, "1");
    }

    function _addPoolToken(address token) internal {
        _balV3Pool().tokens._add(token);
    }

    function _poolTokens() internal view virtual returns (AddressSet storage) {
        return _balV3Pool().tokens;
    }

    function _balV3IndexOfToken(address token_) internal view returns (uint256) {
        return _balV3Pool().tokens._indexOf(token_);
    }

    function _tokenOfBalV3Index(uint256 index_) internal view returns (address) {
        return _balV3Pool().tokens._index(index_);
    }

    /* ---------------------------------------------------------------------- */
    /*                             ERC20 Override                             */
    /* ---------------------------------------------------------------------- */

    // tag::_decimals[]
    /**
     * @return precision Stated precision for determining a single unit of account.
     */
    function _decimals() internal view virtual override returns (uint8 precision) {
        return 18;
    }

    // end::_decimals[]

    // tag::_totalSupply[]
    /**
     * @notice query the total minted token supply
     * @return supply token supply.
     */
    function _totalSupply() internal view virtual override returns (uint256 supply) {
        return _balV3Vault().totalSupply(address(this));
    }
    // end::_totalSupply[]

    function _mint(
        uint256, // amount,
        address, // account,
        uint256 // currentSupply
    )
        internal
        virtual
        override
    {
        revert LocaclOperationNotAllowed();
    }

    function _mint(
        address, // account,
        uint256, // amount,
        uint256 // currentSupply
    )
        internal
        virtual
        override
    {
        revert LocaclOperationNotAllowed();
    }

    function _mint(
        uint256, // amount,
        address // account
    )
        internal
        virtual
        override
    {
        revert LocaclOperationNotAllowed();
    }

    function _mint(
        address, // account,
        uint256 // amount
    )
        internal
        virtual
        override
    {
        revert LocaclOperationNotAllowed();
    }

    function _burn(
        uint256, // amount,
        address, // account,
        uint256 // currentSupply
    )
        internal
        virtual
        override
    {
        revert LocaclOperationNotAllowed();
    }

    function _burn(
        address, // account,
        uint256, // amount,
        uint256 // currentSupply
    )
        internal
        virtual
        override
    {
        revert LocaclOperationNotAllowed();
    }

    function _burn(
        address, // account,
        uint256 // amount
    )
        internal
        virtual
        override
    {
        revert LocaclOperationNotAllowed();
    }

    function _burn(
        uint256, // amount,
        address // account
    )
        internal
        virtual
        override
    {
        revert LocaclOperationNotAllowed();
    }

    // tag::_balanceOf[]
    /**
     * @notice query the balance of an account
     * @param account_ The address of the account to query.
     * @return balance The balance of the account.
     */
    function _balanceOf(address account_) internal view virtual override returns (uint256 balance) {
        return _balV3Vault().balanceOf(address(this), account_);
    }
    // end::_balanceOf[]

    function _increaseBalanceOf(
        address, // account,
        uint256 // amount
    )
        internal
        virtual
        override
    {
        revert LocaclOperationNotAllowed();
    }

    function _decreaseBalanceOf(
        address, // account,
        uint256 // amount
    )
        internal
        virtual
        override
    {
        revert LocaclOperationNotAllowed();
    }

    function _allowance(address owner, address spender) internal view virtual override returns (uint256) {
        return _balV3Vault().allowance(address(this), owner, spender);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual override {
        _balV3Vault().approve(owner, spender, amount);
    }

    function _increaseAllowance(address owner, address spender, uint256 amount) internal virtual override {
        _balV3Vault().approve(owner, spender, _allowance(owner, spender) + amount);
    }

    function _decreaseAllowance(address owner, address spender, uint256 amount) internal virtual override {
        _balV3Vault().approve(owner, spender, _allowance(owner, spender) - amount);
    }

}
