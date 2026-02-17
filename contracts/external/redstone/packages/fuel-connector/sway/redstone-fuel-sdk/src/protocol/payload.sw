library;

use std::bytes::*;
use ::utils::{bytes::*, from_bytes::FromBytes, sample::*, test_helpers::*, vec::*};
use ::protocol::{
    constants::*,
    data_package::{
        DataPackage,
        make_data_package,
    },
    data_point::DataPoint,
};

pub struct Payload {
    pub data_packages: Vec<DataPackage>,
}

impl Eq for Payload {
    fn eq(self, other: Self) -> bool {
        self.data_packages == other.data_packages
    }
}

impl Payload {
    pub fn from_bytes(bytes: Bytes) -> Self {
        let (marker_rest, marker_bytes) = bytes.slice_tail(REDSTONE_MARKER_BS);
        let mut i = 0;
        while (i < REDSTONE_MARKER_BS) {
            if (marker_bytes.get(i).unwrap().as_u64() != REDSTONE_MARKER[i])
            {
                revert(WRONG_REDSTONE_MARKER + i);
            }
            i += 1;
        }

        let (unsigned_metadata_rest, unsigned_metadata_size) = marker_rest.slice_number(UNSIGNED_METADATA_BYTE_SIZE_BS);
        let (data_package_count_rest, data_package_count) = unsigned_metadata_rest.slice_number_offset(DATA_PACKAGES_COUNT_BS, unsigned_metadata_size);

        let mut i = 0;
        let mut data_packages = Vec::with_capacity(data_package_count);
        let mut bytes_rest = data_package_count_rest;
        while (i < data_package_count) {
            let (data_package, bytes_taken) = make_data_package(bytes_rest);
            data_packages.push(data_package);
            let (head, _) = bytes_rest.slice_tail(bytes_taken);
            bytes_rest = head;

            i += 1;
        }

        if (bytes_rest.len() > 0) {
            revert(WRONG_PAYLOAD);
        }

        Self { data_packages }
    }
}

#[test]
fn test_payload_from_bytes() {
    let sample = SamplePayload::sample(Vec::<u64>::new().with(0));
    let payload = Payload::from_bytes(sample.bytes());

    let data_package = DataPackage {
        signer_address: sample.data_packages.get(0).unwrap().signer_address,
        data_points: Vec::<DataPoint>::new().with(DataPoint {
            feed_id: ETH,
            value: SAMPLE_ETH_PRICE_0,
        }),
        timestamp: SAMPLE_TIMESTAMP * 1000,
    };

    assert(
        Payload {
            data_packages: Vec::<DataPackage>::new().with(data_package),
        } == payload,
    );
}

#[test(should_revert)]
fn test_payload_from_bytes_longer_marker() {
    let sample = SamplePayload::sample(Vec::<u64>::new().with(0));
    let _ = Payload::from_bytes(sample.bytes().with(0x00));
}

#[test(should_revert)]
fn test_payload_from_bytes_shorter_marker() {
    let sample = SamplePayload::sample(Vec::<u64>::new().with(0));
    let _ = Payload::from_bytes(sample.bytes().cut(1));
}

#[test(should_revert)]
fn test_payload_from_bytes_changed_marker() {
    let sample = SamplePayload::sample(Vec::<u64>::new().with(0));
    let mut bytes = sample.bytes();
    bytes.swap(bytes.len() - 4, bytes.len() - 3);
    let _ = Payload::from_bytes(bytes);
}

#[test(should_revert)]
fn test_payload_from_bytes_additional_prefix_character() {
    let sample = SamplePayload::sample(Vec::<u64>::new().with(0));
    let mut bytes = sample.bytes();
    bytes.insert(0, 0x00);
    let _ = Payload::from_bytes(bytes);
}

#[test]
fn test_payload_from_bytes_empty() {
    let sample = SamplePayload::sample(Vec::<u64>::new());
    let payload = Payload::from_bytes(sample.bytes());

    assert(Payload {
        data_packages: Vec::<DataPackage>::new(),
    } == payload);
}
