// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {Kernel} from "@crane/contracts/protocols/tokens/stable/olympus/v3/Kernel.sol";
import {OlympusMinter} from "@crane/contracts/protocols/tokens/stable/olympus/v3/modules/MINTR/OlympusMinter.sol";
import {OlympusRoles} from "@crane/contracts/protocols/tokens/stable/olympus/v3/modules/ROLES/OlympusRoles.sol";

// tag::OlympusKernelAwareRepo[]
/**
 * @title OlympusKernelAwareRepo - Storage for Olympus V3 Kernel (+ optional module) dependency injection.
 * @author Crane
 * @dev Dual overloads (parameterized Storage + default STORAGE_SLOT).
 *      Slot: `protocols.tokens.stable.olympus.v3.kernel.aware`.
 */
library OlympusKernelAwareRepo {
    // tag::STORAGE_SLOT[]
    /// @dev ERC1967-style slot: keccak256("protocols.tokens.stable.olympus.v3.kernel.aware") - 1.
    bytes32 internal constant STORAGE_SLOT =
        bytes32(uint256(keccak256(abi.encode("protocols.tokens.stable.olympus.v3.kernel.aware"))) - 1);
    // end::STORAGE_SLOT[]

    // tag::Storage[]
    struct Storage {
        Kernel kernel;
        address ohm;
        OlympusMinter mintr;
        OlympusRoles roles;
    }
    // end::Storage[]

    // tag::_layoutStruct(bytes32)[]
    function _layoutStruct(bytes32 slot_) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot_
        }
    }
    // end::_layoutStruct(bytes32)[]

    // tag::_layoutStruct()[]
    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }
    // end::_layoutStruct()[]

    // tag::_initialize(Storage-Kernel-address-OlympusMinter-OlympusRoles)[]
    function _initialize(
        Storage storage layoutStruct,
        Kernel kernel_,
        address ohm_,
        OlympusMinter mintr_,
        OlympusRoles roles_
    ) internal {
        layoutStruct.kernel = kernel_;
        layoutStruct.ohm = ohm_;
        layoutStruct.mintr = mintr_;
        layoutStruct.roles = roles_;
    }
    // end::_initialize(Storage-Kernel-address-OlympusMinter-OlympusRoles)[]

    // tag::_initialize(Kernel-address-OlympusMinter-OlympusRoles)[]
    function _initialize(
        Kernel kernel_,
        address ohm_,
        OlympusMinter mintr_,
        OlympusRoles roles_
    ) internal {
        _initialize(_layoutStruct(), kernel_, ohm_, mintr_, roles_);
    }
    // end::_initialize(Kernel-address-OlympusMinter-OlympusRoles)[]

    // tag::_kernel(Storage)[]
    function _kernel(Storage storage layoutStruct) internal view returns (Kernel) {
        return layoutStruct.kernel;
    }
    // end::_kernel(Storage)[]

    // tag::_kernel()[]
    function _kernel() internal view returns (Kernel) {
        return _kernel(_layoutStruct());
    }
    // end::_kernel()[]

    // tag::_ohm(Storage)[]
    function _ohm(Storage storage layoutStruct) internal view returns (address) {
        return layoutStruct.ohm;
    }
    // end::_ohm(Storage)[]

    // tag::_ohm()[]
    function _ohm() internal view returns (address) {
        return _ohm(_layoutStruct());
    }
    // end::_ohm()[]

    // tag::_mintr(Storage)[]
    function _mintr(Storage storage layoutStruct) internal view returns (OlympusMinter) {
        return layoutStruct.mintr;
    }
    // end::_mintr(Storage)[]

    // tag::_mintr()[]
    function _mintr() internal view returns (OlympusMinter) {
        return _mintr(_layoutStruct());
    }
    // end::_mintr()[]

    // tag::_roles(Storage)[]
    function _roles(Storage storage layoutStruct) internal view returns (OlympusRoles) {
        return layoutStruct.roles;
    }
    // end::_roles(Storage)[]

    // tag::_roles()[]
    function _roles() internal view returns (OlympusRoles) {
        return _roles(_layoutStruct());
    }
    // end::_roles()[]
}
// end::OlympusKernelAwareRepo[]
