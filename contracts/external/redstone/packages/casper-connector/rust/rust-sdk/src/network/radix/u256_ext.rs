use crate::network::specific::U256;

pub trait U256Ext {
    fn max_value() -> Self;
}

impl U256Ext for U256 {
    fn max_value() -> Self {
        Self::MAX
    }
}
