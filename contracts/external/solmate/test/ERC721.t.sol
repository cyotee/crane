// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.35;

import {DSTestPlus} from "./utils/DSTestPlus.sol";
import {DSInvariantTest} from "./utils/DSInvariantTest.sol";

import {MockERC721} from "./utils/mocks/MockERC721.sol";

import {ERC721TokenReceiver} from "../tokens/ERC721.sol";
import {Vm} from "forge-std/Vm.sol";

contract ERC721Recipient is ERC721TokenReceiver {
    address public operator;
    address public from;
    uint256 public id;
    bytes public data;

    function onERC721Received(address _operator, address _from, uint256 _id, bytes calldata _data)
        public
        virtual
        override
        returns (bytes4)
    {
        operator = _operator;
        from = _from;
        id = _id;
        data = _data;

        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

contract RevertingERC721Recipient is ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) public virtual override returns (bytes4) {
        revert(string(abi.encodePacked(ERC721TokenReceiver.onERC721Received.selector)));
    }
}

contract WrongReturnDataERC721Recipient is ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) public virtual override returns (bytes4) {
        return 0xCAFEBEEF;
    }
}

contract NonERC721Recipient {}

contract ERC721Test is DSTestPlus {
    MockERC721 token;
    RevertingERC721Recipient revertingRecipient;
    WrongReturnDataERC721Recipient wrongReturnRecipient;
    NonERC721Recipient nonRecipient;

    Vm internal constant vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    function setUp() public {
        token = new MockERC721("Token", "TKN");
        revertingRecipient = new RevertingERC721Recipient();
        wrongReturnRecipient = new WrongReturnDataERC721Recipient();
        nonRecipient = new NonERC721Recipient();
    }

    function invariantMetadata() public {
        assertEq(token.name(), "Token");
        assertEq(token.symbol(), "TKN");
    }

    function testMint() public {
        token.mint(address(0xBEEF), 1337);

        assertEq(token.balanceOf(address(0xBEEF)), 1);
        assertEq(token.ownerOf(1337), address(0xBEEF));
    }

    function testBurn() public {
        token.mint(address(0xBEEF), 1337);
        token.burn(1337);

        assertEq(token.balanceOf(address(0xBEEF)), 0);

        hevm.expectRevert("NOT_MINTED");
        token.ownerOf(1337);
    }

    function testApprove() public {
        token.mint(address(this), 1337);

        token.approve(address(0xBEEF), 1337);

        assertEq(token.getApproved(1337), address(0xBEEF));
    }

    function testApproveBurn() public {
        token.mint(address(this), 1337);

        token.approve(address(0xBEEF), 1337);

        token.burn(1337);

        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.getApproved(1337), address(0));

        vm.expectRevert("NOT_MINTED");
        token.ownerOf(1337);
    }

    function testApproveAll() public {
        token.setApprovalForAll(address(0xBEEF), true);

        assertTrue(token.isApprovedForAll(address(this), address(0xBEEF)));
    }

    function testTransferFrom() public {
        address from = address(0xABCD);

        token.mint(from, 1337);

        hevm.prank(from);
        token.approve(address(this), 1337);

        token.transferFrom(from, address(0xBEEF), 1337);

        assertEq(token.getApproved(1337), address(0));
        assertEq(token.ownerOf(1337), address(0xBEEF));
        assertEq(token.balanceOf(address(0xBEEF)), 1);
        assertEq(token.balanceOf(from), 0);
    }

    function testTransferFromSelf() public {
        token.mint(address(this), 1337);

        token.transferFrom(address(this), address(0xBEEF), 1337);

        assertEq(token.getApproved(1337), address(0));
        assertEq(token.ownerOf(1337), address(0xBEEF));
        assertEq(token.balanceOf(address(0xBEEF)), 1);
        assertEq(token.balanceOf(address(this)), 0);
    }

    function testTransferFromApproveAll() public {
        address from = address(0xABCD);

        token.mint(from, 1337);

        hevm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.transferFrom(from, address(0xBEEF), 1337);

        assertEq(token.getApproved(1337), address(0));
        assertEq(token.ownerOf(1337), address(0xBEEF));
        assertEq(token.balanceOf(address(0xBEEF)), 1);
        assertEq(token.balanceOf(from), 0);
    }

    function testSafeTransferFromToEOA() public {
        address from = address(0xABCD);

        token.mint(from, 1337);

        hevm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, address(0xBEEF), 1337);

        assertEq(token.getApproved(1337), address(0));
        assertEq(token.ownerOf(1337), address(0xBEEF));
        assertEq(token.balanceOf(address(0xBEEF)), 1);
        assertEq(token.balanceOf(from), 0);
    }

    function testSafeTransferFromToERC721Recipient() public {
        address from = address(0xABCD);
        ERC721Recipient recipient = new ERC721Recipient();

        token.mint(from, 1337);

        hevm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, address(recipient), 1337);

        assertEq(token.getApproved(1337), address(0));
        assertEq(token.ownerOf(1337), address(recipient));
        assertEq(token.balanceOf(address(recipient)), 1);
        assertEq(token.balanceOf(from), 0);

        assertEq(recipient.operator(), address(this));
        assertEq(recipient.from(), from);
        assertEq(recipient.id(), 1337);
        assertBytesEq(recipient.data(), "");
    }

    function testSafeTransferFromToERC721RecipientWithData() public {
        address from = address(0xABCD);
        ERC721Recipient recipient = new ERC721Recipient();

        token.mint(from, 1337);

        hevm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, address(recipient), 1337, "testing 123");

        assertEq(token.getApproved(1337), address(0));
        assertEq(token.ownerOf(1337), address(recipient));
        assertEq(token.balanceOf(address(recipient)), 1);
        assertEq(token.balanceOf(from), 0);

        assertEq(recipient.operator(), address(this));
        assertEq(recipient.from(), from);
        assertEq(recipient.id(), 1337);
        assertBytesEq(recipient.data(), "testing 123");
    }

    function testSafeMintToEOA() public {
        token.safeMint(address(0xBEEF), 1337);

        assertEq(token.ownerOf(1337), address(address(0xBEEF)));
        assertEq(token.balanceOf(address(address(0xBEEF))), 1);
    }

    function testSafeMintToERC721Recipient() public {
        ERC721Recipient to = new ERC721Recipient();

        token.safeMint(address(to), 1337);

        assertEq(token.ownerOf(1337), address(to));
        assertEq(token.balanceOf(address(to)), 1);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), address(0));
        assertEq(to.id(), 1337);
        assertBytesEq(to.data(), "");
    }

    function testSafeMintToERC721RecipientWithData() public {
        ERC721Recipient to = new ERC721Recipient();

        token.safeMint(address(to), 1337, "testing 123");

        assertEq(token.ownerOf(1337), address(to));
        assertEq(token.balanceOf(address(to)), 1);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), address(0));
        assertEq(to.id(), 1337);
        assertBytesEq(to.data(), "testing 123");
    }

    function test_RevertWhen_MintToZero() public {
        vm.expectRevert();
        token.mint(address(0), 1337);
    }

    function test_RevertWhen_DoubleMint() public {
        token.mint(address(0xBEEF), 1337);
        vm.expectRevert();
        token.mint(address(0xBEEF), 1337);
    }

    function test_RevertWhen_BurnUnMinted() public {
        vm.expectRevert();
        token.burn(1337);
    }

    function test_RevertWhen_DoubleBurn() public {
        token.mint(address(0xBEEF), 1337);

        token.burn(1337);
        vm.expectRevert();
        token.burn(1337);
    }

    function test_RevertWhen_ApproveUnMinted() public {
        vm.expectRevert();
        token.approve(address(0xBEEF), 1337);
    }

    function test_RevertWhen_ApproveUnAuthorized() public {
        token.mint(address(0xCAFE), 1337);

        vm.expectRevert();
        token.approve(address(0xBEEF), 1337);
    }

    function test_RevertWhen_TransferFromUnOwned() public {
        vm.expectRevert();
        token.transferFrom(address(0xFEED), address(0xBEEF), 1337);
    }

    function test_RevertWhen_TransferFromWrongFrom() public {
        token.mint(address(0xCAFE), 1337);

        vm.expectRevert();
        token.transferFrom(address(0xFEED), address(0xBEEF), 1337);
    }

    function test_RevertWhen_TransferFromToZero() public {
        token.mint(address(this), 1337);

        vm.expectRevert();
        token.transferFrom(address(this), address(0), 1337);
    }

    function test_RevertWhen_TransferFromNotOwner() public {
        token.mint(address(0xFEED), 1337);

        vm.expectRevert();
        token.transferFrom(address(0xFEED), address(0xBEEF), 1337);
    }

    function test_RevertWhen_SafeTransferFromToNonERC721Recipient() public {
        token.mint(address(this), 1337);

        vm.expectRevert();
        token.safeTransferFrom(address(this), address(nonRecipient), 1337);
    }

    function test_RevertWhen_SafeTransferFromToNonERC721RecipientWithData() public {
        token.mint(address(this), 1337);

        vm.expectRevert();
        token.safeTransferFrom(address(this), address(nonRecipient), 1337, "testing 123");
    }

    function test_RevertWhen_SafeTransferFromToRevertingERC721Recipient() public {
        token.mint(address(this), 1337);

        vm.expectRevert();
        token.safeTransferFrom(address(this), address(revertingRecipient), 1337);
    }

    function test_RevertWhen_SafeTransferFromToRevertingERC721RecipientWithData() public {
        token.mint(address(this), 1337);

        vm.expectRevert();
        token.safeTransferFrom(address(this), address(revertingRecipient), 1337, "testing 123");
    }

    function test_RevertWhen_SafeTransferFromToERC721RecipientWithWrongReturnData() public {
        token.mint(address(this), 1337);

        vm.expectRevert();
        token.safeTransferFrom(address(this), address(wrongReturnRecipient), 1337);
    }

    function test_RevertWhen_SafeTransferFromToERC721RecipientWithWrongReturnDataWithData() public {
        token.mint(address(this), 1337);

        vm.expectRevert();
        token.safeTransferFrom(address(this), address(wrongReturnRecipient), 1337, "testing 123");
    }

    function test_RevertWhen_SafeMintToNonERC721Recipient() public {
        vm.expectRevert();
        token.safeMint(address(nonRecipient), 1337);
    }

    function test_RevertWhen_SafeMintToNonERC721RecipientWithData() public {
        vm.expectRevert();
        token.safeMint(address(nonRecipient), 1337, "testing 123");
    }

    function test_RevertWhen_SafeMintToRevertingERC721Recipient() public {
        vm.expectRevert();
        token.safeMint(address(revertingRecipient), 1337);
    }

    function test_RevertWhen_SafeMintToRevertingERC721RecipientWithData() public {
        vm.expectRevert();
        token.safeMint(address(revertingRecipient), 1337, "testing 123");
    }

    function test_RevertWhen_SafeMintToERC721RecipientWithWrongReturnData() public {
        vm.expectRevert();
        token.safeMint(address(wrongReturnRecipient), 1337);
    }

    function test_RevertWhen_SafeMintToERC721RecipientWithWrongReturnDataWithData() public {
        vm.expectRevert();
        token.safeMint(address(wrongReturnRecipient), 1337, "testing 123");
    }

    function test_RevertWhen_BalanceOfZeroAddress() public {
        vm.expectRevert();
        token.balanceOf(address(0));
    }

    function test_RevertWhen_OwnerOfUnminted() public {
        vm.expectRevert();
        token.ownerOf(1337);
    }

    function testMetadata(string memory name, string memory symbol) public {
        MockERC721 tkn = new MockERC721(name, symbol);

        assertEq(tkn.name(), name);
        assertEq(tkn.symbol(), symbol);
    }

    function testMint(address to, uint256 id) public {
        if (to == address(0)) to = address(0xBEEF);

        token.mint(to, id);

        assertEq(token.balanceOf(to), 1);
        assertEq(token.ownerOf(id), to);
    }

    function testBurn(address to, uint256 id) public {
        if (to == address(0)) to = address(0xBEEF);

        token.mint(to, id);
        token.burn(id);

        assertEq(token.balanceOf(to), 0);

        vm.expectRevert("NOT_MINTED");
        token.ownerOf(id);
    }

    function testApprove(address to, uint256 id) public {
        if (to == address(0)) to = address(0xBEEF);

        token.mint(address(this), id);

        token.approve(to, id);

        assertEq(token.getApproved(id), to);
    }

    function testApproveBurn(address to, uint256 id) public {
        token.mint(address(this), id);

        token.approve(address(to), id);

        token.burn(id);

        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.getApproved(id), address(0));

        vm.expectRevert("NOT_MINTED");
        token.ownerOf(id);
    }

    function testApproveAll(address to, bool approved) public {
        token.setApprovalForAll(to, approved);

        assertBoolEq(token.isApprovedForAll(address(this), to), approved);
    }

    function testTransferFrom(uint256 id, address to) public {
        address from = address(0xABCD);

        if (to == address(0) || to == from) to = address(0xBEEF);

        token.mint(from, id);

        hevm.prank(from);
        token.approve(address(this), id);

        token.transferFrom(from, to, id);

        assertEq(token.getApproved(id), address(0));
        assertEq(token.ownerOf(id), to);
        assertEq(token.balanceOf(to), 1);
        assertEq(token.balanceOf(from), 0);
    }

    function testTransferFromSelf(uint256 id, address to) public {
        if (to == address(0) || to == address(this)) to = address(0xBEEF);

        token.mint(address(this), id);

        token.transferFrom(address(this), to, id);

        assertEq(token.getApproved(id), address(0));
        assertEq(token.ownerOf(id), to);
        assertEq(token.balanceOf(to), 1);
        assertEq(token.balanceOf(address(this)), 0);
    }

    function testTransferFromApproveAll(uint256 id, address to) public {
        address from = address(0xABCD);

        if (to == address(0) || to == from) to = address(0xBEEF);

        token.mint(from, id);

        hevm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.transferFrom(from, to, id);

        assertEq(token.getApproved(id), address(0));
        assertEq(token.ownerOf(id), to);
        assertEq(token.balanceOf(to), 1);
        assertEq(token.balanceOf(from), 0);
    }

    function testSafeTransferFromToEOA(uint256 id, address to) public {
        address from = address(0xABCD);

        if (to == address(0) || to == from) to = address(0xBEEF);

        if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;

        token.mint(from, id);

        hevm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, to, id);

        assertEq(token.getApproved(id), address(0));
        assertEq(token.ownerOf(id), to);
        assertEq(token.balanceOf(to), 1);
        assertEq(token.balanceOf(from), 0);
    }

    function testSafeTransferFromToERC721Recipient(uint256 id) public {
        address from = address(0xABCD);

        ERC721Recipient recipient = new ERC721Recipient();

        token.mint(from, id);

        hevm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, address(recipient), id);

        assertEq(token.getApproved(id), address(0));
        assertEq(token.ownerOf(id), address(recipient));
        assertEq(token.balanceOf(address(recipient)), 1);
        assertEq(token.balanceOf(from), 0);

        assertEq(recipient.operator(), address(this));
        assertEq(recipient.from(), from);
        assertEq(recipient.id(), id);
        assertBytesEq(recipient.data(), "");
    }

    function testSafeTransferFromToERC721RecipientWithData(uint256 id, bytes calldata data) public {
        address from = address(0xABCD);
        ERC721Recipient recipient = new ERC721Recipient();

        token.mint(from, id);

        hevm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, address(recipient), id, data);

        assertEq(token.getApproved(id), address(0));
        assertEq(token.ownerOf(id), address(recipient));
        assertEq(token.balanceOf(address(recipient)), 1);
        assertEq(token.balanceOf(from), 0);

        assertEq(recipient.operator(), address(this));
        assertEq(recipient.from(), from);
        assertEq(recipient.id(), id);
        assertBytesEq(recipient.data(), data);
    }

    function testSafeMintToEOA(uint256 id, address to) public {
        if (to == address(0)) to = address(0xBEEF);

        if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;

        token.safeMint(to, id);

        assertEq(token.ownerOf(id), address(to));
        assertEq(token.balanceOf(address(to)), 1);
    }

    function testSafeMintToERC721Recipient(uint256 id) public {
        ERC721Recipient to = new ERC721Recipient();

        token.safeMint(address(to), id);

        assertEq(token.ownerOf(id), address(to));
        assertEq(token.balanceOf(address(to)), 1);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), address(0));
        assertEq(to.id(), id);
        assertBytesEq(to.data(), "");
    }

    function testSafeMintToERC721RecipientWithData(uint256 id, bytes calldata data) public {
        ERC721Recipient to = new ERC721Recipient();

        token.safeMint(address(to), id, data);

        assertEq(token.ownerOf(id), address(to));
        assertEq(token.balanceOf(address(to)), 1);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), address(0));
        assertEq(to.id(), id);
        assertBytesEq(to.data(), data);
    }

    function test_RevertWhen_MintToZero(uint256 id) public {
        vm.expectRevert();
        token.mint(address(0), id);
    }

    function test_RevertWhen_DoubleMint(uint256 id, address to) public {
        if (to == address(0)) to = address(0xBEEF);

        token.mint(to, id);
        vm.expectRevert();
        token.mint(to, id);
    }

    function test_RevertWhen_BurnUnMinted(uint256 id) public {
        vm.expectRevert();
        token.burn(id);
    }

    function test_RevertWhen_DoubleBurn(uint256 id, address to) public {
        if (to == address(0)) to = address(0xBEEF);

        token.mint(to, id);

        token.burn(id);
        vm.expectRevert();
        token.burn(id);
    }

    function test_RevertWhen_ApproveUnMinted(uint256 id, address to) public {
        vm.expectRevert();
        token.approve(to, id);
    }

    function test_RevertWhen_ApproveUnAuthorized(address owner, uint256 id, address to) public {
        if (owner == address(0) || owner == address(this)) owner = address(0xBEEF);

        token.mint(owner, id);

        vm.expectRevert();
        token.approve(to, id);
    }

    function test_RevertWhen_TransferFromUnOwned(address from, address to, uint256 id) public {
        vm.expectRevert();
        token.transferFrom(from, to, id);
    }

    function test_RevertWhen_TransferFromWrongFrom(address, address, address, uint256) public {
        address owner = address(0xBEEF);
        address from = address(0xCAFE);
        address to = address(0xDEAD);
        uint256 id = 1337;
        token.mint(owner, id);

        vm.expectRevert();
        token.transferFrom(from, to, id);
    }

    function test_RevertWhen_TransferFromToZero(uint256 id) public {
        token.mint(address(this), id);

        vm.expectRevert();
        token.transferFrom(address(this), address(0), id);
    }

    function test_RevertWhen_TransferFromNotOwner(address, address, uint256) public {
        address from = address(0xBEEF);
        address to = address(0xCAFE);
        uint256 id = 1337;
        token.mint(from, id);

        vm.expectRevert();
        token.transferFrom(from, to, id);
    }

    function test_RevertWhen_SafeTransferFromToNonERC721Recipient(uint256 id) public {
        token.mint(address(this), id);

        vm.expectRevert();
        this.safeTransferFromWrapper(address(this), address(nonRecipient), id);
    }

    function test_RevertWhen_SafeTransferFromToNonERC721RecipientWithData(uint256 id, bytes calldata data) public {
        token.mint(address(this), id);

        vm.expectRevert();
        this.safeTransferFromWrapper(address(this), address(nonRecipient), id, data);
    }

    function test_RevertWhen_SafeTransferFromToRevertingERC721Recipient(uint256) public {
        uint256 id = 1337;
        token.mint(address(this), id);

        vm.expectRevert();
        this.safeTransferFromWrapper(address(this), address(revertingRecipient), id);
    }

    function test_RevertWhen_SafeTransferFromToRevertingERC721RecipientWithData(uint256, bytes calldata) public {
        uint256 id = 1337;
        token.mint(address(this), id);

        vm.expectRevert();
        token.safeTransferFrom(address(this), address(revertingRecipient), id, "test");
    }

    function test_RevertWhen_SafeTransferFromToERC721RecipientWithWrongReturnData(uint256 id) public {
        token.mint(address(this), id);

        vm.expectRevert();
        this.safeTransferFromWrapper(address(this), address(wrongReturnRecipient), id);
    }

    function test_RevertWhen_SafeTransferFromToERC721RecipientWithWrongReturnDataWithData(
        uint256 id,
        bytes calldata data
    ) public {
        token.mint(address(this), id);

        vm.expectRevert();
        this.safeTransferFromWrapper(address(this), address(wrongReturnRecipient), id, data);
    }

    function test_RevertWhen_SafeMintToNonERC721Recipient(uint256 id) public {
        vm.expectRevert();
        this.safeMintWrapper(address(nonRecipient), id);
    }

    function test_RevertWhen_SafeMintToNonERC721RecipientWithData(uint256 id, bytes calldata data) public {
        vm.expectRevert();
        this.safeMintWrapper(address(nonRecipient), id, data);
    }

    function test_RevertWhen_SafeMintToRevertingERC721Recipient(uint256 id) public {
        vm.expectRevert();
        this.safeMintWrapper(address(revertingRecipient), id);
    }

    function test_RevertWhen_SafeMintToRevertingERC721RecipientWithData(uint256 id, bytes calldata data) public {
        vm.expectRevert();
        this.safeMintWrapper(address(revertingRecipient), id, data);
    }

    function test_RevertWhen_SafeMintToERC721RecipientWithWrongReturnData(uint256 id) public {
        vm.expectRevert();
        this.safeMintWrapper(address(wrongReturnRecipient), id);
    }

    function test_RevertWhen_SafeMintToERC721RecipientWithWrongReturnDataWithData(uint256 id, bytes calldata data)
        public
    {
        vm.expectRevert();
        this.safeMintWrapper(address(wrongReturnRecipient), id, data);
    }

    function test_RevertWhen_OwnerOfUnminted(uint256 id) public {
        vm.expectRevert();
        token.ownerOf(id);
    }

    // external wrappers to ensure vm.expectRevert observes reverts from safe hook calls
    function safeMintWrapper(address to, uint256 id) external {
        token.safeMint(to, id);
    }

    function safeMintWrapper(address to, uint256 id, bytes calldata data) external {
        token.safeMint(to, id, data);
    }

    function safeTransferFromWrapper(address from, address to, uint256 id) external {
        token.safeTransferFrom(from, to, id);
    }

    function safeTransferFromWrapper(address from, address to, uint256 id, bytes calldata data) external {
        token.safeTransferFrom(from, to, id, data);
    }
}
