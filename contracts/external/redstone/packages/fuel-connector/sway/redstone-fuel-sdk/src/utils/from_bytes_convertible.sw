library;

use std::{bytes::Bytes, bytes_conversions::{u256::*, u64::*}};

pub trait FromBytesConvertible {
    fn size() -> u64;
    fn _from_be_bytes(bytes: Bytes) -> Self;
}

impl FromBytesConvertible for u256 {
    fn size() -> u64 {
        32
    }

    fn _from_be_bytes(bytes: Bytes) -> Self {
        Self::from_be_bytes(bytes)
    }
}

impl FromBytesConvertible for u64 {
    fn size() -> u64 {
        8
    }

    fn _from_be_bytes(bytes: Bytes) -> Self {
        Self::from_be_bytes(bytes)
    }
}
