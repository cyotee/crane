library;

use std::bytes::*;
use ::utils::{
    bytes::*,
    from_bytes::FromBytes,
    from_bytes_convertible::*,
    sample::*,
    test_helpers::*,
};
use ::protocol::constants::*;

pub struct DataPoint {
    pub feed_id: u256,
    pub value: u256,
}

impl Eq for DataPoint {
    fn eq(self, other: Self) -> bool {
        self.feed_id == other.feed_id && self.value == other.value
    }
}

impl DataPoint {
    pub fn from_bytes(bytes: Bytes) -> Self {
        let (feed_id_bytes, value_bytes) = bytes.slice_tail(bytes.len() - DATA_FEED_ID_BS);

        Self {
            feed_id: u256::from_bytes(feed_id_bytes.zero_truncated()),
            value: u256::from_bytes(value_bytes),
        }
    }
}

#[test]
fn test_data_point_from_bytes() {
    let sample = SampleDataPackage::sample(0);
    let data_feed_bytes = sample.signable_bytes.cut(DATA_POINTS_COUNT_BS + DATA_POINT_VALUE_BYTE_SIZE_BS + TIMESTAMP_BS);

    assert(
        DataPoint {
            feed_id: ETH,
            value: SAMPLE_ETH_PRICE_0,
        } == DataPoint::from_bytes(data_feed_bytes),
    );
}
