library;

use std::{bytes::*, logging::log, vec::Vec};
use ::crypto::recover::recover_signer_address;
use ::utils::{bytes::*, from_bytes::FromBytes, sample::*, test_helpers::*, vec::*};
use ::protocol::{constants::*, data_point::DataPoint};

pub struct DataPackage {
    pub timestamp: u64,
    pub signer_address: b256,
    pub data_points: Vec<DataPoint>,
}

impl Eq for DataPackage {
    fn eq(self, other: Self) -> bool {
        self.timestamp == other.timestamp && self.signer_address == other.signer_address && self.data_points == other.data_points
    }
}

pub fn make_data_package(bytes: Bytes) -> (DataPackage, u64) {
    let (signature_rest, signature_bytes) = bytes.slice_tail(SIGNATURE_BS);
    let (data_point_count_rest, data_point_count) = signature_rest.slice_number(DATA_POINTS_COUNT_BS);
    let (data_point_value_size_rest, data_point_value_size) = data_point_count_rest.slice_number(DATA_POINT_VALUE_BYTE_SIZE_BS);
    let (timestamp_rest, timestamp) = data_point_value_size_rest.slice_number(TIMESTAMP_BS);
    let (_, data_points_bytes) = timestamp_rest.slice_tail(data_point_count * (data_point_value_size + DATA_FEED_ID_BS));

    let mut data_points = Vec::with_capacity(data_point_count);
    let mut i = 0;
    let mut rest = data_points_bytes;
    while (i < data_point_count) {
        let (head, dp_bytes) = rest.slice_tail(DATA_FEED_ID_BS + data_point_value_size);
        rest = head;
        data_points.push(DataPoint::from_bytes(dp_bytes));

        i += 1;
    }
    let signable_bytes_len = DATA_POINTS_COUNT_BS + DATA_POINT_VALUE_BYTE_SIZE_BS + TIMESTAMP_BS + data_point_count * (data_point_value_size + DATA_FEED_ID_BS);
    let (_, signable_bytes) = signature_rest.slice_tail(signable_bytes_len);

    let signer_address = recover_signer_address(signature_bytes, signable_bytes);

    let data_package = DataPackage {
        signer_address,
        timestamp,
        data_points,
    };

    return (data_package, signable_bytes_len + SIGNATURE_BS);
}

#[test]
fn test_make_data_package() {
    let sample = SampleDataPackage::sample(0);
    let (data_package, bytes_taken) = make_data_package(sample.bytes());
    assert(
        bytes_taken == DATA_POINTS_COUNT_BS + DATA_POINT_VALUE_BYTE_SIZE_BS + TIMESTAMP_BS + 32 + DATA_FEED_ID_BS + SIGNATURE_BS,
    );

    assert(
        DataPackage {
            signer_address: sample.signer_address,
            data_points: Vec::new().with(DataPoint {
                feed_id: ETH,
                value: SAMPLE_ETH_PRICE_0,
            }),
            timestamp: SAMPLE_TIMESTAMP * 1000,
        } == data_package,
    );
}
