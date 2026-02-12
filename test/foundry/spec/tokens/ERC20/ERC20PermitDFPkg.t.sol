// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {ERC20PermitDFPkg, IERC20PermitDFPkg} from "@crane/contracts/tokens/ERC20/ERC20PermitDFPkg.sol";
import {ERC20Facet} from "@crane/contracts/tokens/ERC20/ERC20Facet.sol";
import {ERC5267Facet} from "@crane/contracts/utils/cryptography/ERC5267/ERC5267Facet.sol";
import {ERC2612Facet} from "@crane/contracts/tokens/ERC2612/ERC2612Facet.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IERC20Permit} from "@crane/contracts/interfaces/IERC20Permit.sol";
import {IERC5267} from "@crane/contracts/interfaces/IERC5267.sol";
import {ERC20Repo} from "@crane/contracts/tokens/ERC20/ERC20Repo.sol";
import {EIP712Repo} from "@crane/contracts/utils/cryptography/EIP712/EIP712Repo.sol";

/**
 * @title ERC20PermitDFPkg_Test
 * @notice Tests for ERC20PermitDFPkg Diamond Factory Package
 */
contract ERC20PermitDFPkg_Test is Test {
    ERC20PermitDFPkg internal pkg;
    ERC20Facet internal erc20Facet;
    ERC5267Facet internal erc5267Facet;
    ERC2612Facet internal erc2612Facet;

    address internal recipient = address(0x1234);

    function setUp() public {
        // Deploy facets
        erc20Facet = new ERC20Facet();
        erc5267Facet = new ERC5267Facet();
        erc2612Facet = new ERC2612Facet();

        // Deploy package
        pkg = new ERC20PermitDFPkg(
            IERC20PermitDFPkg.PkgInit({
                erc20Facet: IFacet(address(erc20Facet)),
                erc5267Facet: IFacet(address(erc5267Facet)),
                erc2612Facet: IFacet(address(erc2612Facet))
            })
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                           Package Metadata Tests                           */
    /* -------------------------------------------------------------------------- */

    function test_packageName_returnsCorrectName() public view {
        assertEq(pkg.packageName(), "ERC20PermitDFPkg");
    }

    function test_packageMetadata_returnsAllData() public view {
        (string memory name, bytes4[] memory interfaces, address[] memory facets) = pkg.packageMetadata();

        assertEq(name, "ERC20PermitDFPkg");
        assertEq(interfaces.length, 5);
        assertEq(facets.length, 3);
    }

    function test_facetAddresses_returnsThreeFacets() public view {
        address[] memory facets = pkg.facetAddresses();

        assertEq(facets.length, 3);
        assertEq(facets[0], address(erc20Facet));
        assertEq(facets[1], address(erc5267Facet));
        assertEq(facets[2], address(erc2612Facet));
    }

    function test_facetInterfaces_returnsFiveInterfaces() public view {
        bytes4[] memory interfaces = pkg.facetInterfaces();

        assertEq(interfaces.length, 5);
        assertEq(interfaces[0], type(IERC20).interfaceId);
        assertEq(interfaces[1], type(IERC20Metadata).interfaceId);
        assertEq(interfaces[2], type(IERC20Metadata).interfaceId ^ type(IERC20).interfaceId);
        assertEq(interfaces[3], type(IERC20Permit).interfaceId);
        assertEq(interfaces[4], type(IERC5267).interfaceId);
    }

    /* -------------------------------------------------------------------------- */
    /*                            Facet Cuts Tests                                */
    /* -------------------------------------------------------------------------- */

    function test_facetCuts_returnsThreeCuts() public view {
        IDiamond.FacetCut[] memory cuts = pkg.facetCuts();

        assertEq(cuts.length, 3);
    }

    function test_facetCuts_firstCutIsERC20() public view {
        IDiamond.FacetCut[] memory cuts = pkg.facetCuts();

        assertEq(cuts[0].facetAddress, address(erc20Facet));
        assertEq(uint8(cuts[0].action), uint8(IDiamond.FacetCutAction.Add));
        assertGt(cuts[0].functionSelectors.length, 0);
    }

    function test_facetCuts_secondCutIsERC5267() public view {
        IDiamond.FacetCut[] memory cuts = pkg.facetCuts();

        assertEq(cuts[1].facetAddress, address(erc5267Facet));
        assertEq(uint8(cuts[1].action), uint8(IDiamond.FacetCutAction.Add));
    }

    function test_facetCuts_thirdCutIsERC2612() public view {
        IDiamond.FacetCut[] memory cuts = pkg.facetCuts();

        assertEq(cuts[2].facetAddress, address(erc2612Facet));
        assertEq(uint8(cuts[2].action), uint8(IDiamond.FacetCutAction.Add));
        assertGt(cuts[2].functionSelectors.length, 0);
    }

    function test_diamondConfig_returnsConfigWithCutsAndInterfaces() public view {
        ERC20PermitDFPkg.DiamondConfig memory config = pkg.diamondConfig();

        assertEq(config.facetCuts.length, 3);
        assertEq(config.interfaces.length, 5);
    }

    /* -------------------------------------------------------------------------- */
    /*                            Salt Calculation Tests                          */
    /* -------------------------------------------------------------------------- */

    function test_calcSalt_withNameAndSymbol_returnsDeterministicHash() public view {
        IERC20PermitDFPkg.PkgArgs memory args = IERC20PermitDFPkg.PkgArgs({
            name: "Test Token",
            symbol: "TEST",
            decimals: 18,
            totalSupply: 1000e18,
            recipient: recipient,
            optionalSalt: bytes32(0)
        });

        bytes memory encodedArgs = abi.encode(args);
        bytes32 salt1 = pkg.calcSalt(encodedArgs);
        bytes32 salt2 = pkg.calcSalt(encodedArgs);

        assertEq(salt1, salt2, "Same args should produce same salt");
    }

    function test_calcSalt_emptyName_usesSymbolAsName() public view {
        IERC20PermitDFPkg.PkgArgs memory args = IERC20PermitDFPkg.PkgArgs({
            name: "",
            symbol: "TEST",
            decimals: 18,
            totalSupply: 0,
            recipient: address(0),
            optionalSalt: bytes32(0)
        });

        // Should not revert - uses symbol as name
        bytes32 salt = pkg.calcSalt(abi.encode(args));
        assertTrue(salt != bytes32(0), "Salt should not be zero");
    }

    function test_calcSalt_emptySymbol_usesNameAsSymbol() public view {
        IERC20PermitDFPkg.PkgArgs memory args = IERC20PermitDFPkg.PkgArgs({
            name: "Test Token",
            symbol: "",
            decimals: 18,
            totalSupply: 0,
            recipient: address(0),
            optionalSalt: bytes32(0)
        });

        // Should not revert - uses name as symbol
        bytes32 salt = pkg.calcSalt(abi.encode(args));
        assertTrue(salt != bytes32(0), "Salt should not be zero");
    }

    function test_calcSalt_emptyNameAndSymbol_reverts() public {
        IERC20PermitDFPkg.PkgArgs memory args = IERC20PermitDFPkg.PkgArgs({
            name: "",
            symbol: "",
            decimals: 18,
            totalSupply: 0,
            recipient: address(0),
            optionalSalt: bytes32(0)
        });

        vm.expectRevert(IERC20PermitDFPkg.NoNameAndSymbol.selector);
        pkg.calcSalt(abi.encode(args));
    }

    function test_calcSalt_totalSupplyWithNoRecipient_reverts() public {
        IERC20PermitDFPkg.PkgArgs memory args = IERC20PermitDFPkg.PkgArgs({
            name: "Test Token",
            symbol: "TEST",
            decimals: 18,
            totalSupply: 1000e18,
            recipient: address(0),
            optionalSalt: bytes32(0)
        });

        vm.expectRevert(IERC20PermitDFPkg.NoRecipient.selector);
        pkg.calcSalt(abi.encode(args));
    }

    function test_calcSalt_zeroDecimals_defaultsToEighteen() public view {
        IERC20PermitDFPkg.PkgArgs memory args1 = IERC20PermitDFPkg.PkgArgs({
            name: "Test Token",
            symbol: "TEST",
            decimals: 0,
            totalSupply: 0,
            recipient: address(0),
            optionalSalt: bytes32(0)
        });

        IERC20PermitDFPkg.PkgArgs memory args2 = IERC20PermitDFPkg.PkgArgs({
            name: "Test Token",
            symbol: "TEST",
            decimals: 18,
            totalSupply: 0,
            recipient: address(0),
            optionalSalt: bytes32(0)
        });

        // Both should produce the same salt since 0 defaults to 18
        bytes32 salt1 = pkg.calcSalt(abi.encode(args1));
        bytes32 salt2 = pkg.calcSalt(abi.encode(args2));

        assertEq(salt1, salt2, "Zero decimals should default to 18");
    }

    function test_calcSalt_zeroTotalSupplyWithZeroRecipient_succeeds() public view {
        IERC20PermitDFPkg.PkgArgs memory args = IERC20PermitDFPkg.PkgArgs({
            name: "Test Token",
            symbol: "TEST",
            decimals: 18,
            totalSupply: 0,
            recipient: address(0),
            optionalSalt: bytes32(0)
        });

        // Should succeed - no recipient needed when totalSupply is 0
        bytes32 salt = pkg.calcSalt(abi.encode(args));
        assertTrue(salt != bytes32(0), "Salt should not be zero");
    }

    /* -------------------------------------------------------------------------- */
    /*                            Process Args Tests                              */
    /* -------------------------------------------------------------------------- */

    function test_processArgs_emptyName_usesSymbolAsName() public view {
        IERC20PermitDFPkg.PkgArgs memory args = IERC20PermitDFPkg.PkgArgs({
            name: "",
            symbol: "TEST",
            decimals: 18,
            totalSupply: 0,
            recipient: address(0),
            optionalSalt: bytes32(0)
        });

        bytes memory processed = pkg.processArgs(abi.encode(args));
        IERC20PermitDFPkg.PkgArgs memory decodedArgs = abi.decode(processed, (IERC20PermitDFPkg.PkgArgs));

        assertEq(decodedArgs.name, "TEST", "Name should be set from symbol");
        assertEq(decodedArgs.symbol, "TEST", "Symbol should remain unchanged");
    }

    function test_processArgs_emptySymbol_usesNameAsSymbol() public view {
        IERC20PermitDFPkg.PkgArgs memory args = IERC20PermitDFPkg.PkgArgs({
            name: "Test Token",
            symbol: "",
            decimals: 18,
            totalSupply: 0,
            recipient: address(0),
            optionalSalt: bytes32(0)
        });

        bytes memory processed = pkg.processArgs(abi.encode(args));
        IERC20PermitDFPkg.PkgArgs memory decodedArgs = abi.decode(processed, (IERC20PermitDFPkg.PkgArgs));

        assertEq(decodedArgs.name, "Test Token", "Name should remain unchanged");
        assertEq(decodedArgs.symbol, "Test Token", "Symbol should be set from name");
    }

    function test_processArgs_emptyNameAndSymbol_reverts() public {
        IERC20PermitDFPkg.PkgArgs memory args = IERC20PermitDFPkg.PkgArgs({
            name: "",
            symbol: "",
            decimals: 18,
            totalSupply: 0,
            recipient: address(0),
            optionalSalt: bytes32(0)
        });

        vm.expectRevert(IERC20PermitDFPkg.NoNameAndSymbol.selector);
        pkg.processArgs(abi.encode(args));
    }

    function test_processArgs_totalSupplyWithNoRecipient_reverts() public {
        IERC20PermitDFPkg.PkgArgs memory args = IERC20PermitDFPkg.PkgArgs({
            name: "Test Token",
            symbol: "TEST",
            decimals: 18,
            totalSupply: 1000e18,
            recipient: address(0),
            optionalSalt: bytes32(0)
        });

        vm.expectRevert(IERC20PermitDFPkg.NoRecipient.selector);
        pkg.processArgs(abi.encode(args));
    }

    function test_processArgs_zeroDecimals_defaultsToEighteen() public view {
        IERC20PermitDFPkg.PkgArgs memory args = IERC20PermitDFPkg.PkgArgs({
            name: "Test Token",
            symbol: "TEST",
            decimals: 0,
            totalSupply: 0,
            recipient: address(0),
            optionalSalt: bytes32(0)
        });

        bytes memory processed = pkg.processArgs(abi.encode(args));
        IERC20PermitDFPkg.PkgArgs memory decodedArgs = abi.decode(processed, (IERC20PermitDFPkg.PkgArgs));

        assertEq(decodedArgs.decimals, 18, "Decimals should default to 18");
    }

    /* -------------------------------------------------------------------------- */
    /*                            Update/PostDeploy Tests                         */
    /* -------------------------------------------------------------------------- */

    function test_updatePkg_returnsTrue() public {
        bool result = pkg.updatePkg(address(0x1), "");
        assertTrue(result);
    }

    function test_postDeploy_returnsTrue() public view {
        bool result = pkg.postDeploy(address(0x1));
        assertTrue(result);
    }

    /* -------------------------------------------------------------------------- */
    /*                             initAccount Tests                              */
    /* -------------------------------------------------------------------------- */

    function test_initAccount_initializesERC20Repo() public {
        IERC20PermitDFPkg.PkgArgs memory args = IERC20PermitDFPkg.PkgArgs({
            name: "Test Token",
            symbol: "TEST",
            decimals: 18,
            totalSupply: 0,
            recipient: address(0),
            optionalSalt: bytes32(0)
        });

        // Call initAccount via delegatecall to set storage in this test contract
        (bool success,) = address(pkg).delegatecall(
            abi.encodeWithSelector(pkg.initAccount.selector, abi.encode(args))
        );
        assertTrue(success, "initAccount should succeed");

        // Verify ERC20 was initialized
        assertEq(ERC20Repo._name(), "Test Token");
        assertEq(ERC20Repo._symbol(), "TEST");
        assertEq(ERC20Repo._decimals(), 18);
    }

    function test_initAccount_initializesEIP712Repo() public {
        IERC20PermitDFPkg.PkgArgs memory args = IERC20PermitDFPkg.PkgArgs({
            name: "Test Token",
            symbol: "TEST",
            decimals: 18,
            totalSupply: 0,
            recipient: address(0),
            optionalSalt: bytes32(0)
        });

        // Call initAccount via delegatecall
        (bool success,) = address(pkg).delegatecall(
            abi.encodeWithSelector(pkg.initAccount.selector, abi.encode(args))
        );
        assertTrue(success, "initAccount should succeed");

        // Verify EIP712 was initialized
        assertEq(EIP712Repo._EIP712Name(), "Test Token");
        assertEq(EIP712Repo._EIP712Version(), "1");
    }

    function test_initAccount_withTotalSupply_mintsTokens() public {
        IERC20PermitDFPkg.PkgArgs memory args = IERC20PermitDFPkg.PkgArgs({
            name: "Test Token",
            symbol: "TEST",
            decimals: 18,
            totalSupply: 1000e18,
            recipient: recipient,
            optionalSalt: bytes32(0)
        });

        // Call initAccount via delegatecall
        (bool success,) = address(pkg).delegatecall(
            abi.encodeWithSelector(pkg.initAccount.selector, abi.encode(args))
        );
        assertTrue(success, "initAccount should succeed");

        // Verify tokens were minted
        assertEq(ERC20Repo._balanceOf(recipient), 1000e18);
        assertEq(ERC20Repo._totalSupply(), 1000e18);
    }

    function test_initAccount_zeroTotalSupply_noMint() public {
        IERC20PermitDFPkg.PkgArgs memory args = IERC20PermitDFPkg.PkgArgs({
            name: "Test Token",
            symbol: "TEST",
            decimals: 18,
            totalSupply: 0,
            recipient: address(0),
            optionalSalt: bytes32(0)
        });

        // Call initAccount via delegatecall
        (bool success,) = address(pkg).delegatecall(
            abi.encodeWithSelector(pkg.initAccount.selector, abi.encode(args))
        );
        assertTrue(success, "initAccount should succeed");

        // Verify no tokens were minted
        assertEq(ERC20Repo._totalSupply(), 0);
    }

    /* -------------------------------------------------------------------------- */
    /*                                Fuzz Tests                                  */
    /* -------------------------------------------------------------------------- */

    function testFuzz_calcSalt_anyValidArgs_producesHash(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 totalSupply,
        address fuzzRecipient
    ) public view {
        // Skip invalid combinations
        vm.assume(bytes(name).length > 0 || bytes(symbol).length > 0);
        vm.assume(totalSupply == 0 || fuzzRecipient != address(0));

        IERC20PermitDFPkg.PkgArgs memory args = IERC20PermitDFPkg.PkgArgs({
            name: name,
            symbol: symbol,
            decimals: decimals,
            totalSupply: totalSupply,
            recipient: fuzzRecipient,
            optionalSalt: bytes32(0)
        });

        bytes32 salt = pkg.calcSalt(abi.encode(args));
        assertTrue(salt != bytes32(0), "Salt should not be zero");
    }

    function testFuzz_processArgs_anyValidArgs_returnsProcessed(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 totalSupply,
        address fuzzRecipient
    ) public view {
        // Skip invalid combinations
        vm.assume(bytes(name).length > 0 || bytes(symbol).length > 0);
        vm.assume(totalSupply == 0 || fuzzRecipient != address(0));

        IERC20PermitDFPkg.PkgArgs memory args = IERC20PermitDFPkg.PkgArgs({
            name: name,
            symbol: symbol,
            decimals: decimals,
            totalSupply: totalSupply,
            recipient: fuzzRecipient,
            optionalSalt: bytes32(0)
        });

        bytes memory processed = pkg.processArgs(abi.encode(args));
        assertTrue(processed.length > 0, "Processed args should not be empty");
    }
}
