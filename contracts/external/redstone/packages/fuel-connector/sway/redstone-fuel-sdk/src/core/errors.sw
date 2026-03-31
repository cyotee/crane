//! various errors
library;

/// # Enum `RedStoneError`
///
/// This enum represents various errors that can occur during the execution of a RedStone payload processing.
/// Each variant contains relevant information for specific error types.
///
/// ## Variants
///
/// ### `EmptyAllowedSigners`
///
/// ```sway
/// EmptyAllowedSigners: ()
/// ```
///
/// - **Description**: Raised when the allowed signers list is empty.
///
/// ### `EmptyFeedIds`
///
/// ```sway
/// EmptyFeedIds: ()
/// ```
///
/// - **Description**: Raised when the list of feed IDs is empty.
///
/// ### `SignerCountThresholdToSmall`
///
/// ```sway
/// SignerCountThresholdToSmall: ()
/// ```
///
/// - **Description**: Raised when the signer count threshold is smaller than the signer list length.
///
/// ### `DuplicatedSigner`
///
/// ```sway
/// DuplicatedSigner: ()
/// ```
///
/// - **Description**: Raised when a duplicated signer is found in the list of allowed signers.
///
/// ### `DuplicatedFeedId`
///
/// ```sway
/// DuplicatedFeedId: ()
/// ```
///
/// - **Description**: Raised when a duplicated feed ID is found.
///
/// ### `DuplicatedValueForSigner`
///
/// ```sway
/// DuplicatedValueForSigner: (b256, u256)
/// ```
///
/// - **Description**: Raised when the payload contains multiple values for the same signer and feed ID.
/// - **Fields**:
///     - `b256`: The signer's address.
///     - `u256`: The feed ID.
///
/// ### `SignerNotRecognized`
///
/// ```sway
/// SignerNotRecognized: (b256, u64)
/// ```
///
/// - **Description**: Raised when a recovered signer address is not one of the allowed signers.
/// - **Fields**:
///     - `b256`: The signer's address.
///     - `u64`: The index at which the signer was encountered.
///
/// ### `InsufficientSignerCount`
///
/// ```sway
/// InsufficientSignerCount: (u64, u64)
/// ```
///
/// - **Description**: Raised when the number of valid signers is less than the threshold.
/// - **Fields**:
///     - `u64`: The current number of signers.
///     - `u64`: The index of the feed being processed.
///
/// ### `TimestampOutOfRange`
///
/// ```sway
/// TimestampOutOfRange: (bool, u64, u64)
/// ```
///
/// - **Description**: Raised when a timestamp is too far in the future or past.
/// - **Fields**:
///     - `bool`: Whether the timestamp is too far in the future (`true`) or in the past (`false`).
///     - `u64`: The provided block timestamp.
///     - `u64`: The recovered timestamp.
///
/// ### `TimestampDifferentThanOthers`
///
/// ```sway
/// TimestampDifferentThanOthers: (u64, u64, u64)
/// ```
///
/// - **Description**: Raised when one timestamp differs from the others provided.
/// - **Fields**:
///     - `u64`: The reference timestamp.
///     - `u64`: The differing timestamp.
///     - `u64`: The index of the data package that's timestamp differs.
pub enum RedStoneError {
    EmptyAllowedSigners: (),
    EmptyFeedIds: (),
    SignerCountThresholdToSmall: (),
    DuplicatedSigner: (),
    DuplicatedFeedId: (),
    DuplicatedValueForSigner: (b256, u256),
    SignerNotRecognized: (b256, u64),
    InsufficientSignerCount: (u64, u64),
    TimestampOutOfRange: (bool, u64, u64),
    TimestampDifferentThanOthers: (u64, u64, u64),
}
