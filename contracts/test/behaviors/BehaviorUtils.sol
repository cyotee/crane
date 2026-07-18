// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import {Vm} from "forge-std/Vm.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {VM_ADDRESS} from "@crane/contracts/constants/FoundryConstants.sol";

// tag::BehaviorUtils[]

/**
 * @title BehaviorUtils
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Core shared utility library for Behavior test helpers. Provides standardized error prefix formatting ("behaviorName:funcSig::label") for comparator error messages and structured logging.
 * @dev Used by Behavior_IFacet, Behavior_IERC165, Behavior_IDiamondLoupe, Behavior_IFacetRegistry, Behavior_IDiamondFactoryPackageRegistry, Behavior call-target registries, Behavior_IRouter, FacetsComparator and all other Behaviors.
 *      Delegation pattern: Behaviors implement _<prefix>_errPrefixFunc etc that call BehaviorUtils._errPrefixFunc / _errPrefix .
 *      Core LR-1/LR-7 test infrastructure component (see AGENTS.md "Key Testing Files", "Behavior Libraries", crane-testing skill; PRD LR-1 scope includes all test files + Behaviors + NatSpec on test code/helpers).
 *      Rich NatSpec + EXACT // tag:: / end:: on library and all key helpers per LR-1 (hyphenated for overload disambiguation).
 *      No storage. No public interface surface => no @custom:selector / @custom:signature / interfaceid (per CENTRALLY_COMPUTED_NATSPEC_VALUES.md prose-only usage; only @notice/@param/@return/@dev).
 *      Pattern modeled directly on gold closed Behaviors (Behavior_IFacet, Behavior_IERC165) + usage in TestBase_IFacet etc. Preserves 100% original logic, using, forge-lint, structure.
 */
library BehaviorUtils {
    /// forge-lint: disable-next-line(screaming-snake-case-const)
    Vm constant vm = Vm(VM_ADDRESS);

    // tag::_errPrefixFunc(string-string)[]
    /**
     * @notice Returns the base error prefix function string in the form "behaviorName:testedFuncSig::".
     * @dev Primary helper. All Behavior _errPrefixFunc wrappers delegate to this (e.g. _ifacet_errPrefixFunc calls BehaviorUtils._errPrefixFunc(_Behavior_IFacetName(), testedFuncSig)).
     *      Used as building block for full prefixes in areValid_*, hasValid_*, isValid_* + error paths + console.logBehavior* calls.
     * @param behaviorName The name of the Behavior library (from _Behavior_XXXName()).
     * @param testedFuncSig The signature string of the function under test (e.g. from funcSig_IFacet_facetName()).
     * @return The formatted prefix base string.
     */
    function _errPrefixFunc(string memory behaviorName, string memory testedFuncSig)
        internal
        pure
        returns (string memory)
    {
        return string.concat(behaviorName, ":", testedFuncSig, "::");
    }

    // end::_errPrefixFunc(string-string)[]

    // tag::_errPrefix(string-string-string)[]
    /**
     * @notice Returns the full error prefix for a subject identified by string label.
     * @dev Concatenates the func prefix with subjectLabel. Overload for cases passing pre-resolved label (string subjectName in areValid_*).
     * @param behaviorName The Behavior library name.
     * @param testedFuncSig The tested function signature string.
     * @param subjectLabel Label of the subject (from vm.getLabel or explicit).
     * @return Full prefix string for error reporting / comparators.
     */
    function _errPrefix(string memory behaviorName, string memory testedFuncSig, string memory subjectLabel)
        internal
        pure
        returns (string memory)
    {
        return string.concat(_errPrefixFunc(behaviorName, testedFuncSig), subjectLabel);
    }

    // end::_errPrefix(string-string-string)[]

    // tag::_errPrefix(string-string-address)[]
    /**
     * @notice Returns the full error prefix for a subject identified by address (auto-resolves label).
     * @dev Overload that calls vm.getLabel(subject) internally. Used in Behavior helpers taking IFacet, IERC* and contract subjects directly (e.g. hasValid_*).
     * @param behaviorName The Behavior library name.
     * @param testedFuncSig The tested function signature string.
     * @param subject The address of the subject being tested.
     * @return Full prefix string (label resolved via Foundry Vm).
     */
    function _errPrefix(string memory behaviorName, string memory testedFuncSig, address subject)
        internal
        view
        returns (string memory)
    {
        return _errPrefix(behaviorName, testedFuncSig, vm.getLabel(subject));
    }
    // end::_errPrefix(string-string-address)[]

    // end::BehaviorUtils[]
}
