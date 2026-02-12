// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "@crane/contracts/tokens/ERC20/TestBase_ERC20.sol";
import "@crane/contracts/interfaces/IERC2612.sol";
import {IERC20Permit} from "@crane/contracts/interfaces/IERC20Permit.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

/// Test base that adds ERC2612 permit selectors to the fuzz target.
abstract contract TestBase_ERC20Permit is TestBase_ERC20 {
    function setUp() public virtual override {
        // call base setup which deploys handler/token and registers basic selectors
        super.setUp();

        // deploy a permit handler that will exercise the permit flows
        ERC20PermitHandler p = new ERC20PermitHandler(handler);

        // register permit handler selectors in addition to the base handler
        bytes4[] memory psel = new bytes4[](3);
        psel[0] = p.permit_valid.selector;
        psel[1] = p.permit_invalid_badSigner.selector;
        psel[2] = p.permit_invalid_expired.selector;
        targetSelector(FuzzSelector({addr: address(p), selectors: psel}));
    }
}

// Permit handler implemented alongside the permit test base so we don't modify the generic ERC20 base.
contract ERC20PermitHandler is Test {
    using BetterEfficientHashLib for bytes;

    ERC20TargetStubHandler public base;
    IERC20 public sut;

    bytes32[] internal _pairs;
    mapping(bytes32 => bool) internal _seenPair;
    mapping(bytes32 => uint256) internal _expectedAllowance;
    address[] internal _pairOwners;
    address[] internal _pairSpenders;

    constructor(ERC20TargetStubHandler _base) {
        base = _base;
        sut = IERC20(address(base.sut()));
    }

    function addrFromSeed(uint256 seed) public pure returns (address) {
        uint160 v = uint160((seed % 16) + 1);
        return address(v);
    }

    function ownerFromSeed(uint256 seed) public pure returns (address) {
        uint256 pk = uint256(seed) + 0x1000;
        return vm.addr(pk);
    }

    bytes32 internal constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    // Valid permit
    function permit_valid(uint256 ownerSeed, uint256 spenderSeed, uint256 value, uint256 deadlineOffset) external {
        address owner = ownerFromSeed(ownerSeed);
        address spender = addrFromSeed(spenderSeed);

        uint256 nonce = IERC2612(address(sut)).nonces(owner);
        uint256 deadline = block.timestamp + (deadlineOffset % 1000) + 1;

        bytes32 structHash = abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline)._hash();
        bytes32 domain = IERC20Permit(address(sut)).DOMAIN_SEPARATOR();
        bytes32 digest = abi.encodePacked("\x19\x01", domain, structHash)._hash();

        (uint8 v, bytes32 r, bytes32 s) = _sign(ownerSeed, digest);
        IERC2612(address(sut)).permit(owner, spender, value, deadline, v, r, s);

        bytes32 k = abi.encodePacked(owner, spender)._hash();
        _expectedAllowance[k] = value;
        if (!_seenPair[k]) {
            _seenPair[k] = true;
            _pairs.push(k);
            _pairOwners.push(owner);
            _pairSpenders.push(spender);
        }
    }

    function permit_invalid_badSigner(uint256 ownerSeed, uint256 spenderSeed, uint256 value, uint256 deadlineOffset)
        external
    {
        address owner = ownerFromSeed(ownerSeed);
        address spender = addrFromSeed(spenderSeed);

        uint256 nonce = IERC2612(address(sut)).nonces(owner);
        uint256 deadline = block.timestamp + (deadlineOffset % 1000) + 1;

        bytes32 structHash = abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline)._hash();
        bytes32 domain = IERC20Permit(address(sut)).DOMAIN_SEPARATOR();
        bytes32 digest = abi.encodePacked("\x19\x01", domain, structHash)._hash();

        // sign with wrong key
        (uint8 v, bytes32 r, bytes32 s) = _sign_wrong(ownerSeed, digest);
        vm.expectRevert();
        IERC2612(address(sut)).permit(owner, spender, value, deadline, v, r, s);
    }

    function permit_invalid_expired(uint256 ownerSeed, uint256 spenderSeed, uint256 value) external {
        address owner = ownerFromSeed(ownerSeed);
        address spender = addrFromSeed(spenderSeed);

        uint256 nonce = IERC2612(address(sut)).nonces(owner);
        uint256 deadline = block.timestamp - 1;

        bytes32 structHash = abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline)._hash();
        bytes32 domain = IERC20Permit(address(sut)).DOMAIN_SEPARATOR();
        bytes32 digest = abi.encodePacked("\x19\x01", domain, structHash)._hash();

        (uint8 v, bytes32 r, bytes32 s) = _sign(ownerSeed, digest);
        vm.expectRevert();
        IERC2612(address(sut)).permit(owner, spender, value, deadline, v, r, s);
    }

    function _sign(uint256 ownerSeed, bytes32 digest) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        uint256 pk = uint256(ownerSeed) + 0x1000;
        (v, r, s) = vm.sign(pk, digest);
    }

    function _sign_wrong(uint256 ownerSeed, bytes32 digest) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        uint256 pk = uint256(ownerSeed) + 0x1000 + 1;
        (v, r, s) = vm.sign(pk, digest);
    }

    // Views for invariants
    function pairCount() external view returns (uint256) {
        return _pairs.length;
    }

    function pairAt(uint256 idx) external view returns (address owner, address spender, uint256 expected) {
        owner = _pairOwners[idx];
        spender = _pairSpenders[idx];
        expected = _expectedAllowance[_pairs[idx]];
    }

    function expectedAllowance(address owner, address spender) external view returns (uint256) {
        return _expectedAllowance[abi.encodePacked(owner, spender)._hash()];
    }
}

// Add an invariant that checks permit-updated allowances
abstract contract TestBase_ERC20Permit_Invariants is TestBase_ERC20 {
    ERC20PermitHandler public permitHandler;

    function setUp() public virtual override {
        super.setUp();
        permitHandler = new ERC20PermitHandler(handler);
        bytes4[] memory psel = new bytes4[](3);
        psel[0] = permitHandler.permit_valid.selector;
        psel[1] = permitHandler.permit_invalid_badSigner.selector;
        psel[2] = permitHandler.permit_invalid_expired.selector;
        targetSelector(FuzzSelector({addr: address(permitHandler), selectors: psel}));
    }

    function invariant_permit_allowances_consistent() public view {
        uint256 pc = permitHandler.pairCount();
        for (uint256 i = 0; i < pc; i++) {
            (address owner, address spender, uint256 expected) = permitHandler.pairAt(i);
            uint256 actual = tokenSubject.allowance(owner, spender);
            assertEq(actual, expected);
        }
    }
}
