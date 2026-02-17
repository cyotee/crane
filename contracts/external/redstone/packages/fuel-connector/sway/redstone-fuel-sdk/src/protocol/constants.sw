library;

pub const REDSTONE_MARKER = [0x00, 0x00, 0x02, 0xed, 0x57, 0x01, 0x1e, 0x00, 0x00];
pub const REDSTONE_MARKER_BS = 9;
pub const UNSIGNED_METADATA_BYTE_SIZE_BS = 3;
pub const DATA_PACKAGES_COUNT_BS = 2;
pub const SIGNATURE_BS = 65;
pub const DATA_POINTS_COUNT_BS = 3;
pub const DATA_POINT_VALUE_BYTE_SIZE_BS = 4;
pub const TIMESTAMP_BS = 6;
pub const DATA_FEED_ID_BS = 32;

// 13107200 + byte_index
pub const WRONG_REDSTONE_MARKER = 0xc80000;

pub const WRONG_PAYLOAD = 0xff0000;
