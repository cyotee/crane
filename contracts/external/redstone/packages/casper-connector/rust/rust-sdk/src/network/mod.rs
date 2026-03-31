pub mod as_str;
pub mod assert;
pub mod error;
pub mod from_bytes_repr;
pub mod print_debug;
pub mod specific;

#[cfg(feature = "network_casper")]
pub mod casper;

#[cfg(feature = "network_casper")]
pub type _Network = casper::Casper;

#[cfg(feature = "network_radix")]
pub mod radix;

#[cfg(feature = "network_radix")]
pub type _Network = radix::Radix;

pub mod flattened;
#[cfg(all(not(feature = "network_casper"), not(feature = "network_radix")))]
mod pure;

#[cfg(all(not(feature = "network_casper"), not(feature = "network_radix")))]
pub type _Network = pure::Std;
