// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {Create3Factory} from "@crane/contracts/factories/create3/Create3Factory.sol";
import {ERC165Facet} from "@crane/contracts/introspection/ERC165/ERC165Facet.sol";
import {IERC165} from "@crane/contracts/interfaces/IERC165.sol";

/**
 * @title MockFacet
 * @notice Simple mock facet for testing registration and deployment.
 */
contract MockFacet is IFacet {
    string internal _name;
    bytes4[] internal _interfaces;
    bytes4[] internal _funcs;

    constructor(string memory name_, bytes4[] memory interfaces_, bytes4[] memory funcs_) {
        _name = name_;
        _interfaces = interfaces_;
        _funcs = funcs_;
    }

    function facetName() external view override returns (string memory) {
        return _name;
    }

    function facetInterfaces() external view override returns (bytes4[] memory) {
        return _interfaces;
    }

    function facetFuncs() external view override returns (bytes4[] memory) {
        return _funcs;
    }

    function facetMetadata()
        external
        view
        override
        returns (string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        return (_name, _interfaces, _funcs);
    }
}

/**
 * @title MockPackage
 * @notice Simple mock package for testing registration.
 */
contract MockPackage is IDiamondFactoryPackage {
    string internal _name;
    bytes4[] internal _interfaces;
    address[] internal _facets;

    constructor(string memory name_, bytes4[] memory interfaces_, address[] memory facets_) {
        _name = name_;
        _interfaces = interfaces_;
        _facets = facets_;
    }

    function packageName() external view override returns (string memory) {
        return _name;
    }

    function packageMetadata()
        external
        view
        override
        returns (string memory name, bytes4[] memory interfaces, address[] memory facets)
    {
        return (_name, _interfaces, _facets);
    }

    function facetAddresses() external view override returns (address[] memory) {
        return _facets;
    }

    function facetInterfaces() external view override returns (bytes4[] memory) {
        return _interfaces;
    }

    function facetCuts() external pure override returns (IDiamond.FacetCut[] memory cuts) {
        cuts = new IDiamond.FacetCut[](0);
    }

    function diamondConfig() external view override returns (IDiamondFactoryPackage.DiamondConfig memory) {
        IDiamond.FacetCut[] memory cuts = new IDiamond.FacetCut[](0);
        return IDiamondFactoryPackage.DiamondConfig({
            facetCuts: cuts,
            interfaces: _interfaces
        });
    }

    function calcSalt(bytes memory) external pure override returns (bytes32) {
        return bytes32(0);
    }

    function processArgs(bytes memory pkgArgs) external pure override returns (bytes memory) {
        return pkgArgs;
    }

    function updatePkg(address, bytes memory) external pure override returns (bool) {
        return true;
    }

    function initAccount(bytes memory) external override {}

    function postDeploy(address) external pure override returns (bool) {
        return true;
    }
}

/**
 * @title Create3Factory_Test
 * @notice Tests for Create3Factory.
 */
contract Create3Factory_Test is Test {
    Create3Factory internal factory;

    address internal owner;
    address internal operator;
    address internal nonAuthorized;

    function setUp() public {
        owner = makeAddr("owner");
        operator = makeAddr("operator");
        nonAuthorized = makeAddr("nonAuthorized");

        vm.prank(owner);
        factory = new Create3Factory(owner);

        // Grant operator role
        vm.prank(owner);
        factory.setOperator(operator, true);
    }

    /* ---------------------------------------------------------------------- */
    /*                          Constructor Tests                              */
    /* ---------------------------------------------------------------------- */

    function test_constructor_setsOwner() public view {
        assertEq(factory.owner(), owner, "Owner should be set");
    }

    function test_constructor_ownerCanCall() public view {
        // Owner should have been set successfully - verify via owner query
        assertEq(factory.owner(), owner);
    }

    /* ---------------------------------------------------------------------- */
    /*                    setDiamondPackageFactory Tests                       */
    /* ---------------------------------------------------------------------- */

    function test_setDiamondPackageFactory_asOwner_succeeds() public {
        IDiamondPackageCallBackFactory mockDpf = IDiamondPackageCallBackFactory(makeAddr("dpf"));

        vm.prank(owner);
        bool result = factory.setDiamondPackageFactory(mockDpf);

        assertTrue(result, "Should return true");
        assertEq(address(factory.diamondPackageFactory()), address(mockDpf), "Factory should be set");
    }

    function test_setDiamondPackageFactory_asNonOwner_reverts() public {
        IDiamondPackageCallBackFactory mockDpf = IDiamondPackageCallBackFactory(makeAddr("dpf"));

        vm.prank(nonAuthorized);
        vm.expectRevert();
        factory.setDiamondPackageFactory(mockDpf);
    }

    function test_setDiamondPackageFactory_asOperator_reverts() public {
        IDiamondPackageCallBackFactory mockDpf = IDiamondPackageCallBackFactory(makeAddr("dpf"));

        vm.prank(operator);
        vm.expectRevert();
        factory.setDiamondPackageFactory(mockDpf);
    }

    /* ---------------------------------------------------------------------- */
    /*                          create3 Tests                                  */
    /* ---------------------------------------------------------------------- */

    function test_create3_asOwner_deploysContract() public {
        bytes memory initCode = type(MockFacet).creationCode;
        bytes4[] memory interfaces = new bytes4[](1);
        interfaces[0] = type(IERC165).interfaceId;
        bytes4[] memory funcs = new bytes4[](0);
        bytes memory constructorArgs = abi.encode("TestFacet", interfaces, funcs);
        bytes memory fullInitCode = abi.encodePacked(initCode, constructorArgs);
        bytes32 salt = keccak256("test.salt");

        vm.prank(owner);
        address deployed = factory.create3(fullInitCode, salt);

        assertTrue(deployed != address(0), "Should deploy contract");
        assertTrue(deployed.code.length > 0, "Contract should have code");
    }

    function test_create3_asOperator_deploysContract() public {
        bytes memory initCode = type(MockFacet).creationCode;
        bytes4[] memory interfaces = new bytes4[](0);
        bytes4[] memory funcs = new bytes4[](0);
        bytes memory constructorArgs = abi.encode("TestFacet2", interfaces, funcs);
        bytes memory fullInitCode = abi.encodePacked(initCode, constructorArgs);
        bytes32 salt = keccak256("operator.test.salt");

        vm.prank(operator);
        address deployed = factory.create3(fullInitCode, salt);

        assertTrue(deployed != address(0), "Should deploy contract");
    }

    function test_create3_asNonAuthorized_reverts() public {
        bytes memory initCode = type(MockFacet).creationCode;
        bytes4[] memory interfaces = new bytes4[](0);
        bytes4[] memory funcs = new bytes4[](0);
        bytes memory constructorArgs = abi.encode("TestFacet", interfaces, funcs);
        bytes memory fullInitCode = abi.encodePacked(initCode, constructorArgs);
        bytes32 salt = keccak256("unauth.salt");

        vm.prank(nonAuthorized);
        vm.expectRevert();
        factory.create3(fullInitCode, salt);
    }

    function test_create3_existingContract_returnsExisting() public {
        bytes memory initCode = type(MockFacet).creationCode;
        bytes4[] memory interfaces = new bytes4[](0);
        bytes4[] memory funcs = new bytes4[](0);
        bytes memory constructorArgs = abi.encode("DuplicateFacet", interfaces, funcs);
        bytes memory fullInitCode = abi.encodePacked(initCode, constructorArgs);
        bytes32 salt = keccak256("duplicate.salt");

        vm.prank(owner);
        address first = factory.create3(fullInitCode, salt);

        vm.prank(owner);
        address second = factory.create3(fullInitCode, salt);

        assertEq(first, second, "Should return existing address");
    }

    /* ---------------------------------------------------------------------- */
    /*                       deployFacet Tests                                 */
    /* ---------------------------------------------------------------------- */

    function test_deployFacet_deploysAndRegisters() public {
        bytes memory initCode = abi.encodePacked(
            type(MockFacet).creationCode,
            abi.encode("RegisteredFacet", new bytes4[](0), new bytes4[](0))
        );
        bytes32 salt = keccak256("registered.facet.salt");

        vm.prank(owner);
        IFacet facet = factory.deployFacet(initCode, salt);

        assertTrue(address(facet) != address(0), "Should deploy facet");

        // Check registration
        address[] memory allFacets = factory.allFacets();
        assertEq(allFacets.length, 1, "Should have 1 registered facet");
        assertEq(allFacets[0], address(facet), "Facet should be registered");
    }

    function test_deployFacet_storesFacetName() public {
        bytes4[] memory interfaces = new bytes4[](0);
        bytes4[] memory funcs = new bytes4[](0);
        bytes memory initCode = abi.encodePacked(
            type(MockFacet).creationCode,
            abi.encode("NamedFacet", interfaces, funcs)
        );
        bytes32 salt = keccak256("named.facet.salt");

        vm.prank(owner);
        IFacet facet = factory.deployFacet(initCode, salt);

        string memory storedName = factory.nameOfFacet(facet);
        assertEq(storedName, "NamedFacet", "Name should be stored");
    }

    function test_deployFacetWithArgs_deploysAndRegisters() public {
        bytes memory initCode = type(MockFacet).creationCode;
        bytes4[] memory interfaces = new bytes4[](1);
        interfaces[0] = type(IERC165).interfaceId;
        bytes4[] memory funcs = new bytes4[](0);
        bytes memory initArgs = abi.encode("FacetWithArgs", interfaces, funcs);
        bytes32 salt = keccak256("facet.with.args.salt");

        vm.prank(owner);
        IFacet facet = factory.deployFacetWithArgs(initCode, initArgs, salt);

        assertTrue(address(facet) != address(0), "Should deploy facet");

        // Check that the facet is registered by verifying it's in allFacets
        address[] memory allFacets = factory.allFacets();
        assertEq(allFacets.length, 1, "Should have 1 registered facet");

        // Check that the facet can be found by interface
        address[] memory facetsByInterface = factory.facetsOfInterface(type(IERC165).interfaceId);
        assertEq(facetsByInterface.length, 1, "Should have 1 facet for interface");
        assertEq(facetsByInterface[0], address(facet), "Facet should be indexed by interface");
    }

    /* ---------------------------------------------------------------------- */
    /*                       deployPackage Tests                               */
    /* ---------------------------------------------------------------------- */

    function test_deployPackage_deploysAndRegisters() public {
        bytes4[] memory interfaces = new bytes4[](0);
        address[] memory facets = new address[](0);
        bytes memory initCode = abi.encodePacked(
            type(MockPackage).creationCode,
            abi.encode("TestPackage", interfaces, facets)
        );
        bytes32 salt = keccak256("package.salt");

        vm.prank(owner);
        IDiamondFactoryPackage pkg = factory.deployPackage(initCode, salt);

        assertTrue(address(pkg) != address(0), "Should deploy package");

        address[] memory allPackages = factory.allPackages();
        assertEq(allPackages.length, 1, "Should have 1 registered package");
        assertEq(allPackages[0], address(pkg), "Package should be registered");
    }

    function test_deployPackageWithArgs_deploysAndRegisters() public {
        bytes memory initCode = type(MockPackage).creationCode;
        bytes4[] memory interfaces = new bytes4[](1);
        interfaces[0] = bytes4(0x12345678);
        address[] memory facets = new address[](0);
        bytes memory constructorArgs = abi.encode("PackageWithArgs", interfaces, facets);
        bytes32 salt = keccak256("package.with.args.salt");

        vm.prank(owner);
        IDiamondFactoryPackage pkg = factory.deployPackageWithArgs(initCode, constructorArgs, salt);

        assertTrue(address(pkg) != address(0), "Should deploy package");

        string memory storedName = factory.nameOfPackage(pkg);
        assertEq(storedName, "PackageWithArgs", "Name should be stored");
    }

    /* ---------------------------------------------------------------------- */
    /*                       registerFacet Tests                               */
    /* ---------------------------------------------------------------------- */

    function test_registerFacet_manualRegistration() public {
        bytes4[] memory interfaces = new bytes4[](2);
        interfaces[0] = bytes4(0xaabbccdd);
        interfaces[1] = bytes4(0x11223344);
        bytes4[] memory funcs = new bytes4[](1);
        funcs[0] = bytes4(0xdeadbeef);

        MockFacet facet = new MockFacet("ManualFacet", interfaces, funcs);

        vm.prank(owner);
        bool result = factory.registerFacet(IFacet(address(facet)), "ManualFacet", interfaces, funcs);

        assertTrue(result, "Should return true");
        assertEq(factory.nameOfFacet(IFacet(address(facet))), "ManualFacet");
    }

    function test_registerFacet_indexesByInterface() public {
        bytes4[] memory interfaces = new bytes4[](1);
        interfaces[0] = type(IERC165).interfaceId;
        bytes4[] memory funcs = new bytes4[](0);

        MockFacet facet = new MockFacet("InterfaceFacet", interfaces, funcs);

        vm.prank(owner);
        factory.registerFacet(IFacet(address(facet)), "InterfaceFacet", interfaces, funcs);

        address[] memory facetsByInterface = factory.facetsOfInterface(type(IERC165).interfaceId);
        assertEq(facetsByInterface.length, 1, "Should have 1 facet for interface");
        assertEq(facetsByInterface[0], address(facet), "Facet should be indexed by interface");
    }

    function test_registerFacet_indexesByFunction() public {
        bytes4[] memory interfaces = new bytes4[](0);
        bytes4[] memory funcs = new bytes4[](1);
        funcs[0] = bytes4(keccak256("testFunction()"));

        MockFacet facet = new MockFacet("FunctionFacet", interfaces, funcs);

        vm.prank(owner);
        factory.registerFacet(IFacet(address(facet)), "FunctionFacet", interfaces, funcs);

        address[] memory facetsByFunc = factory.facetsOfFunction(funcs[0]);
        assertEq(facetsByFunc.length, 1, "Should have 1 facet for function");
        assertEq(facetsByFunc[0], address(facet), "Facet should be indexed by function");
    }

    /* ---------------------------------------------------------------------- */
    /*                       registerPackage Tests                             */
    /* ---------------------------------------------------------------------- */

    function test_registerPackage_manualRegistration() public {
        bytes4[] memory interfaces = new bytes4[](1);
        interfaces[0] = bytes4(0xaabbccdd);
        address[] memory facets = new address[](0);

        MockPackage pkg = new MockPackage("ManualPackage", interfaces, facets);

        vm.prank(owner);
        bool result = factory.registerPackage(IDiamondFactoryPackage(address(pkg)), "ManualPackage", interfaces, facets);

        assertTrue(result, "Should return true");
        assertEq(factory.nameOfPackage(IDiamondFactoryPackage(address(pkg))), "ManualPackage");
    }

    function test_registerPackage_indexesByFacet() public {
        bytes4[] memory interfaces = new bytes4[](0);
        bytes4[] memory funcs = new bytes4[](0);
        MockFacet facet = new MockFacet("LinkedFacet", interfaces, funcs);

        address[] memory facets = new address[](1);
        facets[0] = address(facet);
        MockPackage pkg = new MockPackage("LinkedPackage", interfaces, facets);

        vm.prank(owner);
        factory.registerPackage(IDiamondFactoryPackage(address(pkg)), "LinkedPackage", interfaces, facets);

        address[] memory packagesByFacet = factory.packagesByFacet(IFacet(address(facet)));
        assertEq(packagesByFacet.length, 1, "Should have 1 package for facet");
        assertEq(packagesByFacet[0], address(pkg), "Package should be indexed by facet");
    }

    /* ---------------------------------------------------------------------- */
    /*                          Query Tests                                    */
    /* ---------------------------------------------------------------------- */

    function test_allFacets_returnsEmpty_initially() public view {
        address[] memory allFacets = factory.allFacets();
        assertEq(allFacets.length, 0, "Should be empty initially");
    }

    function test_allPackages_returnsEmpty_initially() public view {
        address[] memory allPackages = factory.allPackages();
        assertEq(allPackages.length, 0, "Should be empty initially");
    }

    function test_facetsOfName_returnsMatchingFacets() public {
        bytes4[] memory interfaces = new bytes4[](0);
        bytes4[] memory funcs = new bytes4[](0);

        MockFacet facet1 = new MockFacet("SameName", interfaces, funcs);
        MockFacet facet2 = new MockFacet("SameName", interfaces, funcs);

        vm.startPrank(owner);
        factory.registerFacet(IFacet(address(facet1)), "SameName", interfaces, funcs);
        factory.registerFacet(IFacet(address(facet2)), "SameName", interfaces, funcs);
        vm.stopPrank();

        address[] memory facetsByName = factory.facetsOfName("SameName");
        assertEq(facetsByName.length, 2, "Should have 2 facets with same name");
    }

    function test_packagesByName_returnsMatchingPackages() public {
        bytes4[] memory interfaces = new bytes4[](0);
        address[] memory facets = new address[](0);

        MockPackage pkg1 = new MockPackage("SamePkgName", interfaces, facets);
        MockPackage pkg2 = new MockPackage("SamePkgName", interfaces, facets);

        vm.startPrank(owner);
        factory.registerPackage(IDiamondFactoryPackage(address(pkg1)), "SamePkgName", interfaces, facets);
        factory.registerPackage(IDiamondFactoryPackage(address(pkg2)), "SamePkgName", interfaces, facets);
        vm.stopPrank();

        address[] memory pkgsByName = factory.packagesByName("SamePkgName");
        assertEq(pkgsByName.length, 2, "Should have 2 packages with same name");
    }

    function test_packagesByInterface_returnsMatchingPackages() public {
        bytes4[] memory interfaces = new bytes4[](1);
        interfaces[0] = bytes4(0x55556666);
        address[] memory facets = new address[](0);

        MockPackage pkg = new MockPackage("InterfacePkg", interfaces, facets);

        vm.prank(owner);
        factory.registerPackage(IDiamondFactoryPackage(address(pkg)), "InterfacePkg", interfaces, facets);

        address[] memory pkgsByInterface = factory.packagesByInterface(bytes4(0x55556666));
        assertEq(pkgsByInterface.length, 1, "Should have 1 package for interface");
    }

    /* ---------------------------------------------------------------------- */
    /*                       Access Control Tests                              */
    /* ---------------------------------------------------------------------- */

    function test_deployFacet_asNonAuthorized_reverts() public {
        bytes memory initCode = abi.encodePacked(
            type(MockFacet).creationCode,
            abi.encode("Unauthorized", new bytes4[](0), new bytes4[](0))
        );
        bytes32 salt = keccak256("unauth.facet.salt");

        vm.prank(nonAuthorized);
        vm.expectRevert();
        factory.deployFacet(initCode, salt);
    }

    function test_deployPackage_asNonAuthorized_reverts() public {
        bytes memory initCode = abi.encodePacked(
            type(MockPackage).creationCode,
            abi.encode("Unauthorized", new bytes4[](0), new address[](0))
        );
        bytes32 salt = keccak256("unauth.pkg.salt");

        vm.prank(nonAuthorized);
        vm.expectRevert();
        factory.deployPackage(initCode, salt);
    }

    function test_registerFacet_asNonAuthorized_reverts() public {
        bytes4[] memory interfaces = new bytes4[](0);
        bytes4[] memory funcs = new bytes4[](0);
        MockFacet facet = new MockFacet("Unauth", interfaces, funcs);

        vm.prank(nonAuthorized);
        vm.expectRevert();
        factory.registerFacet(IFacet(address(facet)), "Unauth", interfaces, funcs);
    }

    function test_registerPackage_asNonAuthorized_reverts() public {
        bytes4[] memory interfaces = new bytes4[](0);
        address[] memory facets = new address[](0);
        MockPackage pkg = new MockPackage("Unauth", interfaces, facets);

        vm.prank(nonAuthorized);
        vm.expectRevert();
        factory.registerPackage(IDiamondFactoryPackage(address(pkg)), "Unauth", interfaces, facets);
    }

    /* ---------------------------------------------------------------------- */
    /*                            Fuzz Tests                                   */
    /* ---------------------------------------------------------------------- */

    function testFuzz_create3_differentSalts_differentAddresses(bytes32 salt1, bytes32 salt2) public {
        vm.assume(salt1 != salt2);

        bytes4[] memory interfaces = new bytes4[](0);
        bytes4[] memory funcs = new bytes4[](0);

        bytes memory initCode1 = abi.encodePacked(
            type(MockFacet).creationCode,
            abi.encode("Fuzz1", interfaces, funcs)
        );
        bytes memory initCode2 = abi.encodePacked(
            type(MockFacet).creationCode,
            abi.encode("Fuzz2", interfaces, funcs)
        );

        vm.startPrank(owner);
        address addr1 = factory.create3(initCode1, salt1);
        address addr2 = factory.create3(initCode2, salt2);
        vm.stopPrank();

        assertTrue(addr1 != addr2, "Different salts should produce different addresses");
    }

    function testFuzz_registerFacet_anyName(string calldata name) public {
        vm.assume(bytes(name).length > 0);
        vm.assume(bytes(name).length < 256);

        bytes4[] memory interfaces = new bytes4[](0);
        bytes4[] memory funcs = new bytes4[](0);
        MockFacet facet = new MockFacet(name, interfaces, funcs);

        vm.prank(owner);
        factory.registerFacet(IFacet(address(facet)), name, interfaces, funcs);

        assertEq(factory.nameOfFacet(IFacet(address(facet))), name);
    }
}
