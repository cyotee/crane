use crate::network::{
    from_bytes_repr::{FromBytesRepr, Sanitized},
    specific::U256,
};

impl FromBytesRepr<Vec<u8>> for U256 {
    fn from_bytes_repr(bytes: Vec<u8>) -> Self {
        match bytes.len() {
            0 => U256::ZERO,
            1 => U256::from(bytes[0]),
            _ => {
                // TODO: make it cheaper
                let mut bytes_le = bytes.sanitized();
                bytes_le.reverse();

                U256::from_le_bytes(bytes_le.as_slice())
            }
        }
    }
}
