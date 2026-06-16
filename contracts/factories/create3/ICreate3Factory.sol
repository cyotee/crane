// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";

// tag::ICreate3Factory[]
/// @title ICreate3Factory
/// @author cyotee doge <doge.cyotee>
/// @notice CREATE3-based factory for deterministic deployment of facets, packages, and arbitrary contracts.
/// @dev Primary entry point for one-time logic deployment. Combined with DiamondPackageCallBackFactory
///      for cheap reproducible Diamond proxies.
/// @notice Supports plain CREATE3 + a callback variant that lets the deployed contract receive factory context.
interface ICreate3Factory {
    /* -------------------------------------------------------------------------- */
    /*                              Diamond Integration                           */
    /* -------------------------------------------------------------------------- */

    // tag::diamondPackageFactory[]
    /// @notice Returns the DiamondPackageCallBackFactory wired to this Create3Factory.
    /// @return factory The callback factory used for DFPkg-based Diamond deployments.
    /// @custom:signature diamondPackageFactory()
    /// @custom:selector 0x0fe96d13
    function diamondPackageFactory() external view returns (IDiamondPackageCallBackFactory factory);
    // end::diamondPackageFactory[]

    // tag::setDiamondPackageFactory[]
    /// @notice Wires (or updates) the DiamondPackageCallBackFactory.
    /// @param diamondPackageFactory_ Address of the Diamond callback factory.
    /// @return success True on success.
    /// @custom:signature setDiamondPackageFactory(address)
    /// @custom:selector 0x1cdca5df
    function setDiamondPackageFactory(IDiamondPackageCallBackFactory diamondPackageFactory_) external returns (bool);
    // end::setDiamondPackageFactory[]

    /* -------------------------------------------------------------------------- */
    /*                              Core CREATE3 API                              */
    /* -------------------------------------------------------------------------- */

    // tag::create3[]
    /// @notice Deploys a contract deterministically using CREATE3.
    /// @dev Salt is usually derived as `abi.encode(type(X).name)._hash()`.
    /// @param initCode The creation bytecode (optionally with constructor args appended).
    /// @param salt CREATE3 salt.
    /// @return proxy The deterministic address of the deployed contract.
    /// @custom:signature create3(bytes,bytes32)
    /// @custom:selector 0xa7b62a7f
    function create3(bytes memory initCode, bytes32 salt) external returns (address proxy);
    // end::create3[]

    // tag::create3WithArgs[]
    /// @notice Variant that performs a callback after deployment so the new contract can self-initialize
    ///         using factory-provided context (used by some DFPkgs and aware contracts).
    /// @param initCode Creation bytecode.
    /// @param initData_ Data passed to the deployed contract via callback.
    /// @param salt CREATE3 salt.
    /// @return proxy Deterministic deployed address.
    /// @custom:signature create3WithArgs(bytes,bytes,bytes32)
    /// @custom:selector 0x1f7fe4db
    function create3WithArgs(bytes memory initCode, bytes memory initData_, bytes32 salt)
        external
        returns (address proxy);
    // end::create3WithArgs[]

    /* -------------------------------------------------------------------------- */
    /*                    Convenience / Registry Helpers (historical)             */
    /* -------------------------------------------------------------------------- */

    // Note: Registry methods are currently commented in the interface. The practical path for most
    // consumers is to use Create3Factory + FactoryService + DFPkgs, which auto-register via the
    // factories. The low-level registry functions may be restored or exposed via separate registry facets.

    // function registerFacet(...)
    // function registerPackage(...)
    // ... query helpers ...
}
// end::ICreate3Factory[]
