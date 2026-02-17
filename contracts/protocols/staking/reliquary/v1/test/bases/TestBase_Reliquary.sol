// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {CraneTest} from "@crane/contracts/test/CraneTest.sol";
import {MockERC20} from "@crane/contracts/test/mocks/MockERC20.sol";
import {ERC721Holder} from "@crane/contracts/external/openzeppelin/token/ERC721/utils/ERC721Holder.sol";

import {Reliquary} from "@crane/contracts/protocols/staking/reliquary/v1/Reliquary.sol";
import {IReliquary} from "@crane/contracts/protocols/staking/reliquary/v1/interfaces/IReliquary.sol";
import {LinearCurve} from "@crane/contracts/protocols/staking/reliquary/v1/curves/LinearCurve.sol";
import {LinearPlateauCurve} from "@crane/contracts/protocols/staking/reliquary/v1/curves/LinearPlateauCurve.sol";
import {PolynomialPlateauCurve} from "@crane/contracts/protocols/staking/reliquary/v1/curves/PolynomialPlateauCurve.sol";
import {ReliquaryEvents} from "@crane/contracts/protocols/staking/reliquary/v1/services/ReliquaryEvents.sol";

abstract contract TestBase_Reliquary is CraneTest, ERC721Holder {
    IReliquary internal reliquary;

    LinearCurve internal linearCurve;
    LinearPlateauCurve internal linearPlateauCurve;
    PolynomialPlateauCurve internal polynomialCurve;

    MockERC20 internal rewardToken;
    MockERC20 internal poolToken;

    uint256 internal constant DEFAULT_EMISSION = 1e18;

    function setUp() public virtual override {
        CraneTest.setUp();

        // Deploy mock tokens
        rewardToken = new MockERC20("Reward", "RWD", 18);
        poolToken = new MockERC20("Pool", "POOL", 18);

        // Deploy Reliquary
        Reliquary reliquary_ = new Reliquary(address(rewardToken), DEFAULT_EMISSION, "Reliquary Deposit", "RELIC");
        reliquary = IReliquary(address(reliquary_));

        // Deploy curves
        linearCurve = new LinearCurve(1, 1);
        linearPlateauCurve = new LinearPlateauCurve(1, 1, 10);

        int256[] memory coeffs = new int256[](1);
        coeffs[0] = int256(1e18);
        polynomialCurve = new PolynomialPlateauCurve(coeffs, 100);

        // Mint some reward tokens to the Reliquary
        rewardToken.mint(address(reliquary_), 1_000_000e18);

        // Mint pool tokens to this test contract and approve Reliquary
        poolToken.mint(address(this), 1_000_000e18);
        poolToken.approve(address(reliquary_), type(uint256).max);

        // Grant operator role to this contract so we can add pools
        // Reliquary sets DEFAULT_ADMIN_ROLE to deployer (this contract not admin), so skip role granularity

        // Add default pool using linear curve
        // Reliquary.addPool requires DEFAULT_ADMIN_ROLE - in tests we can call via deployer
        // For simplicity, we impersonate the deployer by using address(this) if it is admin; otherwise do minimal bootstrapping
        // Since deployer is msg.sender in constructor (set to this deployer), the deployer is address(this) and thus has admin
        reliquary_.addPool(100, address(poolToken), address(0), linearCurve, "Pool A", address(0), true, address(this));
    }

    // Helper: create a pool with given allocPoint and curve
    function _createPool(uint256 allocPoint, address _poolToken, address _curve) internal returns (uint8) {
        Reliquary r = Reliquary(address(reliquary));
        r.addPool(allocPoint, _poolToken, address(0), LinearCurve(_curve), "", address(0), true, address(this));
        return uint8(r.poolLength() - 1);
    }

    // Helper: deposit pool tokens into a relic (create relic and deposit)
    function _createAndDeposit(uint8 poolId, uint256 amount) internal returns (uint256) {
        Reliquary r = Reliquary(address(reliquary));
        // create relic and deposit to this contract
        uint256 relicId = r.createRelicAndDeposit(address(this), poolId, amount);
        return relicId;
    }
}
