// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { Vat } from "../../core/Vat.sol";
import { Dai } from "../../core/Dai.sol";
import { GemJoin, DaiJoin } from "../../core/Join.sol";
import { Jug } from "../../core/Jug.sol";
import { Pot } from "../../core/Pot.sol";
import { Spotter } from "../../core/Spot.sol";
import { Vow } from "../../core/Vow.sol";
import { Dog } from "../../core/Dog.sol";
import { End } from "../../core/End.sol";

import { SkyDssFactoryService } from "../../services/SkyDssFactoryService.sol";
import { MockChainlog } from "../mocks/MockChainlog.sol";

/// @title DSValue
/// @notice Simple price feed mock for testing
contract DSValue {
    bool public has;
    bytes32 public val;

    function peek() external view returns (bytes32, bool) {
        return (val, has);
    }

    function read() external view returns (bytes32) {
        require(has, "DSValue/no-value");
        return val;
    }

    function poke(bytes32 wut) external {
        val = wut;
        has = true;
    }

    function void() external {
        val = bytes32(0);
        has = false;
    }
}

/// @title MockGem
/// @notice Simple ERC20 mock for testing collateral tokens
contract MockGem {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function burn(address from, uint256 amount) external {
        balanceOf[from] -= amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return transferFrom(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        if (from != msg.sender && allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= amount;
        }
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}

/// @title TestBase_SkyDss
/// @notice Base test contract for Sky/DSS testing
/// @dev Provides a fully deployed DSS system with helper functions for CDP operations
abstract contract TestBase_SkyDss is Test {
    // Constants
    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;
    uint256 constant RAD = 10 ** 45;

    // Default ilk for testing
    bytes32 constant DEFAULT_ILK = "TEST-A";

    // Core contracts
    Vat public vat;
    Dai public dai;
    DaiJoin public daiJoin;
    Jug public jug;
    Pot public pot;
    Spotter public spotter;
    Vow public vow;
    Dog public dog;
    End public end;
    MockChainlog public chainlog;

    // Test collateral
    MockGem public gem;
    GemJoin public gemJoin;
    DSValue public pip;

    // Test users
    address public alice;
    address public bob;
    address public charlie;

    function setUp() public virtual {
        // Create test users
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");

        // Deploy DSS
        SkyDssFactoryService.DssDeployment memory deployment = SkyDssFactoryService.deployDss(block.chainid);

        // Store references
        vat = deployment.vat;
        dai = deployment.dai;
        daiJoin = deployment.daiJoin;
        jug = deployment.jug;
        pot = deployment.pot;
        spotter = deployment.spotter;
        vow = deployment.vow;
        dog = deployment.dog;
        end = deployment.end;
        chainlog = deployment.chainlog;

        // Set default parameters
        SkyDssFactoryService.setDefaultParameters(deployment);

        // Deploy test collateral
        gem = new MockGem("Test Gem", "GEM", 18);
        pip = new DSValue();
        pip.poke(bytes32(uint256(1000 * WAD))); // $1000 per gem

        // Initialize test ilk
        gemJoin = SkyDssFactoryService.initIlk(deployment, DEFAULT_ILK, address(gem), address(pip));

        // Give test contract admin access
        vat.rely(address(this));
        dai.rely(address(this));
    }

    // --- Helper Functions ---

    /// @notice Mint collateral tokens to a user
    function mintGem(address usr, uint256 amount) internal {
        gem.mint(usr, amount);
    }

    /// @notice Open a CDP: deposit collateral and draw DAI
    /// @param usr The user address
    /// @param collateral Amount of collateral to lock (in wad)
    /// @param daiAmount Amount of DAI to draw (in wad)
    function openCdp(address usr, uint256 collateral, uint256 daiAmount) internal {
        // Mint and approve collateral
        gem.mint(usr, collateral);
        vm.startPrank(usr);
        gem.approve(address(gemJoin), collateral);

        // Join collateral
        gemJoin.join(usr, collateral);

        // Allow vat to manipulate usr's position
        vat.hope(address(this));
        vm.stopPrank();

        // Frob: lock collateral and draw debt
        vat.frob(
            DEFAULT_ILK,
            usr,
            usr,
            usr,
            int256(collateral),
            int256(daiAmount)
        );

        // Exit DAI
        vm.startPrank(usr);
        vat.hope(address(daiJoin));
        daiJoin.exit(usr, daiAmount);
        vm.stopPrank();
    }

    /// @notice Lock collateral into a CDP without drawing DAI
    function lockCollateral(address usr, uint256 amount) internal {
        gem.mint(usr, amount);
        vm.startPrank(usr);
        gem.approve(address(gemJoin), amount);
        gemJoin.join(usr, amount);

        vat.hope(address(this));
        vm.stopPrank();

        vat.frob(DEFAULT_ILK, usr, usr, usr, int256(amount), 0);
    }

    /// @notice Draw DAI from an existing CDP
    function drawDai(address usr, uint256 amount) internal {
        vm.startPrank(usr);
        vat.hope(address(this));
        vm.stopPrank();

        vat.frob(DEFAULT_ILK, usr, usr, usr, 0, int256(amount));

        vm.startPrank(usr);
        vat.hope(address(daiJoin));
        daiJoin.exit(usr, amount);
        vm.stopPrank();
    }

    /// @notice Repay DAI debt
    function wipeDai(address usr, uint256 amount) internal {
        vm.startPrank(usr);
        dai.approve(address(daiJoin), amount);
        daiJoin.join(usr, amount);

        vat.hope(address(this));
        vm.stopPrank();

        vat.frob(DEFAULT_ILK, usr, usr, usr, 0, -int256(amount));
    }

    /// @notice Free (withdraw) collateral from a CDP
    /// @dev The frob removes collateral from the vault, and exit transfers it to the user.
    ///      GemJoin.exit() calls vat.slip(ilk, msg.sender, -amount), so we must call it
    ///      from the user's context since they hold the internal gem balance.
    function freeCollateral(address usr, uint256 amount) internal {
        vm.startPrank(usr);
        vat.hope(address(this));
        vm.stopPrank();

        // Remove collateral from the CDP (this moves gems from urn to usr's internal balance)
        vat.frob(DEFAULT_ILK, usr, usr, usr, -int256(amount), 0);

        // Exit gems from vat to ERC20 tokens - must be called by usr since
        // GemJoin.exit() calls vat.slip(ilk, msg.sender, -amount)
        vm.prank(usr);
        gemJoin.exit(usr, amount);
    }

    /// @notice Get the current collateralization ratio of a CDP
    /// @return ratio The collateralization ratio in ray (1e27 = 100%)
    function getCollateralRatio(address usr) internal view returns (uint256 ratio) {
        (uint256 ink, uint256 art) = vat.urns(DEFAULT_ILK, usr);
        (, uint256 rate, uint256 spot,,) = vat.ilks(DEFAULT_ILK);

        if (art == 0) return type(uint256).max;

        // ratio = (ink * spot) / (art * rate)
        uint256 collateralValue = ink * spot;
        uint256 debtValue = art * rate;

        ratio = collateralValue * RAY / debtValue;
    }

    /// @notice Check if a CDP is safe (not undercollateralized)
    function isSafe(address usr) internal view returns (bool) {
        (uint256 ink, uint256 art) = vat.urns(DEFAULT_ILK, usr);
        (, uint256 rate, uint256 spot,,) = vat.ilks(DEFAULT_ILK);

        return art * rate <= ink * spot;
    }

    /// @notice Update the price feed
    function setPrice(uint256 price) internal {
        pip.poke(bytes32(price));
        spotter.poke(DEFAULT_ILK);
    }

    /// @notice Accumulate stability fees
    function drip() internal {
        jug.drip(DEFAULT_ILK);
    }

    /// @notice Warp time forward
    function warpForward(uint256 seconds_) internal {
        vm.warp(block.timestamp + seconds_);
    }

    /// @notice Get user's DAI balance
    function daiBalance(address usr) internal view returns (uint256) {
        return dai.balanceOf(usr);
    }

    /// @notice Get user's gem balance
    function gemBalance(address usr) internal view returns (uint256) {
        return gem.balanceOf(usr);
    }

    /// @notice Get user's internal vat DAI balance
    function vatDai(address usr) internal view returns (uint256) {
        return vat.dai(usr);
    }

    /// @notice Get user's urn (CDP position)
    function getUrn(address usr) internal view returns (uint256 ink, uint256 art) {
        return vat.urns(DEFAULT_ILK, usr);
    }
}
