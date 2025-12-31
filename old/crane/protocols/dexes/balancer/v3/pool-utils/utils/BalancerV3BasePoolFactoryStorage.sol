// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {IBasePoolFactory} from "@balancer-labs/v3-interfaces/contracts/vault/IBasePoolFactory.sol";
import {IRateProvider} from "@balancer-labs/v3-interfaces/contracts/solidity-utils/helpers/IRateProvider.sol";
import {
    LiquidityManagement,
    PoolRoleAccounts,
    TokenConfig,
    TokenType
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IDiamondFactoryPackage} from "contracts/crane/interfaces/IDiamondFactoryPackage.sol";
import {
    FactoryWidePauseWindowStorage
} from "contracts/crane/protocols/dexes/balancer/v3/solidity-utils/helpers/FactoryWidePauseWindowTarget.sol";
import {
    BalancerV3AuthenticationStorage
} from "contracts/crane/protocols/dexes/balancer/v3/solidity-utils/utils/BalancerV3AuthenticationStorage.sol";
import {
    BalancerV3VaultAwareStorage
} from "contracts/crane/protocols/dexes/balancer/v3/utils/BalancerV3VaultAwareStorage.sol";
import {AddressSet, AddressSetRepo} from "@crane/src/utils/collections/sets/AddressSetRepo.sol";

struct BalancerV3BasePoolFactoryLayout {
    AddressSet pools;
    bool isDisabled;
    // mapping(address pool => TokenConfig[] tokenConfigs) tokenConfigsOfPool;
    mapping(address pool => AddressSet tokens) tokensOfPool;
    mapping(address pool => mapping(address token => TokenType tokenType)) typeOfTokenOfPool;
    mapping(address pool => mapping(address token => address rateProvider)) rateProviderOfTokenOfPool;
    mapping(address pool => mapping(address token => bool paysYieldFees)) paysYieldFeesOfPool;
    mapping(address pool => address hooksContract) hooksContractOfPool;
}

library BalancerV3BasePoolFactoryRepo {
    // tag::_layout[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(bytes32 slot_) internal pure returns (BalancerV3BasePoolFactoryLayout storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }
    // end::_layout[]
}

contract BalancerV3BasePoolFactoryStorage is BalancerV3AuthenticationStorage, FactoryWidePauseWindowStorage {
    /* ------------------------------ LIBRARIES ----------------------------- */

    using BalancerV3BasePoolFactoryRepo for bytes32;

    using AddressSetRepo for AddressSet;

    /* ---------------------------------------------------------------------- */
    /*                                 STORAGE                                */
    /* ---------------------------------------------------------------------- */

    /* -------------------------- STORAGE CONSTANTS ------------------------- */

    bytes32 private constant LAYOUT_ID = keccak256(abi.encode(type(BalancerV3BasePoolFactoryRepo).name));
    bytes32 private constant STORAGE_RANGE_OFFSET = bytes32(uint256(LAYOUT_ID) - 1);
    bytes32 private constant STORAGE_RANGE = type(IBasePoolFactory).interfaceId;
    bytes32 private constant STORAGE_SLOT = (STORAGE_RANGE ^ STORAGE_RANGE_OFFSET);

    // tag::_balV3PoolFactory()[]
    /**
     * @dev internal hook for the default storage range used by this contract.
     * @return The default storage range used with repos.
     */
    function _balV3PoolFactory() internal pure virtual returns (BalancerV3BasePoolFactoryLayout storage) {
        return STORAGE_SLOT._layout();
    }
    // end::_balV3PoolFactory()[]

    /* ---------------------------------------------------------------------- */
    /*                             INITIALIZATION                             */
    /* ---------------------------------------------------------------------- */

    function _initBalancerV3BasePoolFactory(IVault vault_, bytes32 actionIdDisambiguator_, uint32 pauseWindowDuration_)
        internal
    {
        _initBalancerV3Authentication(vault_, actionIdDisambiguator_);
        _initFactoryWidePauseWindow(pauseWindowDuration_);
    }

    function _isPoolFromFactory(address pool_) internal view returns (bool) {
        return _balV3PoolFactory().pools._contains(pool_);
    }

    function _addPool(address pool_) internal {
        _balV3PoolFactory().pools._add(pool_);
    }

    function _getPoolCount() internal view returns (uint256) {
        return _balV3PoolFactory().pools._length();
    }

    function _getPools() internal view returns (address[] memory) {
        return _balV3PoolFactory().pools._values();
    }

    function _getPoolsInRange(uint256 start_, uint256 count_) internal view returns (address[] memory) {
        return _balV3PoolFactory().pools._range(start_, count_);
    }

    function _isDisabled() internal view returns (bool) {
        return _balV3PoolFactory().isDisabled;
    }

    function _ensureEnabled() internal view {
        if (_isDisabled()) {
            revert IBasePoolFactory.Disabled();
        }
    }

    function _getTokenConfigs(address pool_) internal view returns (TokenConfig[] memory tokenConfigs) {
        uint256 length = _balV3PoolFactory().tokensOfPool[pool_]._length();
        tokenConfigs = new TokenConfig[](length);
        for (uint256 cursor = 0; cursor < length; cursor++) {
            address token_ = _balV3PoolFactory().tokensOfPool[pool_]._index(cursor);
            tokenConfigs[cursor] = TokenConfig({
                token: IERC20(token_),
                rateProvider: IRateProvider(_balV3PoolFactory().rateProviderOfTokenOfPool[pool_][token_]),
                tokenType: _balV3PoolFactory().typeOfTokenOfPool[pool_][token_],
                paysYieldFees: _balV3PoolFactory().paysYieldFeesOfPool[pool_][token_]
            });
        }
    }

    function _setTokenConfigs(address pool_, TokenConfig[] memory tokenConfig_) internal {
        for (uint256 cursor = 0; cursor < tokenConfig_.length; cursor++) {
            _balV3PoolFactory().tokensOfPool[pool_]._add(address(tokenConfig_[cursor].token));
            _balV3PoolFactory().rateProviderOfTokenOfPool[pool_][address(tokenConfig_[cursor].token)] =
                address(tokenConfig_[cursor].rateProvider);
            _balV3PoolFactory().typeOfTokenOfPool[pool_][address(tokenConfig_[cursor].token)] =
            tokenConfig_[cursor].tokenType;
            _balV3PoolFactory().paysYieldFeesOfPool[pool_][address(tokenConfig_[cursor].token)] =
            tokenConfig_[cursor].paysYieldFees;
        }
    }

    function _getHooksContract(address pool_) internal view returns (address) {
        return _balV3PoolFactory().hooksContractOfPool[pool_];
    }

    function _setHooksContract(address pool_, address hooksContract_) internal {
        _balV3PoolFactory().hooksContractOfPool[pool_] = hooksContract_;
    }

    function _registerPoolWithBalV3Vault(
        IVault balV3Vault,
        address pool,
        TokenConfig[] memory tokens,
        uint256 swapFeePercentage,
        uint32 pauseWindowEndTime,
        bool protocolFeeExempt,
        PoolRoleAccounts memory roleAccounts,
        address poolHooksContract,
        LiquidityManagement memory liquidityManagement
    ) internal {
        // _addPool(pool);
        balV3Vault.registerPool(
            pool,
            tokens,
            swapFeePercentage,
            pauseWindowEndTime,
            protocolFeeExempt,
            roleAccounts,
            poolHooksContract,
            liquidityManagement
        );
    }
}
