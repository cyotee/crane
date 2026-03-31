use crate::network::{error::Error, specific::NetworkSpecific};
use primitive_types::U256;
use std::eprintln;

mod from_bytes_repr;

pub struct Std;

impl NetworkSpecific for Std {
    type BytesRepr = Vec<u8>;
    type ValueRepr = U256;
    type _Self = Std;

    const VALUE_SIZE: usize = 32;

    fn print(text: String) {
        eprintln!("{}", text)
    }

    fn revert(error: Error) -> ! {
        panic!("{}", error)
    }
}
