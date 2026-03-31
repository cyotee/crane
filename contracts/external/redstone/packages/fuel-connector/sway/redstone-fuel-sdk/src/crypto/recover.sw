library;

use ::utils::bytes::*;
use std::{
    b512::*,
    bytes::*,
    bytes_conversions::b256::*,
    ecr::{
        ec_recover,
        EcRecoverError,
    },
    hash::Hasher,
    logging::log,
    vm::evm::{
        ecr::ec_recover_evm_address,
        evm_address::EvmAddress,
    },
};
use ::utils::sample::{SAMPLE_ID_MALLEABILITY, SAMPLE_ID_V27, SAMPLE_ID_V28, SampleDataPackage};

const ECDSA_SIGNATURE_LENGTH = 65;
const ECDSA_N_DIV_2 = 0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0;

pub fn recover_signer_address(signature_bytes: Bytes, signable_bytes: Bytes) -> b256 {
    assert(signature_bytes.len() == ECDSA_SIGNATURE_LENGTH);

    let (r_bytes, s_bytes) = signature_bytes.slice_tail_offset(32, 1);
    let v = signature_bytes.get(signature_bytes.len() - 1).unwrap();
    let r_number = b256::from_be_bytes(r_bytes);
    let s_number = b256::from_be_bytes(s_bytes);

    let mut hasher = Hasher::new();
    hasher.write(signable_bytes);
    let hash = hasher.keccak256();

    recover_public_address(r_number, s_number, v, hash).unwrap().bits()
}

fn recover_public_address(
    r: b256,
    s: b256,
    v: u8,
    msg_hash: b256,
) -> Result<EvmAddress, EcRecoverError> {
    let v_256 = match v {
        27 => b256::zero(),
        28 => b256::from(0x01u256),
        _ => return Err(EcRecoverError::UnrecoverablePublicKey),
    };

    if (s > ECDSA_N_DIV_2) {
        return return Err(EcRecoverError::UnrecoverablePublicKey);
    }

    let s_with_parity = s | (v_256 << 255);
    let signature = B512::from((r, s_with_parity));

    let address = ec_recover_evm_address(signature, msg_hash);

    if (address.is_ok() && address.unwrap().is_zero()) {
        return Err(EcRecoverError::UnrecoverablePublicKey);
    }

    address
}

#[test]
fn test_recover_signer_address_v27() {
    let sample = SampleDataPackage::sample(SAMPLE_ID_V27);
    let result = recover_signer_address(sample.signature_bytes(), sample.signable_bytes);

    assert(sample.signer_address == result);
}

#[test]
fn test_recover_signer_address_v28() {
    let sample = SampleDataPackage::sample(SAMPLE_ID_V28);
    let result = recover_signer_address(sample.signature_bytes(), sample.signable_bytes);

    assert(sample.signer_address == result);
}

#[test(should_revert)]
fn test_recover_signer_address_v27_as_0() {
    let sample = SampleDataPackage::sample(SAMPLE_ID_V27);
    let mut sig = sample.signature_bytes();
    sig.set(64, 0);
    let _ = recover_signer_address(sig, sample.signable_bytes);
}

#[test(should_revert)]
fn test_recover_signer_address_v28_as_1() {
    let sample = SampleDataPackage::sample(SAMPLE_ID_V28);
    let mut sig = sample.signature_bytes();
    sig.set(64, 1);
    let _ = recover_signer_address(sig, sample.signable_bytes);
}

#[test(should_revert)]
#[test]
fn test_recover_signer_address_malleability() {
    let sample = SampleDataPackage::sample(SAMPLE_ID_MALLEABILITY);
    let _ = recover_signer_address(sample.signature_bytes(), sample.signable_bytes);
}
