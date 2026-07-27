// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {IMorpho} from "@crane/contracts/external/morpho/blue/interfaces/IMorpho.sol";

// tag::MorphoBlueAwareRepo[]
/**
 * @title MorphoBlueAwareRepo - Storage for Morpho Blue singleton (+ optional IRM/oracle factory) dependency injection.
 * @author Crane
 * @dev Dual overloads (parameterized Storage + default STORAGE_SLOT). Slot: `protocols.lending.morpho.blue.aware`.
 */
library MorphoBlueAwareRepo {
    // tag::STORAGE_SLOT[]
    /// @dev ERC1967-style slot: keccak256("protocols.lending.morpho.blue.aware") - 1.
    bytes32 internal constant STORAGE_SLOT =
        bytes32(uint256(keccak256(abi.encode("protocols.lending.morpho.blue.aware"))) - 1);
    // end::STORAGE_SLOT[]

    // tag::Storage[]
    struct Storage {
        IMorpho morpho;
        address adaptiveCurveIrm;
        address chainlinkOracleV2Factory;
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

    // tag::_initialize(Storage-IMorpho-address-address)[]
    function _initialize(
        Storage storage layoutStruct,
        IMorpho morpho_,
        address adaptiveCurveIrm_,
        address chainlinkOracleV2Factory_
    ) internal {
        layoutStruct.morpho = morpho_;
        layoutStruct.adaptiveCurveIrm = adaptiveCurveIrm_;
        layoutStruct.chainlinkOracleV2Factory = chainlinkOracleV2Factory_;
    }
    // end::_initialize(Storage-IMorpho-address-address)[]

    // tag::_initialize(IMorpho-address-address)[]
    function _initialize(IMorpho morpho_, address adaptiveCurveIrm_, address chainlinkOracleV2Factory_) internal {
        _initialize(_layoutStruct(), morpho_, adaptiveCurveIrm_, chainlinkOracleV2Factory_);
    }
    // end::_initialize(IMorpho-address-address)[]

    // tag::_morpho(Storage)[]
    function _morpho(Storage storage layoutStruct) internal view returns (IMorpho) {
        return layoutStruct.morpho;
    }
    // end::_morpho(Storage)[]

    // tag::_morpho()[]
    function _morpho() internal view returns (IMorpho) {
        return _morpho(_layoutStruct());
    }
    // end::_morpho()[]

    // tag::_adaptiveCurveIrm(Storage)[]
    function _adaptiveCurveIrm(Storage storage layoutStruct) internal view returns (address) {
        return layoutStruct.adaptiveCurveIrm;
    }
    // end::_adaptiveCurveIrm(Storage)[]

    // tag::_adaptiveCurveIrm()[]
    function _adaptiveCurveIrm() internal view returns (address) {
        return _adaptiveCurveIrm(_layoutStruct());
    }
    // end::_adaptiveCurveIrm()[]

    // tag::_chainlinkOracleV2Factory(Storage)[]
    function _chainlinkOracleV2Factory(Storage storage layoutStruct) internal view returns (address) {
        return layoutStruct.chainlinkOracleV2Factory;
    }
    // end::_chainlinkOracleV2Factory(Storage)[]

    // tag::_chainlinkOracleV2Factory()[]
    function _chainlinkOracleV2Factory() internal view returns (address) {
        return _chainlinkOracleV2Factory(_layoutStruct());
    }
    // end::_chainlinkOracleV2Factory()[]
}
// end::MorphoBlueAwareRepo[]
