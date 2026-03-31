use crate::crypto::Keccak256Hash;
#[cfg(not(all(feature = "crypto_radix", target_arch = "wasm32")))]
use sha3::Digest;

#[cfg(not(all(feature = "crypto_radix", target_arch = "wasm32")))]
pub fn keccak256(data: &[u8]) -> Keccak256Hash {
    sha3::Keccak256::new_with_prefix(data)
        .finalize()
        .as_slice()
        .try_into()
        .unwrap()
}

#[cfg(all(feature = "crypto_radix", target_arch = "wasm32"))]
pub fn keccak256(data: &[u8]) -> Keccak256Hash {
    scrypto::prelude::CryptoUtils::keccak256_hash(data).0
}

#[cfg(not(all(feature = "crypto_radix", target_arch = "wasm32")))]
#[cfg(feature = "helpers")]
#[cfg(test)]
mod tests {
    use crate::{crypto::keccak256::keccak256, helpers::hex::hex_to_bytes};

    #[cfg(target_arch = "wasm32")]
    use wasm_bindgen_test::wasm_bindgen_test as test;

    const MESSAGE: &str = "415641580000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d394303d018d79bf0ba000000020000001";
    const MESSAGE_HASH: &str = "f0805644755393876d0e917e553f0c206f8bc68b7ebfe73a79d2a9e7f5a4cea6";
    const EMPTY_MESSAGE_HASH: &str =
        "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";

    #[test]
    fn test_keccak256() {
        let hash = keccak256(hex_to_bytes(MESSAGE.into()).as_slice());

        assert_eq!(hash.as_ref(), hex_to_bytes(MESSAGE_HASH.into()).as_slice());
    }

    #[test]
    fn test_keccak256_empty() {
        let hash = keccak256(vec![].as_slice());

        assert_eq!(
            hash.as_ref(),
            hex_to_bytes(EMPTY_MESSAGE_HASH.into()).as_slice()
        );
    }
}
