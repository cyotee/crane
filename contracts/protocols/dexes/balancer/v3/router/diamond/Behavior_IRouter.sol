// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import {Vm} from "forge-std/Vm.sol";

/* -------------------------------------------------------------------------- */
/*                                  Balancer                                  */
/* -------------------------------------------------------------------------- */

import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {IRouter} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IRouter.sol";
import {IRouterCommon} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IRouterCommon.sol";
import {IBatchRouter} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IBatchRouter.sol";
import {IBufferRouter} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IBufferRouter.sol";
import {ICompositeLiquidityRouter} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/ICompositeLiquidityRouter.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {betterconsole as console} from "@crane/contracts/utils/vm/foundry/tools/betterconsole.sol";
import {VM_ADDRESS} from "@crane/contracts/constants/FoundryConstants.sol";
import {Bytes4Set, Bytes4SetRepo} from "@crane/contracts/utils/collections/sets/Bytes4SetRepo.sol";
import {BehaviorUtils} from "@crane/contracts/test/behaviors/BehaviorUtils.sol";
import {Bytes4SetComparatorRepo, Bytes4SetComparator} from "@crane/contracts/test/comparators/Bytes4SetComparator.sol";
import {AddressSetComparatorRepo, AddressSetComparator} from "@crane/contracts/test/comparators/AddressSetComparator.sol";
import {UInt256} from "@crane/contracts/utils/UInt256.sol";
import {Bytes4} from "@crane/contracts/utils/Bytes4.sol";

/* -------------------------------------------------------------------------- */
/*                               Behavior_IRouter                             */
/* -------------------------------------------------------------------------- */

/**
 * @title Behavior_IRouter
 * @notice Behavior library for validating Balancer V3 Router implementations.
 * @dev Provides validation functions following the Crane Behavior pattern:
 *      - expect_* : Record expected values for later validation
 *      - isValid_* / areValid_* : Direct comparison of expected vs actual
 *      - hasValid_* : Validate against recorded expectations
 *
 * This library validates:
 *      - Router interface compliance (IRouter, IRouterCommon, IBatchRouter, etc.)
 *      - Storage initialization (vault, WETH, permit2)
 *      - Facet configuration
 */
library Behavior_IRouter {
    using Bytes4 for bytes4;
    using Bytes4SetRepo for Bytes4Set;
    using UInt256 for uint256;

    /// forge-lint: disable-next-line(screaming-snake-case-const)
    Vm constant vm = Vm(VM_ADDRESS);

    /* ========================================================================== */
    /*                          INTERNAL STORAGE                                  */
    /* ========================================================================== */

    /// @dev Storage layout for expected address values
    struct AddressExpectationLayout {
        mapping(address subject => mapping(bytes4 func => address expected)) recordedExpected;
    }

    /// @dev Storage slot for address expectations
    bytes32 private constant ADDRESS_EXPECTATION_SLOT = keccak256("Behavior_IRouter.AddressExpectationLayout");

    /// @dev Returns the storage layout for address expectations
    function _addressExpectationLayout() private pure returns (AddressExpectationLayout storage layout) {
        bytes32 slot = ADDRESS_EXPECTATION_SLOT;
        assembly {
            layout.slot := slot
        }
    }

    /// @dev Records an expected address for a subject/function pair
    function _recExpectedAddress(address subject, bytes4 func, address expected) internal {
        _addressExpectationLayout().recordedExpected[subject][func] = expected;
    }

    /// @dev Retrieves a recorded expected address
    function _recedExpectedAddress(address subject, bytes4 func) internal view returns (address) {
        return _addressExpectationLayout().recordedExpected[subject][func];
    }

    /* ========================================================================== */
    /*                              BEHAVIOR NAME                                 */
    /* ========================================================================== */

    /**
     * @notice Returns the name of the behavior.
     * @dev Used to prefix log messages for identification.
     * @return The name of the behavior.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _Behavior_IRouterName() internal pure returns (string memory) {
        return type(Behavior_IRouter).name;
    }

    /* ========================================================================== */
    /*                              ERROR HELPERS                                 */
    /* ========================================================================== */

    /// forge-lint: disable-next-line(mixed-case-function)
    function _irouter_errPrefixFunc(string memory testedFuncSig) internal pure returns (string memory) {
        return BehaviorUtils._errPrefixFunc(_Behavior_IRouterName(), testedFuncSig);
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function _irouter_errPrefix(string memory testedFuncSig, string memory subjectLabel)
        internal
        pure
        returns (string memory)
    {
        return string.concat(_irouter_errPrefixFunc(testedFuncSig), subjectLabel);
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function _irouter_errPrefix(string memory testedFuncSig, address subject) internal view returns (string memory) {
        return _irouter_errPrefix(testedFuncSig, vm.getLabel(subject));
    }

    /* ========================================================================== */
    /*                          ROUTER INTERFACES                                */
    /* ========================================================================== */

    /**
     * @notice Returns the function signature being tested.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_IRouter_interfaces() public pure returns (string memory) {
        return "facetInterfaces()";
    }

    /**
     * @notice Returns the error suffix for interface validation.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function errSuffix_IRouter_interfaces() public pure returns (string memory) {
        return "router interface IDs";
    }

    /**
     * @notice Validates router interface IDs against expectations.
     * @param subjectName The name/label of the router being tested
     * @param expected The expected interface IDs
     * @param actual The actual interface IDs
     * @return valid True if the interface IDs match expectations
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_IRouter_interfaces(
        string memory subjectName,
        bytes4[] memory expected,
        bytes4[] memory actual
    ) public returns (bool valid) {
        console.logBehaviorEntry(_Behavior_IRouterName(), "areValid_IRouter_interfaces");

        valid = Bytes4SetComparator._compare(
            expected,
            actual,
            _irouter_errPrefix(funcSig_IRouter_interfaces(), subjectName),
            errSuffix_IRouter_interfaces()
        );

        console.logBehaviorValidation(_Behavior_IRouterName(), "areValid_IRouter_interfaces", "interface IDs", valid);

        console.logBehaviorExit(_Behavior_IRouterName(), "areValid_IRouter_interfaces");
        return valid;
    }

    /**
     * @notice Records expected router interfaces for later validation.
     * @param subject The router address to record expectations for
     * @param expectedInterfaces_ The expected interface IDs
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_IRouter_interfaces(address subject, bytes4[] memory expectedInterfaces_) public {
        console.logBehaviorEntry(_Behavior_IRouterName(), "expect_IRouter_interfaces");

        console.logBehaviorExpectation(
            _Behavior_IRouterName(),
            "expect_IRouter_interfaces",
            "interface count",
            expectedInterfaces_.length._toString()
        );

        // Use a synthetic selector to key the expectation
        Bytes4SetComparatorRepo._recExpectedBytes4(
            subject, bytes4(keccak256("router.interfaces")), expectedInterfaces_
        );

        console.logBehaviorExit(_Behavior_IRouterName(), "expect_IRouter_interfaces");
    }

    /**
     * @notice Retrieves recorded expected router interfaces.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _expected_IRouter_interfaces(address subject) internal view returns (Bytes4Set storage) {
        return Bytes4SetComparatorRepo._recedExpectedBytes4(subject, bytes4(keccak256("router.interfaces")));
    }

    /* ========================================================================== */
    /*                          ROUTER VAULT (IRouterCommon)                     */
    /* ========================================================================== */

    /**
     * @notice Returns the function signature for getVault().
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_IRouterCommon_getVault() public pure returns (string memory) {
        return "getVault()";
    }

    /**
     * @notice Returns the error suffix for vault validation.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function errSuffix_IRouterCommon_getVault() public pure returns (string memory) {
        return "router vault address";
    }

    /**
     * @notice Validates that a router returns the expected vault address.
     * @param subjectLabel The label for the router being tested
     * @param expected The expected vault address
     * @param actual The actual vault address
     * @return valid True if the addresses match
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function isValid_IRouterCommon_getVault(
        string memory subjectLabel,
        address expected,
        address actual
    ) public pure returns (bool valid) {
        console.logBehaviorEntry(_Behavior_IRouterName(), "isValid_IRouterCommon_getVault");

        valid = expected == actual;

        if (!valid) {
            console.logBehaviorError(
                _Behavior_IRouterName(),
                "isValid_IRouterCommon_getVault",
                _irouter_errPrefix(funcSig_IRouterCommon_getVault(), subjectLabel),
                errSuffix_IRouterCommon_getVault()
            );
            console.logBehaviorCompare(
                _Behavior_IRouterName(),
                "isValid_IRouterCommon_getVault",
                "vault address",
                vm.toString(expected),
                vm.toString(actual)
            );
        }

        console.logBehaviorValidation(
            _Behavior_IRouterName(), "isValid_IRouterCommon_getVault", "vault address", valid
        );

        console.logBehaviorExit(_Behavior_IRouterName(), "isValid_IRouterCommon_getVault");
        return valid;
    }

    /**
     * @notice Validates that a router returns the expected vault address.
     * @param router The router to test
     * @param expectedVault The expected vault address
     * @return valid True if the vault matches
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function isValid_IRouterCommon_getVault(IRouterCommon router, address expectedVault)
        public
        view
        returns (bool valid)
    {
        return isValid_IRouterCommon_getVault(
            vm.getLabel(address(router)),
            expectedVault,
            address(router.getVault())
        );
    }

    /**
     * @notice Records expected vault address for later validation.
     * @param subject The router address to record expectations for
     * @param expectedVault The expected vault address
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_IRouterCommon_getVault(address subject, address expectedVault) public {
        console.logBehaviorEntry(_Behavior_IRouterName(), "expect_IRouterCommon_getVault");

        console.logBehaviorExpectation(
            _Behavior_IRouterName(),
            "expect_IRouterCommon_getVault",
            "vault",
            vm.toString(expectedVault)
        );

        _recExpectedAddress(subject, IRouterCommon.getVault.selector, expectedVault);

        console.logBehaviorExit(_Behavior_IRouterName(), "expect_IRouterCommon_getVault");
    }

    /**
     * @notice Validates that a router's vault matches recorded expectations.
     * @param router The router to test
     * @return isValid_ True if the vault matches expectations
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_IRouterCommon_getVault(IRouterCommon router) public view returns (bool isValid_) {
        console.logBehaviorEntry(_Behavior_IRouterName(), "hasValid_IRouterCommon_getVault");

        address expectedVault = _recedExpectedAddress(
            address(router), IRouterCommon.getVault.selector
        );

        isValid_ = isValid_IRouterCommon_getVault(
            vm.getLabel(address(router)),
            expectedVault,
            address(router.getVault())
        );

        console.logBehaviorValidation(
            _Behavior_IRouterName(), "hasValid_IRouterCommon_getVault", "vault configuration", isValid_
        );

        console.logBehaviorExit(_Behavior_IRouterName(), "hasValid_IRouterCommon_getVault");
    }

    /* ========================================================================== */
    /*                          FACET SIZE VALIDATION                            */
    /* ========================================================================== */

    /// @notice Maximum contract size in bytes (24KB limit)
    uint256 internal constant MAX_CONTRACT_SIZE = 24576;

    /**
     * @notice Returns the function signature for facet size validation.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_facetSize() public pure returns (string memory) {
        return "facetSize";
    }

    /**
     * @notice Validates that a facet is under the 24KB deployment limit.
     * @param facetLabel The label for the facet being tested
     * @param facetAddress The facet address to check
     * @return valid True if the facet is under 24KB
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function isValid_facetSize(string memory facetLabel, address facetAddress) public view returns (bool valid) {
        console.logBehaviorEntry(_Behavior_IRouterName(), "isValid_facetSize");

        uint256 codeSize = facetAddress.code.length;
        valid = codeSize < MAX_CONTRACT_SIZE;

        if (!valid) {
            console.logBehaviorError(
                _Behavior_IRouterName(),
                "isValid_facetSize",
                string.concat(facetLabel, " exceeds 24KB limit"),
                string.concat("size: ", codeSize._toString(), " bytes")
            );
        }

        console.logBehaviorValidation(_Behavior_IRouterName(), "isValid_facetSize", facetLabel, valid);

        console.logBehaviorExit(_Behavior_IRouterName(), "isValid_facetSize");
        return valid;
    }

    /**
     * @notice Validates that all facets in an array are under the 24KB limit.
     * @param facets Array of facet addresses to check
     * @return valid True if all facets are under 24KB
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_facetSizes(address[] memory facets) public view returns (bool valid) {
        console.logBehaviorEntry(_Behavior_IRouterName(), "areValid_facetSizes");

        valid = true;
        for (uint256 i = 0; i < facets.length; i++) {
            if (!isValid_facetSize(vm.getLabel(facets[i]), facets[i])) {
                valid = false;
            }
        }

        console.logBehaviorValidation(
            _Behavior_IRouterName(),
            "areValid_facetSizes",
            string.concat("all ", facets.length._toString(), " facets"),
            valid
        );

        console.logBehaviorExit(_Behavior_IRouterName(), "areValid_facetSizes");
        return valid;
    }

    /* ========================================================================== */
    /*                          FACET CUTS VALIDATION                            */
    /* ========================================================================== */

    /**
     * @notice Returns the function signature for facet cuts validation.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_facetCuts() public pure returns (string memory) {
        return "facetCuts()";
    }

    /**
     * @notice Validates that a facet cut has non-empty selectors.
     * @param facetLabel The label for the facet being tested
     * @param selectorCount The number of selectors in the facet cut
     * @return valid True if the facet has selectors
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function isValid_facetCut_hasSelectors(string memory facetLabel, uint256 selectorCount)
        public
        pure
        returns (bool valid)
    {
        console.logBehaviorEntry(_Behavior_IRouterName(), "isValid_facetCut_hasSelectors");

        valid = selectorCount > 0;

        if (!valid) {
            console.logBehaviorError(
                _Behavior_IRouterName(),
                "isValid_facetCut_hasSelectors",
                string.concat(facetLabel, " has no selectors"),
                "facet cuts must have at least one selector"
            );
        }

        console.logBehaviorValidation(_Behavior_IRouterName(), "isValid_facetCut_hasSelectors", facetLabel, valid);

        console.logBehaviorExit(_Behavior_IRouterName(), "isValid_facetCut_hasSelectors");
        return valid;
    }

    /* ========================================================================== */
    /*                          DETERMINISTIC DEPLOYMENT                         */
    /* ========================================================================== */

    /**
     * @notice Returns the function signature for deployment validation.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_deployRouter() public pure returns (string memory) {
        return "deployRouter()";
    }

    /**
     * @notice Validates that a router was deployed to the expected address.
     * @param subjectLabel The label for the deployment being tested
     * @param expectedAddress The expected deployment address
     * @param actualAddress The actual deployment address
     * @return valid True if the addresses match
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function isValid_deployRouter_deterministic(
        string memory subjectLabel,
        address expectedAddress,
        address actualAddress
    ) public pure returns (bool valid) {
        console.logBehaviorEntry(_Behavior_IRouterName(), "isValid_deployRouter_deterministic");

        valid = expectedAddress == actualAddress;

        if (!valid) {
            console.logBehaviorError(
                _Behavior_IRouterName(),
                "isValid_deployRouter_deterministic",
                string.concat(subjectLabel, " address mismatch"),
                "deployment should be deterministic"
            );
            console.logBehaviorCompare(
                _Behavior_IRouterName(),
                "isValid_deployRouter_deterministic",
                "router address",
                vm.toString(expectedAddress),
                vm.toString(actualAddress)
            );
        }

        console.logBehaviorValidation(
            _Behavior_IRouterName(), "isValid_deployRouter_deterministic", "deterministic address", valid
        );

        console.logBehaviorExit(_Behavior_IRouterName(), "isValid_deployRouter_deterministic");
        return valid;
    }

    /**
     * @notice Validates that redeploying with same args returns the same address.
     * @param router1 The first deployment address
     * @param router2 The second deployment address (same args)
     * @return valid True if the addresses match
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function isValid_deployRouter_idempotent(address router1, address router2) public pure returns (bool valid) {
        console.logBehaviorEntry(_Behavior_IRouterName(), "isValid_deployRouter_idempotent");

        valid = router1 == router2;

        if (!valid) {
            console.logBehaviorError(
                _Behavior_IRouterName(),
                "isValid_deployRouter_idempotent",
                "redeployment returned different address",
                "deployRouter should be idempotent"
            );
        }

        console.logBehaviorValidation(
            _Behavior_IRouterName(), "isValid_deployRouter_idempotent", "idempotent deployment", valid
        );

        console.logBehaviorExit(_Behavior_IRouterName(), "isValid_deployRouter_idempotent");
        return valid;
    }

    /**
     * @notice Validates that different params produce different addresses.
     * @param router1 The first deployment address
     * @param router2 The second deployment address (different args)
     * @return valid True if the addresses are different
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function isValid_deployRouter_uniqueParams(address router1, address router2) public pure returns (bool valid) {
        console.logBehaviorEntry(_Behavior_IRouterName(), "isValid_deployRouter_uniqueParams");

        valid = router1 != router2;

        if (!valid) {
            console.logBehaviorError(
                _Behavior_IRouterName(),
                "isValid_deployRouter_uniqueParams",
                "different params produced same address",
                "different deployment args should produce different addresses"
            );
        }

        console.logBehaviorValidation(
            _Behavior_IRouterName(), "isValid_deployRouter_uniqueParams", "unique params", valid
        );

        console.logBehaviorExit(_Behavior_IRouterName(), "isValid_deployRouter_uniqueParams");
        return valid;
    }
}
