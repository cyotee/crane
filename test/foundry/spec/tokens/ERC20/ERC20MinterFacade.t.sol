// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {CraneTest} from "@crane/contracts/test/CraneTest.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IOperable} from "@crane/contracts/interfaces/IOperable.sol";
import {IERC20MintBurn} from "@crane/contracts/interfaces/IERC20MintBurn.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {AccessFacetFactoryService} from "@crane/contracts/access/AccessFacetFactoryService.sol";
import {ICreate3FactoryProxy} from "@crane/contracts/interfaces/proxies/ICreate3FactoryProxy.sol";

import {ERC20Facet} from "@crane/contracts/tokens/ERC20/ERC20Facet.sol";
import {ERC2612Facet} from "@crane/contracts/tokens/ERC2612/ERC2612Facet.sol";
import {ERC5267Facet} from "@crane/contracts/utils/cryptography/ERC5267/ERC5267Facet.sol";
import {ERC20MintBurnOwnableFacet} from "@crane/contracts/tokens/ERC20/ERC20MintBurnOwnableFacet.sol";
import {
    IERC20MintBurnOwnableOperableDFPkg,
    ERC20MintBurnOwnableOperableDFPkg
} from "@crane/contracts/tokens/ERC20/ERC20MintBurnOwnableOperableDFPkg.sol";
import {IERC20MinterFacade} from "@crane/contracts/tokens/ERC20/IERC20MinterFacade.sol";
import {
    ERC20MinterFacadeFacetDFPkg,
    IERC20MinterFacadeFacetDFPkg
} from "@crane/contracts/tokens/ERC20/ERC20MinterFacadeFacetDFPkg.sol";

/// @title ERC20MinterFacade_Test
/// @notice Production-path tests for D42: last-mint interval is keyed by (token, recipient).
contract ERC20MinterFacade_Test is CraneTest {
    using BetterEfficientHashLib for bytes;
    using AccessFacetFactoryService for ICreate3FactoryProxy;

    uint256 internal constant MAX_MINT = 10_000_000e18;
    uint256 internal constant MIN_INTERVAL = 1 hours;

    IERC20MinterFacade internal facade;
    IERC20MintBurn internal tokenA;
    IERC20MintBurn internal tokenB;
    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    function setUp() public virtual override {
        CraneTest.setUp();

        IFacet erc20Facet =
            create3Factory.deployFacet(type(ERC20Facet).creationCode, abi.encode(type(ERC20Facet).name)._hash());
        IFacet erc2612Facet =
            create3Factory.deployFacet(type(ERC2612Facet).creationCode, abi.encode(type(ERC2612Facet).name)._hash());
        IFacet erc5267Facet =
            create3Factory.deployFacet(type(ERC5267Facet).creationCode, abi.encode(type(ERC5267Facet).name)._hash());
        IFacet mintBurnFacet = create3Factory.deployFacet(
            type(ERC20MintBurnOwnableFacet).creationCode, abi.encode(type(ERC20MintBurnOwnableFacet).name)._hash()
        );
        IFacet ownableFacet = create3Factory.deployMultiStepOwnableFacet();
        IFacet operableFacet = create3Factory.deployOperableFacet();

        IERC20MintBurnOwnableOperableDFPkg.PkgInit memory tokenInit;
        tokenInit.erc20Facet = erc20Facet;
        tokenInit.erc5267Facet = erc5267Facet;
        tokenInit.erc2612Facet = erc2612Facet;
        tokenInit.erc20MintBurnOwnableFacet = mintBurnFacet;
        tokenInit.mutiStepOwnableFacet = ownableFacet;
        tokenInit.operableFacet = operableFacet;
        tokenInit.diamondFactory = diamondPackageFactory;

        IERC20MintBurnOwnableOperableDFPkg tokenPkg = IERC20MintBurnOwnableOperableDFPkg(
            address(
                create3Factory.deployPackageWithArgs(
                    type(ERC20MintBurnOwnableOperableDFPkg).creationCode,
                    abi.encode(tokenInit),
                    abi.encode(type(ERC20MintBurnOwnableOperableDFPkg).name)._hash()
                )
            )
        );

        tokenA = IERC20MintBurn(tokenPkg.deployToken("Token A", "TKA", 18, address(this), keccak256("TKA")));
        tokenB = IERC20MintBurn(tokenPkg.deployToken("Token B", "TKB", 18, address(this), keccak256("TKB")));

        IERC20MinterFacadeFacetDFPkg facadePkg = IERC20MinterFacadeFacetDFPkg(
            address(
                create3Factory.deployPackage(
                    type(ERC20MinterFacadeFacetDFPkg).creationCode,
                    abi.encode(type(ERC20MinterFacadeFacetDFPkg).name)._hash()
                )
            )
        );
        facade = IERC20MinterFacade(
            diamondPackageFactory.deploy(
                facadePkg,
                abi.encode(
                    IERC20MinterFacadeFacetDFPkg.PkgArgs({maxMintAmount: MAX_MINT, minMintInterval: MIN_INTERVAL})
                )
            )
        );

        IOperable(address(tokenA)).setOperatorFor(IERC20MintBurn.mint.selector, address(facade), true);
        IOperable(address(tokenB)).setOperatorFor(IERC20MintBurn.mint.selector, address(facade), true);
    }

    function test_mintToken_sameTokenRecipient_blocksUntilInterval() public {
        assertTrue(facade.mintToken(tokenA, 1e18, alice));
        assertEq(IERC20(address(tokenA)).balanceOf(alice), 1e18);

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20MinterFacade.MinimumMintInternalNotMet.selector, block.timestamp, block.timestamp, MIN_INTERVAL
            )
        );
        facade.mintToken(tokenA, 1e18, alice);

        vm.warp(block.timestamp + MIN_INTERVAL);
        assertTrue(facade.mintToken(tokenA, 2e18, alice));
        assertEq(IERC20(address(tokenA)).balanceOf(alice), 3e18);
    }

    function test_mintToken_differentTokenSameRecipient_doesNotBlock() public {
        assertTrue(facade.mintToken(tokenA, 1e18, alice));
        assertTrue(facade.mintToken(tokenB, 4e18, alice));
        assertEq(IERC20(address(tokenA)).balanceOf(alice), 1e18);
        assertEq(IERC20(address(tokenB)).balanceOf(alice), 4e18);
    }

    function test_mintToken_sameTokenDifferentRecipient_doesNotBlock() public {
        assertTrue(facade.mintToken(tokenA, 1e18, alice));
        assertTrue(facade.mintToken(tokenA, 5e18, bob));
        assertEq(IERC20(address(tokenA)).balanceOf(alice), 1e18);
        assertEq(IERC20(address(tokenA)).balanceOf(bob), 5e18);
    }

    function test_mintToken_capsAtMaxMintAmount() public {
        assertTrue(facade.mintToken(tokenA, MAX_MINT + 1, alice));
        assertEq(IERC20(address(tokenA)).balanceOf(alice), MAX_MINT);
    }
}
