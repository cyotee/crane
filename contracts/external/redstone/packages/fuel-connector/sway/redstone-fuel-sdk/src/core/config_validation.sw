library;

use ::protocol::{data_package::DataPackage, data_point::DataPoint, payload::Payload};
use ::core::{config::Config, errors::*, validation::*};
use ::utils::{from_bytes::*, test_helpers::*, vec::*};

trait Validation {
    fn check_parameters(self);
    fn validate_timestamps(self, payload: Payload) -> u64;
    fn validate_signer_count(self, values: Vec<Vec<u256>>);
    fn validate_signer(self, data_package: DataPackage, index: u64) -> u64;
}

impl Validation for Config {
    fn check_parameters(self) {
        assert_signers(self.signers, self.signer_count_threshold);

        require(self.feed_ids.len() > 0, RedStoneError::EmptyFeedIds);
        require(
            self.feed_ids
                .find_duplicate()
                .is_none(),
            RedStoneError::DuplicatedFeedId,
        )
    }

    fn validate_timestamps(self, payload: Payload) -> u64 {
        let first_timestamp = payload.data_packages.get(0).unwrap().timestamp;
        validate_timestamp(first_timestamp, self.block_timestamp * 1000);

        let mut i = 1;
        while (i < payload.data_packages.len()) {
            let timestamp = payload.data_packages.get(i).unwrap().timestamp;
            require(
                timestamp == first_timestamp,
                RedStoneError::TimestampDifferentThanOthers((first_timestamp, timestamp, i)),
            );

            i += 1;
        }

        first_timestamp
    }

    fn validate_signer_count(self, results: Vec<Vec<u256>>) {
        let mut i = 0;
        while (i < self.feed_ids.len()) {
            let values = results.get(i).unwrap();
            require(
                values
                    .len() >= self.signer_count_threshold,
                RedStoneError::InsufficientSignerCount((values.len(), i)),
            );

            i += 1;
        }
    }

    fn validate_signer(self, data_package: DataPackage, index: u64) -> u64 {
        let s = self.signer_index(data_package.signer_address);

        require(
            s
                .is_some(),
            RedStoneError::SignerNotRecognized((data_package.signer_address, index)),
        );

        s.unwrap()
    }
}

fn assert_signers(allowed_signers: Vec<b256>, signer_count_threshold: u64) {
    require(
        allowed_signers
            .len() > 0,
        RedStoneError::EmptyAllowedSigners,
    );
    require(
        allowed_signers
            .len() >= signer_count_threshold,
        RedStoneError::SignerCountThresholdToSmall,
    );
    require(
        allowed_signers
            .find_duplicate()
            .is_none(),
        RedStoneError::DuplicatedSigner,
    );
}

#[test]
fn test_validate_one_signer() {
    let results = make_results();
    let config = make_config(1);

    config.validate_signer_count(results);
}

#[test]
fn test_validate_two_signers() {
    let results = make_results();
    let config = make_config(2);

    config.validate_signer_count(results);
}

#[test(should_revert)]
fn test_validate_three_signers() {
    let results = make_results();
    let config = make_config(3);

    config.validate_signer_count(results);
}

#[test]
fn test_check_parameters_threshold_equal_signer_count() {
    let config = make_config(3);

    config.check_parameters();
}

#[test(should_revert)]
fn test_check_parameters_should_revert_threshold_bigger_than_signer_count() {
    let config = make_config(4);

    config.check_parameters();
}

#[test(should_revert)]
fn test_check_parameters_should_revert_empty_signer_list() {
    let mut config = make_config(0);

    config.signers = Vec::new();
    config.check_parameters();
}

#[test(should_revert)]
fn test_check_parameters_should_revert_duplicated_feed_id() {
    let mut config = make_config(3);

    config.feed_ids = Vec::<u256>::new().with(0x444444u256).with(0x445566u256).with(0x444444u256);
    config.check_parameters();
}

#[test(should_revert)]
fn test_check_parameters_should_revert_duplicated_signer() {
    let mut config = make_config(3);

    config.signers = Vec::<b256>::new().with(b256::from(0x02u256)).with(b256::from(0x02u256)).with(b256::from(0x03u256));
    config.check_parameters();
}

#[test]
fn test_validate_timestamps() {
    let mut config = make_config(2);

    let data_package = DataPackage {
        signer_address: b256::from(0x0201u256),
        data_points: Vec::<DataPoint>::new().with(DataPoint {
            feed_id: 0x445566,
            value: 0x01u256,
        }).with(DataPoint {
            feed_id: 0x554466,
            value: 0x02u256,
        }),
        timestamp: 1234,
    };

    assert(
        config
            .validate_timestamps(Payload {
                data_packages: Vec::<DataPackage>::new().with(data_package).with(data_package),
            }) == 1234,
    );
}

fn make_results() -> Vec<Vec<u256>> {
    let mut results = Vec::<Vec<u256>>::new();

    let set1 = Vec::<u256>::new().with(0x111u256).with(0x777u256);
    let set2 = Vec::<u256>::new().with(0x444u256).with(0x555u256).with(0x666u256);
    let set3 = Vec::<u256>::new().with(0x222u256).with(0x333u256);

    results.with(set1).with(set2).with(set3)
}

fn make_config(signer_count_threshold: u64) -> Config {
    let feed_ids = Vec::<u256>::new().with(0x444444u256).with(0x445566u256).with(0x556644u256);

    let config = Config {
        feed_ids,
        signers: Vec::<b256>::new().with(b256::from(0x01u256)).with(b256::from(0x02u256)).with(b256::from(0x03u256)),
        signer_count_threshold,
        block_timestamp: 0,
    };

    config
}
