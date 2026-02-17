mod keccak256;
pub(crate) mod recover;

pub(crate) type Keccak256Hash = [u8; 32];
pub(crate) type Secp256SigRs = [u8; 64];
pub(crate) type EcdsaUncompressedPublicKey = [u8; 65];
