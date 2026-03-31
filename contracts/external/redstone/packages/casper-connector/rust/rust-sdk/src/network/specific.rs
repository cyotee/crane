use crate::network::{_Network, error::Error, from_bytes_repr::FromBytesRepr};

pub trait NetworkSpecific {
    type BytesRepr: From<Vec<u8>> + Into<Vec<u8>>;
    type ValueRepr: FromBytesRepr<Vec<u8>>;
    type _Self;

    const VALUE_SIZE: usize;

    fn print(_text: String);
    fn revert(error: Error) -> !;
}

pub(crate) type Network = <_Network as NetworkSpecific>::_Self;
pub type Bytes = <_Network as NetworkSpecific>::BytesRepr;
pub type U256 = <_Network as NetworkSpecific>::ValueRepr;
pub const VALUE_SIZE: usize = <_Network as NetworkSpecific>::VALUE_SIZE;

pub fn print(_text: String) {
    Network::print(_text)
}

pub fn revert(error: Error) -> ! {
    Network::revert(error)
}
