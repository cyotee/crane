// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {
    Kernel,
    Module,
    Policy,
    Actions,
    Keycode,
    toKeycode
} from "@crane/contracts/protocols/tokens/stable/olympus/v3/Kernel.sol";
import {OlympusMinter} from "@crane/contracts/protocols/tokens/stable/olympus/v3/modules/MINTR/OlympusMinter.sol";
import {OlympusRoles} from "@crane/contracts/protocols/tokens/stable/olympus/v3/modules/ROLES/OlympusRoles.sol";
import {RolesAdmin} from "@crane/contracts/protocols/tokens/stable/olympus/v3/policies/RolesAdmin.sol";
import {Minter} from "@crane/contracts/protocols/tokens/stable/olympus/v3/policies/Minter.sol";

// tag::OlympusKernelService[]
/**
 * @title OlympusKernelService - Stateless helpers for Olympus V3 Kernel bootstrap and core policy ops.
 * @author Crane
 * @dev Internal API (`_`). Does not bypass Kernel permissions — encodes correct executor / admin call paths only.
 *      Structs avoid stack-too-deep.
 */
library OlympusKernelService {
    // tag::InstallModuleParams[]
    struct InstallModuleParams {
        Kernel kernel;
        Module module;
    }
    // end::InstallModuleParams[]

    // tag::ActivatePolicyParams[]
    struct ActivatePolicyParams {
        Kernel kernel;
        Policy policy;
    }
    // end::ActivatePolicyParams[]

    // tag::GrantRoleParams[]
    struct GrantRoleParams {
        RolesAdmin rolesAdmin;
        bytes32 role;
        address wallet;
    }
    // end::GrantRoleParams[]

    // tag::MintParams[]
    struct MintParams {
        Minter minterPolicy;
        address to;
        uint256 amount;
        bytes32 category;
    }
    // end::MintParams[]

    // tag::_installModule(InstallModuleParams)[]
    /**
     * @notice Install a module via Kernel (caller must be Kernel executor).
     * @custom:signature _installModule((address,address))
     */
    function _installModule(InstallModuleParams memory params) internal {
        params.kernel.executeAction(Actions.InstallModule, address(params.module));
    }
    // end::_installModule(InstallModuleParams)[]

    // tag::_installModule(Kernel-Module)[]
    function _installModule(Kernel kernel_, Module module_) internal {
        _installModule(InstallModuleParams({kernel: kernel_, module: module_}));
    }
    // end::_installModule(Kernel-Module)[]

    // tag::_activatePolicy(ActivatePolicyParams)[]
    /**
     * @notice Activate a policy via Kernel (caller must be Kernel executor).
     * @custom:signature _activatePolicy((address,address))
     */
    function _activatePolicy(ActivatePolicyParams memory params) internal {
        params.kernel.executeAction(Actions.ActivatePolicy, address(params.policy));
    }
    // end::_activatePolicy(ActivatePolicyParams)[]

    // tag::_activatePolicy(Kernel-Policy)[]
    function _activatePolicy(Kernel kernel_, Policy policy_) internal {
        _activatePolicy(ActivatePolicyParams({kernel: kernel_, policy: policy_}));
    }
    // end::_activatePolicy(Kernel-Policy)[]

    // tag::_getModule(Kernel-Keycode)[]
    /**
     * @notice Resolve module address for a keycode.
     * @custom:signature _getModule(address,bytes5)
     */
    function _getModule(Kernel kernel_, Keycode keycode_) internal view returns (Module) {
        return kernel_.getModuleForKeycode(keycode_);
    }
    // end::_getModule(Kernel-Keycode)[]

    // tag::_getModule(Kernel-string)[]
    function _getModule(Kernel kernel_, string memory keycodeStr_) internal view returns (Module) {
        return _getModule(kernel_, toKeycode(bytes5(bytes(keycodeStr_))));
    }
    // end::_getModule(Kernel-string)[]

    // tag::_mintr(Kernel)[]
    function _mintr(Kernel kernel_) internal view returns (OlympusMinter) {
        return OlympusMinter(address(_getModule(kernel_, toKeycode("MINTR"))));
    }
    // end::_mintr(Kernel)[]

    // tag::_roles(Kernel)[]
    function _roles(Kernel kernel_) internal view returns (OlympusRoles) {
        return OlympusRoles(address(_getModule(kernel_, toKeycode("ROLES"))));
    }
    // end::_roles(Kernel)[]

    // tag::_grantRole(GrantRoleParams)[]
    /**
     * @notice Grant a ROLES role via RolesAdmin (caller must be RolesAdmin admin).
     * @custom:signature _grantRole((address,bytes32,address))
     */
    function _grantRole(GrantRoleParams memory params) internal {
        params.rolesAdmin.grantRole(params.role, params.wallet);
    }
    // end::_grantRole(GrantRoleParams)[]

    // tag::_grantRole(RolesAdmin-bytes32-address)[]
    function _grantRole(RolesAdmin rolesAdmin_, bytes32 role_, address wallet_) internal {
        _grantRole(GrantRoleParams({rolesAdmin: rolesAdmin_, role: role_, wallet: wallet_}));
    }
    // end::_grantRole(RolesAdmin-bytes32-address)[]

    // tag::_addMintCategory(Minter-bytes32)[]
    /**
     * @notice Approve a mint category on the Minter policy (caller must have minter_admin role).
     * @custom:signature _addMintCategory(address,bytes32)
     */
    function _addMintCategory(Minter minterPolicy_, bytes32 category_) internal {
        minterPolicy_.addCategory(category_);
    }
    // end::_addMintCategory(Minter-bytes32)[]

    // tag::_mint(MintParams)[]
    /**
     * @notice Mint OHM via the Minter policy (caller must have minter_admin; category approved).
     * @custom:signature _mint((address,address,uint256,bytes32))
     */
    function _mint(MintParams memory params) internal {
        params.minterPolicy.mint(params.to, params.amount, params.category);
    }
    // end::_mint(MintParams)[]

    // tag::_mint(Minter-address-uint256-bytes32)[]
    function _mint(Minter minterPolicy_, address to_, uint256 amount_, bytes32 category_) internal {
        _mint(MintParams({minterPolicy: minterPolicy_, to: to_, amount: amount_, category: category_}));
    }
    // end::_mint(Minter-address-uint256-bytes32)[]
}
// end::OlympusKernelService[]
