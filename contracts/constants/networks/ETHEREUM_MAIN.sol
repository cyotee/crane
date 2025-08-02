// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

library ETHEREUM_MAIN {

    uint256 constant CHAIN_ID = 1;

    /* ---------------------------------------------------------------------- */
    /*                                  WETH9                                 */
    /* ---------------------------------------------------------------------- */

    address payable constant WETH9 =
        payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    /* ---------------------------------------------------------------------- */
    /*                               Uniswap V2                               */
    /* ---------------------------------------------------------------------- */

    address constant UNISWAP_V2_FACTORY
        = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address constant UNISWAP_V2_FEE_TO_SETTER
        = 0x18e433c7Bf8A2E1d0197CE5d8f9AFAda1A771360;
    address constant UNISWAP_V2_ROUTER
        = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    /* ---------------------------------------------------------------------- */
    /*                               Uniswap V3                               */
    /* ---------------------------------------------------------------------- */

    address constant UNISWAP_V3_FACTORY
        = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address constant UNISWAP_V3_PROXY_ADMIN 
        = 0xB753548F6E010e7e680BA186F9Ca1BdAB2E90cf2;
    address constant UNISWAP_V3_TICK_LENS
        = 0xbfd8137f7d1516D3ea5cA83523914859ec47F573;
    address constant UNISWAP_V3_QUOTER
        = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    address constant UNISWAP_V3_SWAP_ROUTER
        = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address constant UNISWAP_V3_NFT_DESCRIPTOR
        = 0x42B24A95702b9986e82d421cC3568932790A48Ec;
    address constant UNISWAP_V3_NFT_POSITION_DESCRIPTOR
        = 0x91ae842A5Ffd8d12023116943e72A606179294f3;
    address constant UNISWAP_V3_TRANSPARENT_UPGRADEABLE_PROXY
        = 0xEe6A57eC80ea46401049E92587E52f5Ec1c24785;
    address constant UNISWAP_V3_NFT_POSITION_MANAGER
        = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address constant UNISWAP_V3_MIGRATOR
        = 0xA5644E29708357803b5A882D272c41cC0dF92B34;
    address constant UNISWAP_V3_QUOTER_V2
        = 0x61fFE014bA17989E743c5F6cB21bF9697530B21e;
    address constant UNISWAP_V3_SWAP_ROUTER_V2
        = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address constant UNISWAP_V3_UNIVERSAL_ROUTER
        = 0x66a9893cC07D91D95644AEDD05D03f95e1dBA8Af;
    address constant UNISWAP_V3_STAKER
        = 0xe34139463bA50bD61336E0c446Bd8C0867c6fE65;

    /* ---------------------------------------------------------------------- */
    /*                                Multicall                               */
    /* ---------------------------------------------------------------------- */

    address constant MULTICALL
        = 0x1F98415757620B543A52E61c46B32eB19261F984;
    address constant MULTICALL2
        = 0x5BA1e12693Dc8F9c48aAD8770482f4739bEeD696;

    /* ---------------------------------------------------------------------- */
    /*                                 Permit2                                */
    /* ---------------------------------------------------------------------- */

    address constant PERMIT2
        = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    /* ---------------------------------------------------------------------- */
    /*                               Balancer V2                              */
    /* ---------------------------------------------------------------------- */

    address constant BALANCER_V2_COMPOSABLE_POOL_FACTORY
        = 0xDB8d758BCb971e482B2C45f7F8a7740283A1bd3A;
    address constant BALANCER_V2_WEIGHTED_POOL_FACTORY
        = 0x897888115Ada5773E02aA29F775430BFB5F34c51;

    /* ---------------------------------------------------------------------- */
    /*                               Balancer V3                              */
    /* ---------------------------------------------------------------------- */

    /* -------------------------------- Core -------------------------------- */

    address constant BALANCER_V3_PROTOCOL_FEE_CONTROLLER_1
        = 0xa731C23D7c95436Baaae9D52782f966E1ed07cc8;
    address constant BALANCER_V3_PROTOCOL_FEE_CONTROLLER_2
        = 0x212F884252792ebaaA811FB0678444b21c7C2879;
    address constant BALANCER_V3_PROTOCOL_FEE_SWEEPER
        = 0x90BD26fbb9dB17D75b56E4cA3A4c438FA7C93694;
    address constant BALANCER_V3_VAULT
        = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address constant BALANCER_V3_VAULT_ADMIN
        = 0x35fFB749B273bEb20F40f35EdeB805012C539864;
    address constant BALANCER_V3_VAULT_EXPLORER
        = 0xFc2986feAB34713E659da84F3B1FA32c1da95832;
    address constant BALANCER_V3_VAULT_EXTENSION
        = 0x0E8B07657D719B86e06bF0806D6729e3D528C9A9;
    address constant BALANCER_V3_VAULT_FACTORY
        = 0x0E8B07657D719B86e06bF0806D6729e3D528C9A9;

    /* ------------------------------- Routers ------------------------------ */

    address constant BALANCER_V3_AGGREGATOR_BATCH_ROUTER
        = 0xDADa7bE438bdD89416F4802B679E320b15c92D49;
    address constant BALANCER_V3_AGGREGATOR_ROUTER
        = 0x309abcAeFa19CA6d34f0D8ff4a4103317c138657;
    address constant BALANCER_V3_BATCH_ROUTER
        = 0x136f1EFcC3f8f88516B9E94110D56FDBfB1778d1;
    address constant BALANCER_V3_BUFFER_ROUTER
        = 0x9179C06629ef7f17Cb5759F501D89997FE0E7b45;
    address constant BALANCER_V3_COMPOSITE_LIQUIDITY_ROUTER
        = 0xb21A277466e7dB6934556a1Ce12eb3F032815c8A;
    address constant BALANCER_V3_LBP_MIGRATION_ROUTER
        = 0xCC267D25576b48f08A90C3605624Ab62a73a7A4E;
    address constant BALANCER_V3_ROUTER
        = 0xAE563E3f8219521950555F5962419C8919758Ea2;

    /* --------------------------- Pool Factories --------------------------- */
    
    address constant BALANCER_V3_GYRO_2CLP_POOL_FACTORY
        = 0xb96524227c4B5Ab908FC3d42005FE3B07abA40E9;
    address constant BALANCER_V3_GYRO_ECLP_POOL_FACTORY
        = 0xE9B0a3bc48178D7FE2F5453C8bc1415d73F966d0;
    address constant BALANCER_V3_LB_POOL_FACTORY
        = 0x4eff2d77D9fFbAeFB4b141A3e494c085b3FF4Cb5;
    address constant BALANCER_V3_MOCK_GYRO_2CLP_POOL
        = 0x4ffECD2dab8703a74BD13Ba10BcE3419B9f5fA80;
    address constant BLANACER_V3_MOCK_GYRO_ECLP_POOL
        = 0xe912C791f7c4b6323EfBA294F66C0dE93c50eB5F;
    address constant BALANCER_V3_MOCK_LB_POOL
        = 0xdBB8aD38C990Bd4ca2c88A6E6CfDF5045B0d4FB0;
    address constant BALANCER_V3_MOCK_RECLAMM_POOL
        = address(0x000aB3853737842bED7Dabe3540E3e5336FE62a6);
    address constant BALANCER_V3_MOCK_STABLE_POOL_V2
        = 0x95BC5CA62Ed018b5206342479ded82e18e46dcbf;
    address constant BALANCER_V3_MOCK_STABLE_SURGE_POOL
        = 0x0A8aFe82Eb901Cd5b19834ec9Ed764Ce4D85DD5D;
    address constant BALANCER_V3_MOCK_WEIGHTED_POOL
        = 0x527d0E14acc53FB040DeBeae1cAb973D23FB3568;
    address constant BALANCER_V3_MOCK_WRAPPED_BALANCER_POOL_TOKEN
        = 0x27ad56B2bfcb923091d80CA2D657AEbA5Ac3121c;
    address constant BALANCER_V3_RECLAMM_POOL_FACTORY
        = address(0xDaa273AeEc06e9CCb7428a77E2abb1E4659B16D2);
    address constant BALANCER_V3_STABLE_POOL_FACTORY
        = 0x8df317a729fcaA260306d7de28888932cb579b88;
    address constant BALANCER_V3_STABLE_SURGE_POOL_FACTORY
        = 0x355bD33F0033066BB3DE396a6d069be57353AD95;
    address constant BALANCER_V3_WEIGHTED_POOL_FACTORY
        = 0x230a59F4d9ADc147480f03B0D3fFfeCd56c3289a;
    address constant BALANCER_V3_WRAPPED_BALANCER_POOL_TOKEN_FACTORY
        = 0xA3d11a39dEA14d245659816d35456B89FfBfB744;

    /* ------------------------ Hooks and Peripherals ----------------------- */

    address constant BALANCER_V3_CONTRACT_REGISTRY
        = 0xa1D0791a41318c775707C56eAe247AF81a05322C;
    address constant BALANCER_V3_MEV_CAPTURE_HOOK
        = 0x1bcA39b01F451b0a05D7030e6e6981a73B716b1C;
    address constant BALANCER_V3_STABLE_SURGE_HOOK
        = 0xBDbADc891BB95DEE80eBC491699228EF0f7D6fF1;
    
    /* ------------------------ Authorization Contracts --------------------- */

    address constant BALANCER_V3_AUTHORIZER
        = 0xA331D84eC860Bf466b4CdCcFb4aC09a1B43F3aE6;
    address constant BALANCER_V3_AUTHORIZER_ADAPTOR
        = 0x8F42aDBbA1B16EaAE3BB5754915E0D06059aDd75;
    address constant BALANCER_V3_AUTHORIZER_ADAPTOR_ENTRYPOINT
        = 0xf5dECDB1f3d1ee384908Fbe16D2F0348AE43a9eA;
    address constant BALANCER_V3_AUTHORIZER_WITH_ADAPTOR_VALIDATION
        = 0x6048A8c631Fb7e77EcA533Cf9C29784e482391e7;
    address constant BALANCER_V3_TIMELOCK_AUTHORIZER
        = address(0);
    address constant BALANCER_V3_TIMELOCK_AUTHORIZER_MIGRATOR
        = address(0);

    /* ------------------------ Gauges and Governance ----------------------- */

    address constant BALANCER_V3_ARBITRUM_ROOT_GUAGE
        = 0x6337949cbC4825Bbd09242c811770F6F6fee9FfC;
    address constant BALANCER_V3_ARBITRUM_ROOT_GUAGE_FACTORY
        = 0x1c99324EDC771c82A0DCCB780CC7DDA0045E50e7;
    address constant BALANCER_V3_AVALANCHE_ROOT_GUAGE
        = 0x3Eae4a1c2E36870A006E816930d9f55DF0a72a13;
    address constant BALANCER_V3_AVALANCHE_ROOT_GUAGE_FACTORY
        = 0x22625eEDd92c81a219A83e1dc48f88d54786B017;
    address constant BALANCER_V3_BALANCER_CONTRACT_REGISTRY
        = 0xa1D0791a41318c775707C56eAe247AF81a05322C;
    address constant BALANCER_V3_BALANCER_HELPERS
        = 0x5aDDCCa35b7A0D07C74063c48700C8590E87864E;
    address constant BALANCER_V3_BALANCER_MINTER
        = 0x239e55F427D44C3cc793f49bFB507ebe76638a2b;
    address constant BALANCER_V3_BALANCER_POOL_DATA_QUERIES
        = 0x6d3197d069F8F9f1Fe7e23665Bc64CB77ED8b089;
    address constant BALANCER_V3_QUERIES
        = 0xE39B5e3B6D74016b2F6A9673D7d7493B6DF549d5;
    address constant BALANCER_V3_RELAYER
        = 0x35Cea9e57A393ac66Aaa7E25C391D52C74B5648f;
    address constant BALANCER_V3_BALANCER_TOKEN_ADMIN
        = 0xf302f9F50958c5593770FDf4d4812309fF77414f;
    address constant BALANCER_V3_BAL_TOKEN_HOLDER_FACTORY
        = 0xB848f50141F3D4255b37aC288C25C109104F2158;
    address constant BALANCER_V3_BASE_ROOT_GAUGE
        = 0x9a4d642b9876231BB9062559521A48097abFe6CB;
    address constant BALANCER_V3_BASE_ROOT_GAUGE_FACTORY
        = 0x8e3B64b3737097F283E965869e3503AA20F31E4D;
    address constant BALANCER_V3_GAUGE_ADDER
        = 0x5DbAd78818D4c8958EfF2d5b95b28385A22113Cd;
    address constant BALANCER_V3_GAUGE_CONTROLLER
        = 0x5DbAd78818D4c8958EfF2d5b95b28385A22113Cd;
    address constant BALANCER_V3_GAUGE_WORKING_BALANCER_HELPER
        = 0xdAB2583911E872a00A851fB80dCC78a4B46BA57c;
    address constant BALANCER_V3_GNOSIS_ROOT_GAUGE
        = 0x05277CE7D1e365d660624612d8b8b9B55bFD4518;
    address constant BALANCER_V3_GNOSIS_ROOT_GAUGE_FACTORY
        = 0x2a18B396829bc29F66a1E59fAdd7a0269A6605E8;
    address constant BALANCER_V3_LIQUIDITY_GAUGE_FACTORY
        = 0xf1665E19bc105BE4EDD3739F88315cC699cc5b65;
    address constant BALANCER_V3_LIQUIDITY_GAUGE_V5
        = 0xe5F96070CA00cd54795416B1a4b4c2403231c548;
    address constant BALANCER_V3_OMNI_VOTING_ESCROW
        = 0xE241C6e48CA045C7f631600a0f1403b2bFea05ad;
    address constant BALANCER_V3_OMNI_VOTING_ESCROW_ADAPTOR
        = 0x96484f2aBF5e58b15176dbF1A799627B53F13B6d;
    address constant BALANCER_V3_OPTIMISM_ROOT_GAUGE
        = 0xBC230b1a66A138cD9cFC7b352390025978dFAdde;
    address constant BALANCER_V3_OPTIMISM_ROOT_GAUGE_FACTORY
        = 0xBC230b1a66A138cD9cFC7b352390025978dFAdde;
    address constant BALANCER_V3_OPTIMISTIC_ROOT_GAUGE
        = 0x37302B98918382c43a176e5f3Bc7B11448cC6498;
    address constant BALANCER_V3_OPTIMISTIC_ROOT_GAUGE_FACTORY
        = 0x18CC3C68A5e64b40c846Aa6E45312cbcBb94f71b;
    address constant BALANCER_V3_POLYGON_ROOT_GAUGE
        = 0xfeb1A24C2752E53576133cdb718F25bC64eBDD52;
    address constant BALANCER_V3_POLYGON_ROOT_GAUGE_FACTORY
        = 0xa98Bce70c92aD2ef3288dbcd659bC0d6b62f8F13;
    address constant BALANCER_V3_POLYGON_ZKEVM_ROOT_GAUGE
        = 0xfeb1A24C2752E53576133cdb718F25bC64eBDD52;
    address constant BALANCER_V3_POLYGON_ZKEVM_ROOT_GAUGE_FACTORY
        = 0x9bF951848288cCD87d06FaC426150262cD3447De;
    address constant BALANCER_V3_PRESEEDED_VOTING_ESCROW_DELEGATION
        = 0xB496FF44746A8693A060FafD984Da41B253f6790;
    address constant BALANCER_V3_PROTOCOL_FEES_COLLECTOR
        = 0xce88686553686DA562CE7Cea497CE749DA109f9F;
    address constant BALANCER_V3_PROTOCOL_FEES_WITHDRAWER
        = 0x5ef4c5352882b10893b70DbcaA0C000965bd23c5;
    address constant BALANCER_V3_SINGLE_RECIPIENT_GAUGE
        = 0xb2007B8B7E0260042517f635CFd8E6dD2Dd7f007;
    address constant BALANCER_V3_SINGLE_RECIPIENT_GAUGE_FACTORY
        = 0x4fb47126Fa83A8734991E41B942Ac29A3266C968;
    address constant BALANCER_V3_STAKELESS_GAUGE_CHECKPOINTER
        = 0x0C8f71D19f87c0bD1b9baD2484EcC3388D5DbB98;
    address constant BALANCER_V3_VEBOOST_V2
        = 0x67F8DF125B796B05895a6dc8Ecf944b9556ecb0B;
    address constant BALANCER_V3_VOTING_ESCROW
        = 0xC128a9954e6c874eA3d62ce62B468bA073093F25;
    address constant BALANCER_V3_VOTING_ESCROW_DELEGATION
        = 0x2E96068b3D5B5BAE3D7515da4A1D2E52d08A2647;
    address constant BALANCER_V3_VOTING_ESCROW_DELEGATION_PROXY
        = 0x6f5a2eE11E7a772AeB5114A20d0D7c0ff61EB8A0;
    address constant BALANCER_V3_VOTING_ESCROW_REMAPPER
        = 0x83E443EF4f9963C77bd860f94500075556668cb8;

}