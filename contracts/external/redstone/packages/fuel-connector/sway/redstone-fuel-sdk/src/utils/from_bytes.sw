library;

use std::bytes::Bytes;
use ::utils::from_bytes_convertible::*;

/// obtains a value from bytes with the suitable byte size"
pub trait FromBytes {
    fn from_bytes(bytes: Bytes) -> Self;
}

impl<T> FromBytes for T
where
    T: FromBytesConvertible,
{
    fn from_bytes(bytes: Bytes) -> Self {
        assert(bytes.len() <= Self::size());

        let mut bytes = bytes;

        while (bytes.len() < Self::size()) {
            bytes.insert(0, 0u8);
        }

        Self::_from_be_bytes(bytes)
    }
}
