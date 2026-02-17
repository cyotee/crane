extern crate alloc;

use crate::network::specific::U256;
use alloc::{format, string::String};

pub trait AsHexStr {
    fn as_hex_str(&self) -> String;
}

impl AsHexStr for &[u8] {
    #[allow(clippy::format_collect)]
    fn as_hex_str(&self) -> String {
        self.iter().map(|byte| format!("{:02x}", byte)).collect()
    }
}

#[cfg(feature = "network_casper")]
impl AsHexStr for casper_types::bytesrepr::Bytes {
    fn as_hex_str(&self) -> String {
        self.as_slice().as_hex_str()
    }
}

#[cfg(not(feature = "network_radix"))]
impl AsHexStr for U256 {
    fn as_hex_str(&self) -> String {
        format!("{:X}", self)
    }
}

#[cfg(feature = "network_radix")]
impl AsHexStr for U256 {
    fn as_hex_str(&self) -> String {
        let digits = self.to_digits();
        let mut result = String::new();
        for &part in &digits {
            if result.is_empty() || part != 0u64 {
                result.push_str(&format!("{:02X}", part));
            }
        }
        result
    }
}

impl AsHexStr for Vec<u8> {
    fn as_hex_str(&self) -> String {
        self.as_slice().as_hex_str()
    }
}

impl AsHexStr for Box<[u8]> {
    fn as_hex_str(&self) -> String {
        self.as_ref().as_hex_str()
    }
}

pub trait AsAsciiStr {
    fn as_ascii_str(&self) -> String;
}

impl AsAsciiStr for &[u8] {
    fn as_ascii_str(&self) -> String {
        self.iter().map(|&code| code as char).collect()
    }
}

impl AsAsciiStr for Vec<u8> {
    fn as_ascii_str(&self) -> String {
        self.as_slice().as_ascii_str()
    }
}

#[cfg(feature = "network_casper")]
impl AsAsciiStr for casper_types::bytesrepr::Bytes {
    fn as_ascii_str(&self) -> String {
        self.as_slice().as_ascii_str()
    }
}

impl AsAsciiStr for U256 {
    fn as_ascii_str(&self) -> String {
        let hex_string = self.as_hex_str();
        let bytes = (0..hex_string.len())
            .step_by(2)
            .map(|i| u8::from_str_radix(&hex_string[i..i + 2], 16))
            .collect::<Result<Vec<u8>, _>>()
            .unwrap();

        bytes.as_ascii_str()
    }
}

#[cfg(test)]
mod tests {
    use crate::network::{
        as_str::{AsAsciiStr, AsHexStr},
        specific::U256,
    };

    #[cfg(target_arch = "wasm32")]
    use wasm_bindgen_test::wasm_bindgen_test as test;

    const ETH: u32 = 4543560u32;

    #[test]
    fn test_as_hex_str() {
        let u256 = U256::from(ETH);
        let result = u256.as_hex_str();

        assert_eq!(result, "455448");
    }

    #[test]
    fn test_as_ascii_str() {
        let u256 = U256::from(ETH);
        let result = u256.as_ascii_str();

        assert_eq!(result, "ETH");
    }
}
