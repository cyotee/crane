// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.30;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

/**
 * @dev Minimal interface declarations for interfaceId computation ONLY.
 *      Mirrors the public surface of the real interfaces for accurate type().interfaceId.
 *      Kept in sync with real interfaces; used exclusively by this verification script.
 */
interface IFacet {
    function facetName() external view returns (string memory);
    function facetInterfaces() external view returns (bytes4[] memory);
    function facetFuncs() external view returns (bytes4[] memory);
    function facetMetadata() external view returns (string memory, bytes4[] memory, bytes4[] memory);
}

interface IDiamondFactoryPackage {
    function packageName() external view returns (string memory);
    function facetInterfaces() external view returns (bytes4[] memory);
    function facetAddresses() external view returns (address[] memory);
    function packageMetadata() external view returns (string memory, bytes4[] memory, address[] memory, bytes memory);
    function facetCuts() external view returns (bytes memory); // simplified; real returns struct[]
    function diamondConfig() external view returns (bytes memory);
    function calcSalt(bytes memory pkgArgs) external view returns (bytes32);
    function processArgs(bytes memory pkgArgs) external view returns (bytes memory);
    function updatePkg(address account, bytes memory updateArgs) external;
    function initAccount(bytes memory initArgs) external;
    function postDeploy(address account) external returns (bool);
}

interface IDiamondPackageCallBackFactory {
    function PROXY_INIT_HASH() external view returns (bytes32);
    function ERC165_FACET() external view returns (address);
    function DIAMOND_LOUPE_FACET() external view returns (address);
    function POST_DEPLOY_HOOK_FACET() external view returns (address);
    function pkgOfAccount(address account) external view returns (address);
    function pkgArgsOfAccount(address account) external view returns (bytes memory);
    function calcAddress(address pkg, bytes memory pkgArgs) external view returns (address);
    function deploy(address pkg, bytes memory pkgArgs) external returns (address account);
    function initAccount(address account, bytes memory initArgs) external;
}

interface ICreate3Factory {
    function diamondPackageFactory() external view returns (address);
    function setDiamondPackageFactory(address factory) external;
    function create3(bytes memory creationCode, bytes32 salt) external returns (address);
    function create3WithArgs(bytes memory creationCode, bytes memory constructorArgs, bytes32 salt)
        external
        returns (address);
}

interface IOperable {
    function isOperator(address operator) external view returns (bool);
    function isOperatorFor(bytes4 func, address operator) external view returns (bool);
    function setOperator(address operator, bool status) external;
    function setOperatorFor(bytes4 func, address operator, bool status) external;
}

interface IMultiStepOwnable {
    function initiateOwnershipTransfer(address newOwner) external;
    function confirmOwnershipTransfer(address newOwner) external;
    function cancelPendingOwnershipTransfer() external;
    function acceptOwnershipTransfer() external;
    function owner() external view returns (address);
    function pendingOwner() external view returns (address);
    function preConfirmedOwner() external view returns (address);
    function getOwnershipTransferBuffer() external view returns (uint256);
}

/**
 * @title ComputeNatSpecValues
 * @notice Dedicated Foundry Script per LR-1 to authoritatively compute
 *         @custom:selector / @custom:interfaceid / @custom:topiczero values
 *         using the Solidity compiler (type(I).interfaceId and keccak inside compiled code).
 *         Run with: forge script scripts/foundry/ComputeNatSpecValues.s.sol --sig "run()" -vvv
 *         (Values appear in console logs. Use for populating CENTRALLY_COMPUTED_NATSPEC_VALUES.md and sources.)
 * @dev This replaces ad-hoc `cast` usage for verification/central population. Re-runnable in CI/release.
 * @custom:signature run()
 */
contract ComputeNatSpecValues is Script {
    /* -------------------------------------------------------------------------- */
    /*                                 Constants                                  */
    /* -------------------------------------------------------------------------- */

    // tag::ComputeNatSpecValues[]
    /**
     * @notice Computes and logs NatSpec custom tag values for core interfaces and symbols.
     * @dev Interface IDs use the compiler's type(I).interfaceId (XOR of function selectors).
     *      Selectors and topic0 use keccak256 in Solidity for exact compiler match.
     */
    function run() public pure {
        console2.log("=== Crane NatSpec Values (Foundry Script - LR-1) ===");
        console2.log("Date: use current; regenerate when interfaces change");
        console2.log("");

        // --- Interface IDs (preferred compiler method) ---
        console2.log("Interface IDs:");
        console2.log("IFacet: ");
        console2.logBytes4(type(IFacet).interfaceId);
        console2.log("IDiamondFactoryPackage: ");
        console2.logBytes4(type(IDiamondFactoryPackage).interfaceId);
        console2.log("IDiamondPackageCallBackFactory: ");
        console2.logBytes4(type(IDiamondPackageCallBackFactory).interfaceId);
        console2.log("ICreate3Factory: ");
        console2.logBytes4(type(ICreate3Factory).interfaceId);
        console2.log("IOperable: ");
        console2.logBytes4(type(IOperable).interfaceId);
        console2.log("IMultiStepOwnable: ");
        console2.logBytes4(type(IMultiStepOwnable).interfaceId);
        console2.log("");

        // --- Common Function Selectors (via keccak in script for reproducibility) ---
        console2.log("Function selectors:");
        _logSelector("facetName()", type(IFacet).interfaceId); // example, but actually use the interface's
        _logSelector("facetInterfaces()", type(IFacet).interfaceId);
        _logSelector("facetFuncs()", type(IFacet).interfaceId);
        _logSelector("facetMetadata()", type(IFacet).interfaceId);
        _logSelector("supportsInterface(bytes4)", type(IFacet).interfaceId); // note: this is IERC165

        _logSelector("packageName()", type(IDiamondFactoryPackage).interfaceId);
        _logSelector("facetInterfaces()", type(IDiamondFactoryPackage).interfaceId);
        _logSelector("facetAddresses()", type(IDiamondFactoryPackage).interfaceId);
        _logSelector("packageMetadata()", type(IDiamondFactoryPackage).interfaceId);
        _logSelector("facetCuts()", type(IDiamondFactoryPackage).interfaceId);
        _logSelector("diamondConfig()", type(IDiamondFactoryPackage).interfaceId);
        _logSelector("calcSalt(bytes)", type(IDiamondFactoryPackage).interfaceId);
        _logSelector("processArgs(bytes)", type(IDiamondFactoryPackage).interfaceId);
        _logSelector("updatePkg(address,bytes)", type(IDiamondFactoryPackage).interfaceId);
        _logSelector("initAccount(bytes)", type(IDiamondFactoryPackage).interfaceId);
        _logSelector("postDeploy(address)", type(IDiamondFactoryPackage).interfaceId);

        _logSelector("deploy(address,bytes)", type(IDiamondPackageCallBackFactory).interfaceId);
        _logSelector("calcAddress(address,bytes)", type(IDiamondPackageCallBackFactory).interfaceId);
        _logSelector("initAccount(address,bytes)", type(IDiamondPackageCallBackFactory).interfaceId);
        _logSelector("pkgOfAccount(address)", type(IDiamondPackageCallBackFactory).interfaceId);
        _logSelector("PROXY_INIT_HASH()", type(IDiamondPackageCallBackFactory).interfaceId);
        _logSelector("pkgConfig()", 0); // impl only

        _logSelector("diamondPackageFactory()", type(ICreate3Factory).interfaceId);
        _logSelector("setDiamondPackageFactory(address)", type(ICreate3Factory).interfaceId);
        _logSelector("create3(bytes,bytes32)", type(ICreate3Factory).interfaceId);
        _logSelector("create3WithArgs(bytes,bytes,bytes32)", type(ICreate3Factory).interfaceId);

        _logSelector("isOperator(address)", type(IOperable).interfaceId);
        _logSelector("isOperatorFor(bytes4,address)", type(IOperable).interfaceId);
        _logSelector("setOperator(address,bool)", type(IOperable).interfaceId);
        _logSelector("setOperatorFor(bytes4,address,bool)", type(IOperable).interfaceId);

        _logSelector("initiateOwnershipTransfer(address)", type(IMultiStepOwnable).interfaceId);
        _logSelector("confirmOwnershipTransfer(address)", type(IMultiStepOwnable).interfaceId);
        _logSelector("cancelPendingOwnershipTransfer()", type(IMultiStepOwnable).interfaceId);
        _logSelector("acceptOwnershipTransfer()", type(IMultiStepOwnable).interfaceId);
        _logSelector("owner()", type(IMultiStepOwnable).interfaceId);
        _logSelector("pendingOwner()", type(IMultiStepOwnable).interfaceId);
        _logSelector("preConfirmedOwner()", type(IMultiStepOwnable).interfaceId);
        _logSelector("getOwnershipTransferBuffer()", type(IMultiStepOwnable).interfaceId);

        console2.log("");

        // --- Event topic0 (keccak of canonical signature) ---
        console2.log("Event topic0:");
        _logTopic0("NewGlobalOperatorStatus(address,bool)");
        _logTopic0("NewFunctionOperatorStatus(address,bytes4,bool)");
        _logTopic0("OwnershipTransferInitiated(address,address)");
        _logTopic0("OwnershipTransferConfirmed(address,address)");
        _logTopic0("OwnershipTransferred(address,address)");

        console2.log("");

        // --- Error selectors ---
        console2.log("Error selectors:");
        _logSelector("NotOperator(address)", 0);
        _logSelector("NotOwner(address)", 0);
        _logSelector("NotPending(address)", 0);
        _logSelector("BufferPeriodNotElapsed(uint256,uint256)", 0);
        _logSelector("DeploymentAddressMismatch(address,address)", 0);

        console2.log("");
        console2.log("=== End NatSpec Values ===");
        console2.log("Copy the bytes values above into CENTRALLY_COMPUTED_NATSPEC_VALUES.md and source NatSpec.");
        console2.log("Re-run after any interface change to keep single source of truth.");
    }

    // end::ComputeNatSpecValues[]

    /* -------------------------------------------------------------------------- */
    /*                               Internal Utils                               */
    /* -------------------------------------------------------------------------- */

    // tag::_logSelector(string-bytes4)[]
    /**
     * @dev Logs a function/error selector using Solidity keccak (compiler accurate).
     * @param sig The canonical signature string e.g. "foo(address)".
     * @param _ignored present for call compatibility in listing.
     */
    function _logSelector(string memory sig, bytes4 _ignored) internal pure {
        bytes4 sel = bytes4(keccak256(bytes(sig)));
        console2.log(string.concat("selector(", sig, ") = "));
        console2.logBytes4(sel);
    }

    // end::_logSelector(string-bytes4)[]

    // tag::_logTopic0(string)[]
    /**
     * @dev Logs event topic0 using Solidity keccak.
     * @param sig The event signature e.g. "Event(address)".
     */
    function _logTopic0(string memory sig) internal pure {
        bytes32 topic = keccak256(bytes(sig));
        console2.log(string.concat("topic0(", sig, ") = "));
        console2.logBytes32(topic);
    }
    // end::_logTopic0(string)[]
}
