"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.buildTokenConfig = exports.setupEnvironment = void 0;
const contract_1 = require("@balancer-labs/v3-helpers/src/contract");
const time_1 = require("@balancer-labs/v3-helpers/src/time");
const constants_1 = require("@balancer-labs/v3-helpers/src/constants");
const sortingHelper_1 = require("@balancer-labs/v3-helpers/src/models/tokens/sortingHelper");
const VaultDeployer = __importStar(require("@balancer-labs/v3-helpers/src/models/vault/VaultDeployer"));
const TypesConverter_1 = __importDefault(require("@balancer-labs/v3-helpers/src/models/types/TypesConverter"));
const types_1 = require("@balancer-labs/v3-helpers/src/models/types/types");
// This deploys a Vault, then creates 3 tokens and 2 pools. The first pool (A) is registered; the second (B) )s not,
// which, along with a registration flag in the Pool mock, permits separate testing of registration functions.
async function setupEnvironment(pauseWindowDuration) {
    const BUFFER_PERIOD_DURATION = time_1.MONTH;
    const vault = await VaultDeployer.deployMock({
        pauseWindowDuration,
        bufferPeriodDuration: BUFFER_PERIOD_DURATION,
    });
    const vaultAddress = await vault.getAddress();
    const factoryAddress = await vault.getPoolFactoryMock();
    const factory = await (0, contract_1.deployedAt)('PoolFactoryMock', factoryAddress);
    const tokenA = await (0, contract_1.deploy)('v3-solidity-utils/ERC20TestToken', { args: ['Token A', 'TKNA', 18] });
    const tokenB = await (0, contract_1.deploy)('v3-solidity-utils/ERC20TestToken', { args: ['Token B', 'TKNB', 6] });
    const tokenC = await (0, contract_1.deploy)('v3-solidity-utils/ERC20TestToken', { args: ['Token C', 'TKNC', 8] });
    const tokenAAddress = await tokenA.getAddress();
    const tokenBAddress = await tokenB.getAddress();
    const tokenCAddress = await tokenC.getAddress();
    const poolATokens = (0, sortingHelper_1.sortAddresses)([tokenAAddress, tokenBAddress, tokenCAddress]);
    const poolA = await (0, contract_1.deploy)('v3-vault/PoolMock', {
        args: [vaultAddress, 'Pool A', 'POOL-A'],
    });
    await factory.registerTestPool(poolA, buildTokenConfig(poolATokens));
    // Don't register PoolB.
    const poolB = await (0, contract_1.deploy)('v3-vault/PoolMock', {
        args: [vaultAddress, 'Pool B', 'POOL-B'],
    });
    return { vault: await TypesConverter_1.default.toIVaultMock(vault), tokens: [tokenA, tokenB, tokenC], pools: [poolA, poolB] };
}
exports.setupEnvironment = setupEnvironment;
function buildTokenConfig(tokens, rateProviders = [], paysYieldFees = []) {
    const result = [];
    if (rateProviders.length == 0) {
        rateProviders = Array(tokens.length).fill(constants_1.ZERO_ADDRESS);
    }
    tokens.map((token, i) => {
        result[i] = {
            token: token,
            tokenType: rateProviders[i] == constants_1.ZERO_ADDRESS ? types_1.TokenType.STANDARD : types_1.TokenType.WITH_RATE,
            rateProvider: rateProviders[i],
            paysYieldFees: paysYieldFees.length == 0 ? rateProviders[i] != constants_1.ZERO_ADDRESS : paysYieldFees[i],
        };
    });
    return result;
}
exports.buildTokenConfig = buildTokenConfig;
