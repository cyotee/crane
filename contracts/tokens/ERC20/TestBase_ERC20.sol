// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Events} from "@crane/contracts/interfaces/IERC20Events.sol";
import {IERC20Errors, IERC721Errors, IERC1155Errors} from "@crane/contracts/interfaces/IERC20Errors.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

// Handler that deploys or targets an ERC20 (SUT) and exposes operations for fuzzing.
contract ERC20TargetStubHandler is Test {
    using BetterEfficientHashLib for bytes;

    IERC20 public sut;

    address[] internal _addrs;
    mapping(address => bool) internal _seen;
    bytes32[] internal _pairs;
    mapping(bytes32 => bool) internal _seenPair;
    mapping(bytes32 => uint256) internal _expectedAllowance;
    address[] internal _pairOwners;
    address[] internal _pairSpenders;

    // Accept the token under test in the constructor so this handler can be reused
    constructor() {}

    // Allow attaching a token after construction (useful when handler must be created
    // before the token is deployed so the token can be minted to the handler address).
    function attachToken(IERC20 token) external {
        sut = token;
        _push(address(this));
    }

    // Normalize arbitrary uint input into small set of addresses
    function addrFromSeed(uint256 seed) public pure returns (address) {
        uint160 v = uint160((seed % 16) + 1);
        return address(v);
    }

    function _push(address a) internal {
        if (!_seen[a]) {
            _seen[a] = true;
            _addrs.push(a);
        }
    }

    // Mutating operations: validate events and reverts with vm.expectEmit / vm.expectRevert
    function transfer(uint256 ownerSeed, uint256 toSeed, uint256 amount) external {
        address owner = addrFromSeed(ownerSeed);
        address to = addrFromSeed(toSeed);
        _push(owner);
        _push(to);

        uint256 bal = sut.balanceOf(owner);

        vm.prank(owner);
        if (amount > bal) {
            bytes memory err =
                abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, owner, bal, amount);
            vm.expectRevert(err);
            sut.transfer(to, amount);
            return;
        }

        vm.expectEmit(true, true, false, true);
        emit IERC20Events.Transfer(owner, to, amount);
        sut.transfer(to, amount);
    }

    function approve(uint256 approverSeed, uint256 spenderSeed, uint256 amount) external {
        address approver = addrFromSeed(approverSeed);
        address spender = addrFromSeed(spenderSeed);
        _push(approver);
        _push(spender);

        vm.prank(approver);
        if (spender == address(0)) {
            bytes memory err = abi.encodeWithSelector(IERC20Errors.ERC20InvalidSpender.selector, spender);
            vm.expectRevert(err);
            sut.approve(spender, amount);
            return;
        }

        vm.expectEmit(true, true, false, true);
        emit IERC20Events.Approval(approver, spender, amount);
        sut.approve(spender, amount);

        // record expected allowance
        bytes32 k = abi.encodePacked(approver, spender)._hash();
        _expectedAllowance[k] = amount;
        if (!_seenPair[k]) {
            _seenPair[k] = true;
            _pairs.push(k);
            _pairOwners.push(approver);
            _pairSpenders.push(spender);
        }
    }

    function transferFrom(uint256 ownerSeed, uint256 spenderSeed, uint256 recipientSeed, uint256 amount) external {
        address owner = addrFromSeed(ownerSeed);
        address spender = addrFromSeed(spenderSeed);
        address recipient = addrFromSeed(recipientSeed);
        _push(owner);
        _push(spender);
        _push(recipient);

        uint256 allowanceBefore = sut.allowance(owner, spender);
        uint256 bal = sut.balanceOf(owner);

        vm.prank(spender);
        if (allowanceBefore < amount) {
            bytes memory err = abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector, spender, allowanceBefore, amount
            );
            vm.expectRevert(err);
            sut.transferFrom(owner, recipient, amount);
            return;
        }

        if (bal < amount) {
            bytes memory err =
                abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, owner, bal, amount);
            vm.expectRevert(err);
            sut.transferFrom(owner, recipient, amount);
            return;
        }

        vm.expectEmit(true, true, false, true);
        emit IERC20Events.Transfer(owner, recipient, amount);
        sut.transferFrom(owner, recipient, amount);

        // allowance should decrease by amount
        uint256 allowanceAfter = sut.allowance(owner, spender);
        assertEq(allowanceAfter, allowanceBefore - amount);

        // update expected allowance tracking
        bytes32 k2 = abi.encodePacked(owner, spender)._hash();
        // avoid underflow in our expected map
        uint256 prev = _expectedAllowance[k2];
        if (prev >= amount) {
            _expectedAllowance[k2] = prev - amount;
        } else {
            _expectedAllowance[k2] = 0;
        }
        if (!_seenPair[k2]) {
            _seenPair[k2] = true;
            _pairs.push(k2);
            _pairOwners.push(owner);
            _pairSpenders.push(spender);
        }
    }

    // Helpers for invariants / views
    function asAddresses() external view returns (address[] memory) {
        return _addrs;
    }

    function balanceOf(address a) external view returns (uint256) {
        return sut.balanceOf(a);
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return sut.allowance(owner, spender);
    }

    function expectedAllowance(address owner, address spender) external view returns (uint256) {
        return _expectedAllowance[abi.encodePacked(owner, spender)._hash()];
    }

    function pairCount() external view returns (uint256) {
        return _pairs.length;
    }

    function pairAt(uint256 idx) external view returns (address owner, address spender, uint256 expected) {
        owner = _pairOwners[idx];
        spender = _pairSpenders[idx];
        expected = _expectedAllowance[_pairs[idx]];
    }

    function totalSupply() external view returns (uint256) {
        return sut.totalSupply();
    }
}

/// Minimal inheritable test base for ERC20 invariant tests
abstract contract TestBase_ERC20 is Test {
    ERC20TargetStubHandler public handler;
    IERC20 public tokenSubject;

    function _deployToken(ERC20TargetStubHandler handler_) internal virtual returns (IERC20 token_);

    function _deployHandler() internal virtual returns (ERC20TargetStubHandler handler_) {
        handler_ = new ERC20TargetStubHandler();
    }

    function _registerToken(ERC20TargetStubHandler handler_, IERC20 token) internal virtual {
        handler_.attachToken(token);
    }

    // Allow derived tests to set the SUT instance
    function _setSut(IERC20 _sut) internal {
        tokenSubject = _sut;
    }

    function setUp() public virtual {
        // Deploy the concrete stub and pass it into the handler from the TestBase
        handler = _deployHandler();
        tokenSubject = _deployToken(handler);
        _registerToken(handler, tokenSubject);
        // set the TestBase sut pointer to the handler's deployed instance
        // _setSut(tokenSubject);

        // Register handler as the fuzz target and explicitly choose selectors
        targetContract(address(handler));

        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = handler.transfer.selector;
        selectors[1] = handler.approve.selector;
        selectors[2] = handler.transferFrom.selector;

        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));

        // (no permit selector registration in the generic ERC20 base)
    }

    // Invariant: totalSupply equals the sum of balances across tracked addresses
    function invariant_totalSupply_equals_sumBalances() public view {
        address[] memory addrs = handler.asAddresses();
        uint256 sum = 0;
        for (uint256 i = 0; i < addrs.length; i++) {
            sum += handler.balanceOf(addrs[i]);
        }
        uint256 reported = handler.totalSupply();
        assertEq(sum, reported);
    }

    // Invariant: balances are never negative (uint) and totalSupply is non-negative
    function invariant_nonnegative() public view {
        address[] memory addrs = handler.asAddresses();
        for (uint256 i = 0; i < addrs.length; i++) {
            uint256 b = handler.balanceOf(addrs[i]);
            assert(b >= 0);
        }
        assert(handler.totalSupply() >= 0);
    }

    // Invariant: allowances reported by the contract match the handler's expected allowances
    function invariant_allowances_consistent() public view {
        uint256 pc = handler.pairCount();
        for (uint256 i = 0; i < pc; i++) {
            (address owner, address spender, uint256 expected) = handler.pairAt(i);
            uint256 actual = handler.allowance(owner, spender);
            assertEq(actual, expected);
        }
    }
}
