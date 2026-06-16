// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import {Vm} from "forge-std/Vm.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IERC721} from "@crane/contracts/interfaces/IERC721.sol";
import {betterconsole as console} from "@crane/contracts/utils/vm/foundry/tools/betterconsole.sol";
import {VM_ADDRESS} from "@crane/contracts/constants/FoundryConstants.sol";
import {BehaviorUtils} from "@crane/contracts/test/behaviors/BehaviorUtils.sol";
import {UInt256} from "@crane/contracts/utils/UInt256.sol";

// tag::Behavior_IERC721[]
/**
 * @title Behavior_IERC721
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Behavior library encapsulating validation logic for IERC721 interface compliance and state transition testing.
 * @dev Core for LR-7 ERC721 behavior and declaration tests (via TestBase_ERC721 and direct use in handlers/stubs). Provides expect_*, hasValid_*, isValid_* (areValid_*) helpers that delegate to direct queries + betterconsole logging (modeled on comparator set patterns in Behavior_IFacet/Behavior_IERC165).
 *      IERC721 surface: balanceOf, ownerOf, getApproved, isApprovedForAll, transfer variants, approve, setApprovalForAll (no totalSupply in base IERC721; enum augments separate).
 *      All IERC721 surface references follow gold ERC721Facet/ERC721*Repo (no custom selector tags inserted here as none for these funcs listed in CENTRALLY; ONLY centrals rule followed strictly).
 *      Pattern modeled exactly on closed Behavior_IERC165.sol + Behavior_IFacet.sol golds (rich prose, _*Name, errPrefix* helpers, expect/hasValid/isValid/areValid patterns, hyphenated overload tags e.g. isValid_balanceOf(IERC721-address-uint256)[], entry/exit/validation/error logs).
 *      No behavior or logic changes: original delta/owner/approval-clear checks preserved exactly; only wrapped with NatSpec + tags + logging.
 *      "Storage" pattern N/A (pure behavior lib, not a Repo). Uses sets/comparators style via import patterns + direct for query params.
 */
library Behavior_IERC721 {
    using UInt256 for uint256;

    /// forge-lint: disable-next-line(screaming-snake-case-const)
    Vm constant vm = Vm(VM_ADDRESS);

    // tag::_Behavior_IERC721Name()[]
    /**
     * @notice Returns the name of the behavior.
     * @dev Used to prefix to identify which Behavior is logging.
     * @return The name of the behavior.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _Behavior_IERC721Name() internal pure returns (string memory) {
        return type(Behavior_IERC721).name;
    }
    // end::_Behavior_IERC721Name()[]

    // tag::_ierc721_errPrefixFunc(string)[]
    /**
     * @notice Returns the error prefix function for the behavior.
     * @param testedFuncSig The function signature being tested.
     * @return The error prefix.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _ierc721_errPrefixFunc(string memory testedFuncSig) internal pure returns (string memory) {
        return BehaviorUtils._errPrefixFunc(_Behavior_IERC721Name(), testedFuncSig);
    }
    // end::_ierc721_errPrefixFunc(string)[]

    // tag::_ierc721_errPrefix(string-string)[]
    /**
     * @notice Returns the error prefix for the behavior.
     * @param testedFuncSig The function signature being tested.
     * @param subjectLabel The label of the subject being tested.
     * @return The error prefix.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _ierc721_errPrefix(string memory testedFuncSig, string memory subjectLabel)
        internal
        pure
        returns (string memory)
    {
        return string.concat(_ierc721_errPrefixFunc(testedFuncSig), subjectLabel);
    }
    // end::_ierc721_errPrefix(string-string)[]

    // tag::_ierc721_errPrefix(string-address)[]
    /**
     * @notice Returns the error prefix for the behavior.
     * @param testedFuncSig The function signature being tested.
     * @param subject The address of the subject being tested.
     * @return The error prefix.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _ierc721_errPrefix(string memory testedFuncSig, address subject) internal view returns (string memory) {
        return _ierc721_errPrefix(testedFuncSig, vm.getLabel(subject));
    }
    // end::_ierc721_errPrefix(string-address)[]

    /* ---------------------- balanceOf(address) ---------------------- */

    // tag::funcSig_IERC721_balanceOf()[]
    /**
     * @notice Returns the IERC721.balanceOf function signature for error messages and logging.
     * @return The function signature.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_IERC721_balanceOf() public pure returns (string memory) {
        return "balanceOf(address)";
    }
    // end::funcSig_IERC721_balanceOf()[]

    // tag::isValid_balanceOf(IERC721-address-uint256)[]
    /**
     * @notice Verify balanceOf returns expected value.
     * @dev Uses exact == (per LR-7 exact value assertions). Logs via betterconsole.
     * @param token The IERC721 subject under test.
     * @param owner address of the account to query
     * @param expectedBalance The expected number of tokens owned by the account.
     * @return valid True if actual == expected.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function isValid_balanceOf(IERC721 token, address owner, uint256 expectedBalance) public view returns (bool valid) {
        console.logBehaviorEntry(_Behavior_IERC721Name(), "isValid_balanceOf");

        uint256 actual = token.balanceOf(owner);
        valid = actual == expectedBalance;
        if (!valid) {
            console.logBehaviorError(
                _Behavior_IERC721Name(),
                "isValid_balanceOf",
                _ierc721_errPrefix(funcSig_IERC721_balanceOf(), address(token)),
                "balance mismatch"
            );
            console.logBehaviorCompare(
                _Behavior_IERC721Name(),
                "isValid_balanceOf",
                "balance",
                expectedBalance._toString(),
                actual._toString()
            );
        }

        console.logBehaviorValidation(
            _Behavior_IERC721Name(), "isValid_balanceOf", "balanceOf", valid
        );

        console.logBehaviorExit(_Behavior_IERC721Name(), "isValid_balanceOf");
        return valid;
    }
    // end::isValid_balanceOf(IERC721-address-uint256)[]

    // tag::expect_balanceOf(IERC721-address-uint256)[]
    /**
     * @notice Records expectation for balanceOf(owner) for later hasValid or test setup (LR-7).
     * @param subject The IERC721 subject under test.
     * @param owner address of the account to query
     * @param expectedBalance The expected balance.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_balanceOf(IERC721 subject, address owner, uint256 expectedBalance) public {
        console.logBehaviorEntry(_Behavior_IERC721Name(), "expect_balanceOf");

        console.logBehaviorExpectation(
            _Behavior_IERC721Name(),
            "expect_balanceOf",
            "balance for owner",
            string.concat(vm.toString(owner), ":", expectedBalance._toString())
        );

        console.logBehaviorExit(_Behavior_IERC721Name(), "expect_balanceOf");
    }
    // end::expect_balanceOf(IERC721-address-uint256)[]

    // tag::hasValid_balanceOf(IERC721-address-uint256)[]
    /**
     * @notice Validates current balanceOf(owner) matches expected (supports declaration/behavior tests).
     * @param subject The IERC721 subject.
     * @param owner address of the account
     * @param expectedBalance The expected.
     * @return isValid_ True if current matches.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_balanceOf(IERC721 subject, address owner, uint256 expectedBalance) public view returns (bool isValid_) {
        console.logBehaviorEntry(_Behavior_IERC721Name(), "hasValid_balanceOf");
        isValid_ = isValid_balanceOf(subject, owner, expectedBalance);
        console.logBehaviorValidation(_Behavior_IERC721Name(), "hasValid_balanceOf", "balanceOf", isValid_);
        console.logBehaviorExit(_Behavior_IERC721Name(), "hasValid_balanceOf");
        return isValid_;
    }
    // end::hasValid_balanceOf(IERC721-address-uint256)[]

    /* ---------------------- ownerOf(uint256) ---------------------- */

    // tag::funcSig_IERC721_ownerOf()[]
    /**
     * @notice Returns the IERC721.ownerOf function signature for error messages and logging.
     * @return The function signature.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_IERC721_ownerOf() public pure returns (string memory) {
        return "ownerOf(uint256)";
    }
    // end::funcSig_IERC721_ownerOf()[]

    // tag::isValid_ownerOf(IERC721-uint256-address)[]
    /**
     * @notice Verify ownerOf returns expected value.
     * @dev Exact match per LR-7.
     * @param token The IERC721 subject under test.
     * @param tokenId identifier of the token to query
     * @param expectedOwner The expected owner of the token.
     * @return valid True if actual == expected.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function isValid_ownerOf(IERC721 token, uint256 tokenId, address expectedOwner) public view returns (bool valid) {
        console.logBehaviorEntry(_Behavior_IERC721Name(), "isValid_ownerOf");

        address actual = token.ownerOf(tokenId);
        valid = actual == expectedOwner;
        if (!valid) {
            console.logBehaviorError(
                _Behavior_IERC721Name(),
                "isValid_ownerOf",
                _ierc721_errPrefix(funcSig_IERC721_ownerOf(), address(token)),
                "owner mismatch"
            );
            console.logBehaviorCompare(
                _Behavior_IERC721Name(),
                "isValid_ownerOf",
                "owner",
                vm.toString(expectedOwner),
                vm.toString(actual)
            );
        }

        console.logBehaviorValidation(
            _Behavior_IERC721Name(), "isValid_ownerOf", "ownerOf", valid
        );

        console.logBehaviorExit(_Behavior_IERC721Name(), "isValid_ownerOf");
        return valid;
    }
    // end::isValid_ownerOf(IERC721-uint256-address)[]

    // tag::expect_ownerOf(IERC721-uint256-address)[]
    /**
     * @notice Records expectation for ownerOf(tokenId).
     * @param subject The IERC721 subject under test.
     * @param tokenId identifier of the token to query
     * @param expectedOwner The expected owner.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_ownerOf(IERC721 subject, uint256 tokenId, address expectedOwner) public {
        console.logBehaviorEntry(_Behavior_IERC721Name(), "expect_ownerOf");
        console.logBehaviorExpectation(
            _Behavior_IERC721Name(),
            "expect_ownerOf",
            "owner for tokenId",
            string.concat(vm.toString(tokenId), ":", vm.toString(expectedOwner))
        );
        console.logBehaviorExit(_Behavior_IERC721Name(), "expect_ownerOf");
    }
    // end::expect_ownerOf(IERC721-uint256-address)[]

    // tag::hasValid_ownerOf(IERC721-uint256-address)[]
    /**
     * @notice Validates current ownerOf(tokenId) matches expected.
     * @param subject The IERC721 subject.
     * @param tokenId identifier of the token
     * @param expectedOwner The expected.
     * @return isValid_ True if matches.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_ownerOf(IERC721 subject, uint256 tokenId, address expectedOwner) public view returns (bool isValid_) {
        console.logBehaviorEntry(_Behavior_IERC721Name(), "hasValid_ownerOf");
        isValid_ = isValid_ownerOf(subject, tokenId, expectedOwner);
        console.logBehaviorExit(_Behavior_IERC721Name(), "hasValid_ownerOf");
        return isValid_;
    }
    // end::hasValid_ownerOf(IERC721-uint256-address)[]

    /* ---------------------- getApproved(uint256) ---------------------- */

    // tag::funcSig_IERC721_getApproved()[]
    /**
     * @notice Returns the IERC721.getApproved function signature for error messages and logging.
     * @return The function signature.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_IERC721_getApproved() public pure returns (string memory) {
        return "getApproved(uint256)";
    }
    // end::funcSig_IERC721_getApproved()[]

    // tag::isValid_getApproved(IERC721-uint256-address)[]
    /**
     * @notice Verify getApproved returns expected value.
     * @param token The IERC721 subject under test.
     * @param tokenId identifier of the token to query the approval of
     * @param expectedApproved The expected approved operator for the token.
     * @return valid True if actual == expected.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function isValid_getApproved(IERC721 token, uint256 tokenId, address expectedApproved)
        public
        view
        returns (bool valid)
    {
        console.logBehaviorEntry(_Behavior_IERC721Name(), "isValid_getApproved");

        address actual = token.getApproved(tokenId);
        valid = actual == expectedApproved;
        if (!valid) {
            console.logBehaviorError(
                _Behavior_IERC721Name(),
                "isValid_getApproved",
                _ierc721_errPrefix(funcSig_IERC721_getApproved(), address(token)),
                "approval mismatch"
            );
            console.logBehaviorCompare(
                _Behavior_IERC721Name(),
                "isValid_getApproved",
                "approved",
                vm.toString(expectedApproved),
                vm.toString(actual)
            );
        }

        console.logBehaviorValidation(
            _Behavior_IERC721Name(), "isValid_getApproved", "getApproved", valid
        );

        console.logBehaviorExit(_Behavior_IERC721Name(), "isValid_getApproved");
        return valid;
    }
    // end::isValid_getApproved(IERC721-uint256-address)[]

    // tag::expect_getApproved(IERC721-uint256-address)[]
    /**
     * @notice Records expectation for getApproved(tokenId).
     * @param subject The IERC721 subject under test.
     * @param tokenId identifier of the token to query
     * @param expectedApproved The expected.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_getApproved(IERC721 subject, uint256 tokenId, address expectedApproved) public {
        console.logBehaviorEntry(_Behavior_IERC721Name(), "expect_getApproved");
        console.logBehaviorExpectation(
            _Behavior_IERC721Name(),
            "expect_getApproved",
            "approved for tokenId",
            string.concat(vm.toString(tokenId), ":", vm.toString(expectedApproved))
        );
        console.logBehaviorExit(_Behavior_IERC721Name(), "expect_getApproved");
    }
    // end::expect_getApproved(IERC721-uint256-address)[]

    // tag::hasValid_getApproved(IERC721-uint256-address)[]
    /**
     * @notice Validates current getApproved(tokenId) matches expected.
     * @param subject The IERC721 subject.
     * @param tokenId identifier of the token
     * @param expectedApproved The expected.
     * @return isValid_ True if matches.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_getApproved(IERC721 subject, uint256 tokenId, address expectedApproved) public view returns (bool isValid_) {
        console.logBehaviorEntry(_Behavior_IERC721Name(), "hasValid_getApproved");
        isValid_ = isValid_getApproved(subject, tokenId, expectedApproved);
        console.logBehaviorExit(_Behavior_IERC721Name(), "hasValid_getApproved");
        return isValid_;
    }
    // end::hasValid_getApproved(IERC721-uint256-address)[]

    /* ---------------------- isApprovedForAll(address,address) ---------------------- */

    // tag::funcSig_IERC721_isApprovedForAll()[]
    /**
     * @notice Returns the IERC721.isApprovedForAll function signature for error messages and logging.
     * @return The function signature.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_IERC721_isApprovedForAll() public pure returns (string memory) {
        return "isApprovedForAll(address,address)";
    }
    // end::funcSig_IERC721_isApprovedForAll()[]

    // tag::isValid_isApprovedForAll(IERC721-address-address-bool)[]
    /**
     * @notice Verify isApprovedForAll returns expected value.
     * @param token The IERC721 subject under test.
     * @param owner address of the owner of the assets
     * @param operator address of the approved operator
     * @param expectedApproval The expected approval status.
     * @return valid True if actual == expected.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function isValid_isApprovedForAll(IERC721 token, address owner, address operator, bool expectedApproval)
        public
        view
        returns (bool valid)
    {
        console.logBehaviorEntry(_Behavior_IERC721Name(), "isValid_isApprovedForAll");

        bool actual = token.isApprovedForAll(owner, operator);
        valid = actual == expectedApproval;
        if (!valid) {
            console.logBehaviorError(
                _Behavior_IERC721Name(),
                "isValid_isApprovedForAll",
                _ierc721_errPrefix(funcSig_IERC721_isApprovedForAll(), address(token)),
                "approval for all mismatch"
            );
            console.logBehaviorCompare(
                _Behavior_IERC721Name(),
                "isValid_isApprovedForAll",
                "isApprovedForAll",
                expectedApproval ? "true" : "false",
                actual ? "true" : "false"
            );
        }

        console.logBehaviorValidation(
            _Behavior_IERC721Name(), "isValid_isApprovedForAll", "isApprovedForAll", valid
        );

        console.logBehaviorExit(_Behavior_IERC721Name(), "isValid_isApprovedForAll");
        return valid;
    }
    // end::isValid_isApprovedForAll(IERC721-address-address-bool)[]

    // tag::expect_isApprovedForAll(IERC721-address-address-bool)[]
    /**
     * @notice Records expectation for isApprovedForAll(owner,operator).
     * @param subject The IERC721 subject under test.
     * @param owner address of the owner
     * @param operator address of the operator
     * @param expectedApproval The expected.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_isApprovedForAll(IERC721 subject, address owner, address operator, bool expectedApproval) public {
        console.logBehaviorEntry(_Behavior_IERC721Name(), "expect_isApprovedForAll");
        console.logBehaviorExpectation(
            _Behavior_IERC721Name(),
            "expect_isApprovedForAll",
            "approvalForAll",
            string.concat(vm.toString(owner), ":", vm.toString(operator), ":", expectedApproval ? "true" : "false")
        );
        console.logBehaviorExit(_Behavior_IERC721Name(), "expect_isApprovedForAll");
    }
    // end::expect_isApprovedForAll(IERC721-address-address-bool)[]

    // tag::hasValid_isApprovedForAll(IERC721-address-address-bool)[]
    /**
     * @notice Validates current isApprovedForAll matches expected.
     * @param subject The IERC721 subject.
     * @param owner address of the owner
     * @param operator address of the operator
     * @param expectedApproval The expected.
     * @return isValid_ True if matches.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_isApprovedForAll(IERC721 subject, address owner, address operator, bool expectedApproval)
        public
        view
        returns (bool isValid_)
    {
        console.logBehaviorEntry(_Behavior_IERC721Name(), "hasValid_isApprovedForAll");
        isValid_ = isValid_isApprovedForAll(subject, owner, operator, expectedApproval);
        console.logBehaviorExit(_Behavior_IERC721Name(), "hasValid_isApprovedForAll");
        return isValid_;
    }
    // end::hasValid_isApprovedForAll(IERC721-address-address-bool)[]

    /* ---------------------- approve(uint256,address) ---------------------- */

    // tag::funcSig_IERC721_approve()[]
    /**
     * @notice Returns the IERC721.approve function signature for error messages and logging.
     * @return The function signature.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_IERC721_approve() public pure returns (string memory) {
        return "approve(address,uint256)";
    }
    // end::funcSig_IERC721_approve()[]

    // tag::isValid_approve(IERC721-uint256-address)[]
    /**
     * @notice Verify approval was set correctly (post approve).
     * @param token The IERC721 subject under test.
     * @param tokenId identifier of the token
     * @param expectedApproved The expected approved address.
     * @return valid True if matches.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function isValid_approve(IERC721 token, uint256 tokenId, address expectedApproved) public view returns (bool valid) {
        console.logBehaviorEntry(_Behavior_IERC721Name(), "isValid_approve");
        valid = isValid_getApproved(token, tokenId, expectedApproved);
        console.logBehaviorExit(_Behavior_IERC721Name(), "isValid_approve");
        return valid;
    }
    // end::isValid_approve(IERC721-uint256-address)[]

    // tag::expect_approve(IERC721-uint256-address)[]
    /**
     * @notice Records expectation for post-approve state.
     * @param subject The IERC721 subject under test.
     * @param tokenId identifier of the token
     * @param expectedApproved The expected.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_approve(IERC721 subject, uint256 tokenId, address expectedApproved) public {
        console.logBehaviorEntry(_Behavior_IERC721Name(), "expect_approve");
        expect_getApproved(subject, tokenId, expectedApproved);
        console.logBehaviorExit(_Behavior_IERC721Name(), "expect_approve");
    }
    // end::expect_approve(IERC721-uint256-address)[]

    // tag::hasValid_approve(IERC721-uint256-address)[]
    /**
     * @notice Validates current approve state.
     * @param subject The IERC721 subject.
     * @param tokenId identifier of the token
     * @param expectedApproved The expected.
     * @return isValid_ True if matches.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_approve(IERC721 subject, uint256 tokenId, address expectedApproved) public view returns (bool isValid_) {
        console.logBehaviorEntry(_Behavior_IERC721Name(), "hasValid_approve");
        isValid_ = isValid_approve(subject, tokenId, expectedApproved);
        console.logBehaviorExit(_Behavior_IERC721Name(), "hasValid_approve");
        return isValid_;
    }
    // end::hasValid_approve(IERC721-uint256-address)[]

    /* ---------------------- setApprovalForAll(address,bool) ---------------------- */

    // tag::funcSig_IERC721_setApprovalForAll()[]
    /**
     * @notice Returns the IERC721.setApprovalForAll function signature for error messages and logging.
     * @return The function signature.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_IERC721_setApprovalForAll() public pure returns (string memory) {
        return "setApprovalForAll(address,bool)";
    }
    // end::funcSig_IERC721_setApprovalForAll()[]

    // tag::isValid_setApprovalForAll(IERC721-address-address-bool)[]
    /**
     * @notice Verify setApprovalForAll was set correctly (post call).
     * @param token The IERC721 subject under test.
     * @param owner address of the owner
     * @param operator address of the operator
     * @param expectedApproval The expected status.
     * @return valid True if matches.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function isValid_setApprovalForAll(IERC721 token, address owner, address operator, bool expectedApproval)
        public
        view
        returns (bool valid)
    {
        console.logBehaviorEntry(_Behavior_IERC721Name(), "isValid_setApprovalForAll");
        valid = isValid_isApprovedForAll(token, owner, operator, expectedApproval);
        console.logBehaviorExit(_Behavior_IERC721Name(), "isValid_setApprovalForAll");
        return valid;
    }
    // end::isValid_setApprovalForAll(IERC721-address-address-bool)[]

    // tag::expect_setApprovalForAll(IERC721-address-address-bool)[]
    /**
     * @notice Records expectation for post setApprovalForAll.
     * @param subject The IERC721 subject under test.
     * @param owner address of the owner
     * @param operator address of the operator
     * @param expectedApproval The expected.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_setApprovalForAll(IERC721 subject, address owner, address operator, bool expectedApproval) public {
        console.logBehaviorEntry(_Behavior_IERC721Name(), "expect_setApprovalForAll");
        expect_isApprovedForAll(subject, owner, operator, expectedApproval);
        console.logBehaviorExit(_Behavior_IERC721Name(), "expect_setApprovalForAll");
    }
    // end::expect_setApprovalForAll(IERC721-address-address-bool)[]

    // tag::hasValid_setApprovalForAll(IERC721-address-address-bool)[]
    /**
     * @notice Validates current setApprovalForAll state.
     * @param subject The IERC721 subject.
     * @param owner address of the owner
     * @param operator address of the operator
     * @param expectedApproval The expected.
     * @return isValid_ True if matches.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_setApprovalForAll(IERC721 subject, address owner, address operator, bool expectedApproval)
        public
        view
        returns (bool isValid_)
    {
        console.logBehaviorEntry(_Behavior_IERC721Name(), "hasValid_setApprovalForAll");
        isValid_ = isValid_setApprovalForAll(subject, owner, operator, expectedApproval);
        console.logBehaviorExit(_Behavior_IERC721Name(), "hasValid_setApprovalForAll");
        return isValid_;
    }
    // end::hasValid_setApprovalForAll(IERC721-address-address-bool)[]

    /* ---------------------- transfer state (composite) ---------------------- */

    // tag::funcSig_IERC721_transferFrom()[]
    /**
     * @notice Returns the IERC721.transferFrom / safe* function signature representative for logging.
     * @return The function signature.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_IERC721_transferFrom() public pure returns (string memory) {
        return "transferFrom(address,address,uint256)";
    }
    // end::funcSig_IERC721_transferFrom()[]

    // tag::isValid_transfer(IERC721-address-address-uint256-uint256-uint256)[]
    /**
     * @notice Verify a transfer (or safeTransferFrom) updated state correctly.
     * @dev Original logic preserved EXACTLY: owner change, -1/+1 balances (unless self), cleared approval.
     *      Uses exact deltas per LR-7.
     * @param token The IERC721 subject under test.
     * @param from address transferred from
     * @param to address transferred to
     * @param tokenId identifier of the token transferred
     * @param fromBalanceBefore pre-transfer balance of from
     * @param toBalanceBefore pre-transfer balance of to
     * @return valid True if all state transitions correct.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function isValid_transfer(
        IERC721 token,
        address from,
        address to,
        uint256 tokenId,
        uint256 fromBalanceBefore,
        uint256 toBalanceBefore
    ) public view returns (bool valid) {
        console.logBehaviorEntry(_Behavior_IERC721Name(), "isValid_transfer");

        // Owner should have changed
        if (token.ownerOf(tokenId) != to) {
            valid = false;
        } else if (token.balanceOf(from) != fromBalanceBefore - 1) {
            valid = false;
        } else if (from != to && token.balanceOf(to) != toBalanceBefore + 1) {
            valid = false;
        } else if (token.getApproved(tokenId) != address(0)) {
            valid = false;
        } else {
            valid = true;
        }

        if (!valid) {
            console.logBehaviorError(
                _Behavior_IERC721Name(),
                "isValid_transfer",
                _ierc721_errPrefix(funcSig_IERC721_transferFrom(), address(token)),
                "transfer state mismatch"
            );
        }

        console.logBehaviorValidation(_Behavior_IERC721Name(), "isValid_transfer", "transfer state", valid);
        console.logBehaviorExit(_Behavior_IERC721Name(), "isValid_transfer");
        return valid;
    }
    // end::isValid_transfer(IERC721-address-address-uint256-uint256-uint256)[]

    // tag::expect_transfer(IERC721-address-address-uint256-uint256-uint256)[]
    /**
     * @notice Records pre-transfer expectations for post-transfer isValid_transfer validation.
     * @param subject The IERC721 subject.
     * @param from pre from
     * @param to pre to
     * @param tokenId the id
     * @param fromBalanceBefore pre bal
     * @param toBalanceBefore pre bal
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_transfer(
        IERC721 subject,
        address from,
        address to,
        uint256 tokenId,
        uint256 fromBalanceBefore,
        uint256 toBalanceBefore
    ) public {
        console.logBehaviorEntry(_Behavior_IERC721Name(), "expect_transfer");
        console.logBehaviorExpectation(
            _Behavior_IERC721Name(),
            "expect_transfer",
            "transfer pre-state",
            string.concat("id:", vm.toString(tokenId))
        );
        console.logBehaviorExit(_Behavior_IERC721Name(), "expect_transfer");
    }
    // end::expect_transfer(IERC721-address-address-uint256-uint256-uint256)[]

    // tag::hasValid_transfer(IERC721-address-address-uint256-uint256-uint256)[]
    /**
     * @notice Validates post-transfer state (call after capture of befores; use isValid under).
     * @return isValid_ True if transfer effects hold.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_transfer(
        IERC721 subject,
        address from,
        address to,
        uint256 tokenId,
        uint256 fromBalanceBefore,
        uint256 toBalanceBefore
    ) public view returns (bool isValid_) {
        console.logBehaviorEntry(_Behavior_IERC721Name(), "hasValid_transfer");
        isValid_ = isValid_transfer(subject, from, to, tokenId, fromBalanceBefore, toBalanceBefore);
        console.logBehaviorExit(_Behavior_IERC721Name(), "hasValid_transfer");
        return isValid_;
    }
    // end::hasValid_transfer(IERC721-address-address-uint256-uint256-uint256)[]

// end::Behavior_IERC721[]
}
