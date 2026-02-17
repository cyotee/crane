use crate::network::{error::Error, specific::NetworkSpecific};

mod from_bytes_repr;
pub mod u256_ext;

pub struct Radix;

impl NetworkSpecific for Radix {
    type BytesRepr = Vec<u8>;
    type ValueRepr = radix_common::math::bnum_integer::U256;
    type _Self = Self;

    const VALUE_SIZE: usize = 32;

    fn print(_text: String) {
        #[cfg(all(not(test), feature = "print_debug"))]
        {
            scrypto::prelude::info!("{}", _text);
        }

        #[cfg(test)]
        {
            println!("{}", _text);
        }
    }

    fn revert(error: Error) -> ! {
        #[cfg(not(test))]
        {
            scrypto::prelude::Runtime::panic(error.to_string())
        }

        #[cfg(test)]
        {
            panic!("{}", error)
        }
    }
}
