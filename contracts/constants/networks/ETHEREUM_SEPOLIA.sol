// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

library ETHEREUM_SEPOLIA {
    uint256 constant CHAIN_ID = 11155111;

    /* ---------------------------------------------------------------------- */
    /*                                  WETH9                                 */
    /* ---------------------------------------------------------------------- */

    address constant WETH9 = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;

    address constant UNISWAP_V2_WETH9 = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;

    address constant BALANCER_V3_WETH9 = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9;

    /* ---------------------------------------------------------------------- */
    /*                               Uniswap V2                               */
    /* ---------------------------------------------------------------------- */

    // TODO Get FeeTo from UniswapV2Factory

    address constant UNISWAP_V2_FACTORY = 0xF62c03E08ada871A0bEb309762E260a7a6a880E6;
    address constant UNISWAP_V2_ROUTER = 0xeE567Fe1712Faf6149d80dA1E6934E354124CfE3;

    /* ---------------------------------------------------------------------- */
    /*                                Mooniswap                               */
    /* ---------------------------------------------------------------------- */

    address constant MOONISWAP_FACTORY = 0x71CD6666064C3A1354a3B4dca5fA1E2D3ee7D303;

    /* ---------------------------------------------------------------------- */
    /*                               Uniswap V3                               */
    /* ---------------------------------------------------------------------- */

    /* ---------------------------------------------------------------------- */
    /*                                Multicall                               */
    /* ---------------------------------------------------------------------- */

    /* ---------------------------------------------------------------------- */
    /*                                 Permit2                                */
    /* ---------------------------------------------------------------------- */

    address constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    /* ---------------------------------------------------------------------- */
    /*                               Balancer V2                              */
    /* ---------------------------------------------------------------------- */

    address constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address constant BALANCER_COMPOSABLE_POOL_FACTORY = 0xa523f47A933D5020b23629dDf689695AA94612Dc;
    address constant BALANCER_WEIGHTED_POOL_FACTORY = 0x7920BFa1b2041911b354747CA7A6cDD2dfC50Cfd;
    address constant BALANCER_QUERIES = 0x1802953277FD955f9a254B80Aa0582f193cF1d77;
    address constant BALANCER_RELAYER = 0xBeA696c7761734d9e66f4F372EB35059C1aeD1e0;
    address constant BALANCER_PROTOCOL_FEES_PERCENTAGES = 0x97207B095e4D5C9a6e4cfbfcd2C3358E03B90c4A;

    /* ---------------------------------------------------------------------- */
    /*                               Balancer V3                              */
    /* ---------------------------------------------------------------------- */

    /* -------------------------------- Core -------------------------------- */

    address constant BALANCER_V3_PROTOCOL_FEE_CONTROLLER_1 = 0xa731C23D7c95436Baaae9D52782f966E1ed07cc8;
    address constant BALANCER_V3_PROTOCOL_FEE_CONTROLLER_2 = 0x931d2a630f6bdfe872F98ea967447c8F99d4823a;
    address constant BALANCER_V3_PROTOCOL_FEE_SWEEPER = 0x0f3615e60b1D23a5DD98CE74865FAA79A6d9aF70;
    address constant BALANCER_V3_VAULT = 0xbA1333333333a1BA1108E8412f11850A5C319bA9;
    address constant BALANCER_V3_VAULT_ADMIN = 0x35fFB749B273bEb20F40f35EdeB805012C539864;
    address constant BALANCER_V3_VAULT_EXPLORER = 0xC82E329C832CAcc8DA65dbB57ac72B068e0CEb9B;
    address constant BALANCER_V3_VAULT_EXTENSION = 0x0E8B07657D719B86e06bF0806D6729e3D528C9A9;
    address constant BALANCER_V3_VAULT_FACTORY = 0xAc27df81663d139072E615855eF9aB0Af3FBD281;

    /* ------------------------------- Routers ------------------------------ */

    address constant BALANCER_V3_AGGREGATOR_BATCH_ROUTER = 0x17a00FcDEafeE2E97b52083330B3B339Fb633dC1;
    address constant BALANCER_V3_AGGREGATOR_ROUTER = 0x17a00FcDEafeE2E97b52083330B3B339Fb633dC1;
    address constant BALANCER_V3_BATCH_ROUTER = 0xC85b652685567C1B074e8c0D4389f83a2E458b1C;
    address constant BALANCER_V3_BUFFER_ROUTER = 0xb5F3A41515457CC6E2716c62a011D260441CcfC9;
    address constant BALANCER_V3_COMPOSITE_LIQUIDITY_ROUTER = 0x6A20a4b6DcFF78e6D21BF0dbFfD58C96644DB9cb;
    address constant BALANCER_V3_LBP_MIGRATION_ROUTER = 0x0AE19A3f8c35e0156E0d39307ad4cce1acD42929;
    address constant BALANCER_V3_ROUTER = 0x5e315f96389C1aaF9324D97d3512ae1e0Bf3C21a;

    /* --------------------------- Pool Factories --------------------------- */

    address constant BALANCER_V3_GYRO_2CLP_POOL_FACTORY = 0x38ce8e04EBC04A39BED4b097e8C9bb8Ca74e33d8;
    address constant BALANCER_V3_GYRO_ECLP_POOL_FACTORY = 0x589cA6855C348d831b394676c25B125BcdC7F8ce;
    address constant BALANCER_V3_LB_POOL_FACTORY = 0xE92cF5185384f53B2af74A2eBA62ba3A9C0ED65B;
    address constant BALANCER_V3_MOCK_GYRO_2CLP_POOL = 0x4d1a7352311CA9f63AB8bEA96CA873796C72EBDf;
    address constant BLANACER_V3_MOCK_GYRO_ECLP_POOL = 0xD2fB2b142c27094833f48c8a4a950ecc2e139F66;
    address constant BALANCER_V3_MOCK_LB_POOL = 0xc432fC493269Cf9412ef419a8E571655657158a3;
    address constant BALANCER_V3_MOCK_RECLAMM_POOL = address(0x78bE2bd092045315D30D2b91d98CAbb15333e021);
    address constant BALANCER_V3_MOCK_STABLE_POOL_V2 = 0x1C72b94E0e291dEe39a239E6e9C47625b14dEA71;
    address constant BALANCER_V3_MOCK_STABLE_SURGE_POOL = 0x781589d386e62ba7eB5D8382eE4DC86d8C64f882;
    address constant BALANCER_V3_MOCK_WEIGHTED_POOL = 0xFc253B433B7225AC7736EAbDF4115F7252aECb91;
    address constant BALANCER_V3_MOCK_WRAPPED_BALANCER_POOL_TOKEN = 0xeC2C01AE8BE49D9335157e2e0680c686e2629Bfb;
    address constant BALANCER_V3_RECLAMM_POOL_FACTORY = address(0xf58A574530Ea5cEB727095e6039170c1e8068fcA);
    address constant BALANCER_V3_STABLE_POOL_FACTORY = 0xc274A11E09a3c92Ac64eAff5bEC4ee8f5dfEe207;
    address constant BALANCER_V3_STABLE_SURGE_POOL_FACTORY = 0x2f1d6F4C40047dC122cA7e46B0D1eC27739BFc66;
    address constant BALANCER_V3_WEIGHTED_POOL_FACTORY = 0x7532d5a3bE916e4a4D900240F49F0BABd4FD855C;
    address constant BALANCER_V3_WRAPPED_BALANCER_POOL_TOKEN_FACTORY = 0xE47e1b8640e18F77BEC160D2Bb2481F65e580730;

    /* ------------------------ Hooks and Peripherals ----------------------- */

    /* ------------------------ Authorization Contracts --------------------- */

    address constant BALANCER_V3_AUTHORIZER = 0xA331D84eC860Bf466b4CdCcFb4aC09a1B43F3aE6;
    address constant BALANCER_V3_AUTHORIZER_ADAPTOR = 0xdcdbf71A870cc60C6F9B621E28a7D3Ffd6Dd4965;
    address constant BALANCER_V3_AUTHORIZER_ADAPTOR_ENTRYPOINT = 0xb9aD3466cdd42015cc05d4804DC68D562b6a2065;
    address constant BALANCER_V3_AUTHORIZER_WITH_ADAPTOR_VALIDATION = 0xb521dD5C8e13fE202626CaC98873FEA2b7760cE4;
    address constant BALANCER_V3_TIMELOCK_AUTHORIZER = address(0xDe615cc5712B4954BeB613BCF32E61C137Cc64f9);
    address constant BALANCER_V3_TIMELOCK_AUTHORIZER_MIGRATOR = address(0x6eaD84Af26E997D27998Fc9f8614e8a19BB93938);

    /* ------------------------ Gauges and Governance ----------------------- */
}
