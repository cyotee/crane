library;

use std::bytes::*;
use ::utils::{bytes::*, vec::*};

pub const SAMPLE_SIGNER_ADDRESS_0 = 0x000000000000000000000000ad05Ce43E0bCD11345f08a28995951DEc30D5226;
pub const SAMPLE_SIGNER_ADDRESS_1 = 0x000000000000000000000000dE13FdEE7a9B483129a81794d02FCB4021069f0C;

pub const SAMPLE_ETH_PRICE_0 = 0x38b8d93cdfu256;
pub const SAMPLE_ETH_PRICE_1 = 0x38ba3376e5u256;
pub const SAMPLE_BTC_PRICE_0 = 0x58f356b791eu256;
pub const SAMPLE_BTC_PRICE_1 = 0x58f32c910a0u256;

pub const SAMPLE_TIMESTAMP = 1727881330;
pub const DIFFERENT_TIMESTAMP = 1728055861;

pub const AVAX = 0x41564158u256;
pub const BTC = 0x425443u256;
pub const ETH = 0x455448u256;

pub const SAMPLE_ID_V27 = 0;
pub const SAMPLE_ID_V28 = 5;
pub const SAMPLE_ID_MALLEABILITY = 6;

const SAMPLE_ID_ETH_SIGNER_0 = 0;
const SAMPLE_ID_ETH_SIGNER_1 = 1;
const SAMPLE_ID_ETH_OTHERTS_0 = 2;
const SAMPLE_ID_ETH_OTHERTS_1 = 3;
const SAMPLE_ID_BTC_SIGNER_0 = 4;
const SAMPLE_ID_BTC_SIGNER_1 = 5;

pub struct SamplePayload {
    pub data_packages: Vec<SampleDataPackage>,
}

pub struct SampleDataPackage {
    pub signable_bytes: Bytes,
    pub signature_r: b256,
    pub signature_s: b256,
    pub signature_v: u8,
    pub signer_address: b256,
}

struct SampleDataPackageInput {
    pub initial: [u8; 3],
    pub number_of_mid_zeroes: u8,
    pub number_low: b256,
    pub signature_r: b256,
    pub signature_s: b256,
    pub signature_v: u8,
    pub signer_address: b256,
}

const SAMPLES = [
    // 77 bytes are split into 3 parts, the first one consists of 3 bytes, the last one consists of 18 bytes + 14 bytes of zero-bytes, so we have 77-(3+18+14) = 42 zero-bytes inside:
    // 0x45544800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002603c77cf6018697ef555000000020000001
    // signature: 0x54bc55649dbae70cbf6279bc68485dfdd3d4915e0baae54e252af69f4c012faf34465a4d835255391ddfd36736b6d8dcd3fbb0ff5798419ea8c287936680bfc31b
    // malleability, 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141-signature_s for the previous case
    SampleDataPackageInput {
        initial: [0x45, 0x54, 0x48],
        number_of_mid_zeroes: 42,
        number_low: 0x000000000000000000000000000038b8d93cdf01924dc0bd5000000020000001,
        signature_r: 0xbf817c39e0554c231da699f344b58e1c8fbcc17b2142bff13e431eababb72f95,
        signature_s: 0x68528c52cf93a03c3dd578afb17a69c8f57a36f81312f351186ac4d2d89a48b8,
        signature_v: 0x1c,
        signer_address: SAMPLE_SIGNER_ADDRESS_0,
    },
    SampleDataPackageInput {
        initial: [0x45, 0x54, 0x48],
        number_of_mid_zeroes: 42,
        number_low: 0x000000000000000000000000000038ba3376e501924dc0bd5000000020000001,
        signature_r: 0x1d5c0dd797827f3be1c3993fb899d02507d390156826e1735dfd670fc8032070,
        signature_s: 0x22f81053c5b7c085d9009e85ba91a8d4f462b0938cca669af6ada814c17b1f70,
        signature_v: 0x1c,
        signer_address: SAMPLE_SIGNER_ADDRESS_1,
    },
    SampleDataPackageInput {
        initial: [0x45, 0x54, 0x48],
        number_of_mid_zeroes: 42,
        number_low: 0x000000000000000000000000000037ab19f5ba01925820fd5000000020000001,
        signature_r: 0x0be65573e519bbad56fd9ac1405de27fbc26713a6bf3a912c65f374549bf61f8,
        signature_s: 0x6829a0042c75037c2d3e3d96e24a149ac10f147f4e34bca387deda6ef5cf9dd8,
        signature_v: 0x1b,
        signer_address: SAMPLE_SIGNER_ADDRESS_1,
    },
    SampleDataPackageInput {
        initial: [0x45, 0x54, 0x48],
        number_of_mid_zeroes: 42,
        number_low: 0x000000000000000000000000000037abfecec9019258214b7000000020000001,
        signature_r: 0x3bebe5b70c57c05c51ecff63e5e63e4efc414396f962aa9ce07946e9c70b5bab,
        signature_s: 0x4688cd1d16109e0f3a1340907c988784ee5bbdfc3374886957c2eafa17163245,
        signature_v: 0x1b,
        signer_address: SAMPLE_SIGNER_ADDRESS_1,
    },
    SampleDataPackageInput {
        initial: [0x42, 0x54, 0x43],
        number_of_mid_zeroes: 42,
        number_low: 0x00000000000000000000000000058f356b791e01924dc0bd5000000020000001,
        signature_r: 0xdde5f74d7203e6cadbdaef415a6c016a04a42aeb73999d610ef91675e23c4ca8,
        signature_s: 0x4fe51ffc037a35c0c488345b6c53704dbe2880aac70c3011c3b6d5314f2a69a2,
        signature_v: 0x1b,
        signer_address: SAMPLE_SIGNER_ADDRESS_0,
    },
    SampleDataPackageInput {
        initial: [0x42, 0x54, 0x43],
        number_of_mid_zeroes: 42,
        number_low: 0x00000000000000000000000000058f32c910a001924dc0bd5000000020000001,
        signature_r: 0x6307247862e106f0d4b3cde75805ababa67325953145aa05bdd219d90a741e0e,
        signature_s: 0x1458648a940c5092493d95712c7ef1c2626b639f3f706fa59e43c0a13a8edfc3,
        signature_v: 0x1c,
        signer_address: SAMPLE_SIGNER_ADDRESS_1,
    },
    SampleDataPackageInput {
        initial: [0x42, 0x54, 0x43],
        number_of_mid_zeroes: 42,
        number_low: 0x00000000000000000000000000058f32c910a001924dc0bd5000000020000001,
        signature_r: 0x6307247862e106f0d4b3cde75805ababa67325953145aa05bdd219d90a741e0e,
        signature_s: 0xeba79b756bf3af6db6c26a8ed3810e3c584379476fd83096218e9deb95a7617e,
        signature_v: 0x1b,
        signer_address: SAMPLE_SIGNER_ADDRESS_1,
    },
];

impl SampleDataPackage {
    pub fn sample(index: u64) -> Self {
        let input = SAMPLES[index];

        Self {
            signature_r: input.signature_r,
            signature_s: input.signature_s,
            signature_v: input.signature_v,
            signable_bytes: signable_bytes(input.initial, input.number_of_mid_zeroes, input.number_low),
            signer_address: input.signer_address,
        }
    }
    pub fn signature_bytes(self) -> Bytes {
        signature_bytes(self.signature_r, self.signature_s, self.signature_v)
    }

    pub fn bytes(self) -> Bytes {
        self.signable_bytes.join(self.signature_bytes())
    }
}

impl SamplePayload {
    pub fn sample(indices: Vec<u64>) -> SamplePayload {
        let mut data_packages = Vec::new();
        let mut i = 0;
        while (i < indices.len()) {
            data_packages.push(SampleDataPackage::sample(indices.get(i).unwrap()));
            i += 1;
        }

        Self { data_packages }
    }

    pub fn bytes(self) -> Bytes {
        const REDSTONE_MARKER = [0x00, 0x00, 0x02, 0xed, 0x57, 0x01, 0x1e, 0x00, 0x00];
        const UNSIGNED_METADATA_BYTE_SIZE_BS = 3;
        const DATA_PACKAGES_COUNT_BS = 2;
        let mut bytes = Bytes::new();
        let mut i = 0;
        while (i < self.data_packages.len()) {
            bytes.append(self.data_packages.get(i).unwrap().bytes());
            i += 1;
        }
        i = 0;
        while (i < DATA_PACKAGES_COUNT_BS - 1) {
            bytes.push(0x00);
            i += 1;
        }
        bytes.push(self.data_packages.len().try_as_u8().unwrap()); // number of data packages
        i = 0;
        while (i < UNSIGNED_METADATA_BYTE_SIZE_BS) {
            bytes.push(0x00);
            i += 1;
        }
        i = 0;
        while (i < 9) {
            bytes.push(REDSTONE_MARKER[i]);
            i += 1;
        }

        bytes
    }

    pub fn different_timestamps() -> SamplePayload {
        Self::sample(Vec::<u64>::new().with(SAMPLE_ID_ETH_OTHERTS_0).with(SAMPLE_ID_ETH_OTHERTS_1))
    }

    pub fn eth_btc_2x2() -> SamplePayload {
        Self::sample(
            Vec::<u64>::new()
                .with(SAMPLE_ID_ETH_SIGNER_0)
                .with(SAMPLE_ID_ETH_SIGNER_1)
                .with(SAMPLE_ID_BTC_SIGNER_1)
                .with(SAMPLE_ID_BTC_SIGNER_0),
        )
    }

    pub fn eth_btc_2plus1() -> SamplePayload {
        Self::sample(
            Vec::<u64>::new()
                .with(SAMPLE_ID_ETH_SIGNER_0)
                .with(SAMPLE_ID_ETH_SIGNER_1)
                .with(SAMPLE_ID_BTC_SIGNER_0),
        )
    }

    pub fn eth_duplicated_btc() -> SamplePayload {
        Self::sample(
            Vec::<u64>::new()
                .with(SAMPLE_ID_BTC_SIGNER_0)
                .with(SAMPLE_ID_BTC_SIGNER_0)
                .with(SAMPLE_ID_ETH_SIGNER_0),
        )
    }
}

fn signable_bytes(initial: [u8; 3], number_of_mid_zeroes: u8, number_low: b256) -> Bytes {
    let mut signable_bytes = Bytes::new();
    signable_bytes.push(initial[0]);
    signable_bytes.push(initial[1]);
    signable_bytes.push(initial[2]);
    let mut i: u8 = 0;
    while (i < number_of_mid_zeroes) {
        signable_bytes.push(0x00);
        i += 1;
    }
    signable_bytes.append(Bytes::from(number_low));

    signable_bytes
}

fn signature_bytes(r: b256, s: b256, v: u8) -> Bytes {
    let mut signature_bytes = Bytes::from(r);
    signature_bytes.append(Bytes::from(s));
    signature_bytes.push(v);

    signature_bytes
}
