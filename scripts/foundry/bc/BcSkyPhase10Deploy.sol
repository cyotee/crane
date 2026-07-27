// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {console2} from "forge-std/console2.sol";
import {Script} from "forge-std/Script.sol";

import {SkyDssFactoryService} from "@crane/contracts/protocols/cdps/sky/services/SkyDssFactoryService.sol";
import {GemJoin} from "@crane/contracts/protocols/cdps/sky/core/Join.sol";

/// @dev Minimal Maker-style pip (peek) for greenfield seed — not Chainlink aggregator ABI.
contract BcSkyDsValue {
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
}

/// @dev Mintable collateral gem for hermetic DSS smoke (not SUT).
contract BcSkyMockGem {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
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
        return true;
    }
}

/// @notice Phase 10 Sky/DSS full graph via SkyDssFactoryService (TestBase_SkyDss parity).
/// @dev **Multi-root Safe Harbor lineage (P10-2):** DSS uses plain `new` inside the service
///      (Maker-style graph). Not CREATE3-wrapped under Phase 1 Create3Factory. Product surface is
///      still Crane-owned bytecode; Safe Harbor agreement covers factory roots + documented
///      multi-root product deploys. Do not invent a divergent CREATE3 graph for Sky.
contract BcSkyPhase10Deploy is Script {
    uint256 internal constant WAD = 10 ** 18;

    struct DeployResult {
        address vat;
        address dai;
        address daiJoin;
        address jug;
        address pot;
        address spotter;
        address vow;
        address dog;
        address flapper;
        address flopper;
        address end;
        address chainlog;
        address gemJoin;
        address gem; // MockGem (hermetic) or external coll
        address pip; // DSValue price feed
        bytes32 ilk;
    }

    /// @notice Deploy full DSS + one ilk with supplied gem + pip (must implement peek()).
    function deployWithIlk(uint256 chainId, bytes32 ilk, address gem, address pip)
        external
        returns (DeployResult memory r)
    {
        require(gem != address(0) && pip != address(0), "p10: gem/pip zero");
        SkyDssFactoryService.DssDeployment memory d = SkyDssFactoryService.deployDss(chainId);
        SkyDssFactoryService.setDefaultParameters(d);
        GemJoin join = SkyDssFactoryService.initIlk(d, ilk, gem, pip);

        r = _fromDeployment(d, address(join), gem, pip, ilk);
        console2.log("p10 vat", r.vat);
        console2.log("p10 dai", r.dai);
        console2.log("p10 flapper", r.flapper);
        console2.log("p10 flopper", r.flopper);
        console2.log("p10 pot", r.pot);
        console2.log("p10 chainlog", r.chainlog);
        console2.log("p10 gemJoin", r.gemJoin);
        return r;
    }

    /// @notice Hermetic: MockGem + DSValue ($2000) + openCdp-ready WETH-A-style ilk.
    function deployHermetic(uint256 chainId) external returns (DeployResult memory r) {
        BcSkyMockGem gem = new BcSkyMockGem("Test Gem", "GEM", 18);
        BcSkyDsValue pip = new BcSkyDsValue();
        pip.poke(bytes32(uint256(2000 * WAD))); // $2000

        r = this.deployWithIlk(chainId, bytes32("WETH-A"), address(gem), address(pip));
        return r;
    }

    /// @notice BC-style: external gem (e.g. WETH) + DSValue pip at fixed USD (oracle adapter later).
    /// @dev Chainlink aggregators are not Maker `peek` pips; greenfield seed uses DSValue.
    function deployWithGemAndFixedPip(uint256 chainId, address gem, uint256 priceWad)
        external
        returns (DeployResult memory r)
    {
        require(gem != address(0) && gem.code.length > 0, "p10: gem no code");
        BcSkyDsValue pip = new BcSkyDsValue();
        pip.poke(bytes32(priceWad));
        return this.deployWithIlk(chainId, bytes32("WETH-A"), gem, address(pip));
    }

    function _fromDeployment(
        SkyDssFactoryService.DssDeployment memory d,
        address join,
        address gem,
        address pip,
        bytes32 ilk
    ) internal pure returns (DeployResult memory r) {
        r.vat = address(d.vat);
        r.dai = address(d.dai);
        r.daiJoin = address(d.daiJoin);
        r.jug = address(d.jug);
        r.pot = address(d.pot);
        r.spotter = address(d.spotter);
        r.vow = address(d.vow);
        r.dog = address(d.dog);
        r.flapper = address(d.flapper);
        r.flopper = address(d.flopper);
        r.end = address(d.end);
        r.chainlog = address(d.chainlog);
        r.gemJoin = join;
        r.gem = gem;
        r.pip = pip;
        r.ilk = ilk;
    }
}
