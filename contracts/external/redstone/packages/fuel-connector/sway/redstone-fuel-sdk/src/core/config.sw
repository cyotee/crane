library;

use std::option::*;
use ::utils::vec::*;

/// Configuration for a RedStone payload processor.
///
/// Specifies the parameters necessary for the verification and aggregation of values
/// from various data points passed by the RedStone payload.
pub struct Config {
    /// List of identifiers for signers authorized to sign the data.
    ///
    /// Each signer is identified by a unique bits (`b256`),
    /// which represents their address.
    pub signers: Vec<b256>,
    /// Identifiers for the data feeds from which values are aggregated.
    ///
    /// Each data feed id is represented by the `u256` type.
    pub feed_ids: Vec<u256>,
    /// The minimum number of signers required validating the data.
    ///
    /// Specifies how many unique signers (from different addresses) are required
    /// for the data to be considered valid and trustworthy.
    pub signer_count_threshold: u64,
    /// The current block time in timestamp format, used for verifying data timeliness.
    ///
    /// The value's been expressed in seconds since the Unix epoch (January 1, 1970) and allows
    /// for determining whether the data is current in the context of blockchain time.
    pub block_timestamp: u64,
}

impl Config {
    pub fn cap(self) -> u64 {
        self.signers.len() * self.feed_ids.len()
    }

    pub fn signer_index(self, signer: b256) -> Option<u64> {
        self.signers.index_of(signer)
    }

    pub fn feed_id_index(self, feed_id: u256) -> Option<u64> {
        self.feed_ids.index_of(feed_id)
    }

    pub fn index(self, feed_id_index: u64, signer_index: u64) -> u64 {
        self.signers.len() * feed_id_index + signer_index
    }
}
