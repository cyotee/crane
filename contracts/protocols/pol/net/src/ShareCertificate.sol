// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

/// @title ShareCertificate — soulbound founding-shareholder certificate
/// @notice specs/genesis.md §1 (FINAL): a non-transferable ERC-721 "share
///         certificate" minted at purchase, metadata = bond amount (WAD USDG,
///         cumulative across a wallet's purchases), first-purchase timestamp,
///         and shareholder number. One certificate per founding shareholder.
///         GenesisBond calls this best-effort — a certificate failure must
///         never revert a bond purchase; the registry entry always lands.
///         No perk is promised in code; the certificate preserves the cohort.
contract ShareCertificate {
    error Soulbound();
    error NotGenesisBond();
    error NonexistentToken();
    error ZeroAddress();

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    struct Certificate {
        uint96 bondAmountWad;
        uint64 firstPurchaseAt;
        uint32 shareholderNumber;
    }

    string public constant name = "NetNet Founding Shareholder Certificate";
    string public constant symbol = "NET-FS";

    address public immutable genesisBond;
    uint256 public nextId = 1;
    mapping(uint256 => address) private _ownerOf;
    mapping(address => uint256) public certificateOf; // 0 = none
    mapping(uint256 => Certificate) public certificates;

    constructor(address genesisBond_) {
        if (genesisBond_ == address(0)) revert ZeroAddress();
        genesisBond = genesisBond_;
    }

    /// @notice Records a purchase: mints on a wallet's first purchase, then
    ///         accumulates the certified bond amount. GenesisBond only.
    function recordPurchase(address to, uint256 usdgAmountWad) external returns (uint256 tokenId) {
        if (msg.sender != genesisBond) revert NotGenesisBond();
        tokenId = certificateOf[to];
        if (tokenId == 0) {
            tokenId = nextId++;
            _ownerOf[tokenId] = to;
            certificateOf[to] = tokenId;
            certificates[tokenId] = Certificate({
                bondAmountWad: uint96(usdgAmountWad),
                firstPurchaseAt: uint64(block.timestamp),
                shareholderNumber: uint32(tokenId)
            });
            emit Transfer(address(0), to, tokenId);
        } else {
            certificates[tokenId].bondAmountWad += uint96(usdgAmountWad);
        }
    }

    function ownerOf(uint256 tokenId) external view returns (address owner) {
        owner = _ownerOf[tokenId];
        if (owner == address(0)) revert NonexistentToken();
    }

    function balanceOf(address owner) external view returns (uint256) {
        return certificateOf[owner] == 0 ? 0 : 1;
    }

    function totalIssued() external view returns (uint256) {
        return nextId - 1;
    }

    // ── ERC-721 transfer surface: soulbound, all revert ──

    function transferFrom(address, address, uint256) external pure {
        revert Soulbound();
    }

    function safeTransferFrom(address, address, uint256) external pure {
        revert Soulbound();
    }

    function safeTransferFrom(address, address, uint256, bytes calldata) external pure {
        revert Soulbound();
    }

    function approve(address, uint256) external pure {
        revert Soulbound();
    }

    function setApprovalForAll(address, bool) external pure {
        revert Soulbound();
    }

    function getApproved(uint256) external pure returns (address) {
        return address(0);
    }

    function isApprovedForAll(address, address) external pure returns (bool) {
        return false;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x01ffc9a7 || interfaceId == 0x80ac58cd; // ERC-165, ERC-721
    }
}
