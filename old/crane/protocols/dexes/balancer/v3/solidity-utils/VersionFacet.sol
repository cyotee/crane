// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import {IVersion} from "@balancer-labs/v3-interfaces/contracts/solidity-utils/helpers/IVersion.sol";
import {VersionStorage} from "contracts/crane/protocols/dexes/balancer/v3/solidity-utils/utils/VersionStorage.sol";
import {IFacet} from "contracts/crane/interfaces/IFacet.sol";

/**
 * @notice Retrieves a contract's version from storage.
 * @dev The version is set at deployment time and cannot be changed. It would be immutable, but immutable strings
 * are not yet supported.
 *
 * Contracts like factories and pools should have versions. These typically take the form of JSON strings containing
 * detailed information about the deployment. For instance:
 *
 * `{name: 'ChildChainGaugeFactory', version: 2, deployment: '20230316-child-chain-gauge-factory-v2'}`
 */
contract VersionFacet is VersionStorage, IVersion, IFacet {
    function facetInterfaces() external pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IVersion).interfaceId;
        return interfaces;
    }

    function facetFuncs() external pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](1);
        funcs[0] = IVersion.version.selector;
        return funcs;
    }

    /**
     * @notice Getter for the version.
     * @return version The stored contract version
     */
    function version() external view returns (string memory) {
        return _version();
    }
}
