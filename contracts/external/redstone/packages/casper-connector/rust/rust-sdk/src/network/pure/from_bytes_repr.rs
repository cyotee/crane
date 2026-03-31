use crate::network::{
    from_bytes_repr::{FromBytesRepr, Sanitized},
    specific::U256,
};

impl FromBytesRepr<Vec<u8>> for U256 {
    fn from_bytes_repr(bytes: Vec<u8>) -> Self {
        Self::from_big_endian(bytes.sanitized().as_slice())
    }
}
