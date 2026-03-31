library;

use std::{bytes::*, bytes_conversions::u256::*, math::*};
use ::utils::{from_bytes::FromBytes, from_bytes_convertible::*};

impl Bytes {
    pub fn cut(self, offset: u64) -> Bytes {
        let (head, _) = self.split_at(self.len() - offset);

        head
    }

    pub fn slice_tail_offset(self, tail_size: u64, tail_offset: u64) -> (Bytes, Bytes) {
        let (head, tail) = self.split_at(self.len() - tail_size - tail_offset);
        (head, tail.cut(tail_offset))
    }

    pub fn slice_tail(self, tail_size: u64) -> (Bytes, Bytes) {
        self.slice_tail_offset(tail_size, 0)
    }

    pub fn slice_number_offset(self, tail_size: u64, tail_offset: u64) -> (Bytes, u64) {
        let (head, tail) = self.slice_tail_offset(tail_size, tail_offset);
        (head, u64::from_bytes(tail))
    }

    pub fn slice_number(self, tail_size: u64) -> (Bytes, u64) {
        self.slice_number_offset(tail_size, 0)
    }

    pub fn join(self, other: Bytes) -> Bytes {
        let mut result = self;
        result.append(other);

        result
    }

    pub fn zero_truncated(self) -> Bytes {
        let mut n = self.len() - 1;
        let mut result = self;
        while (n > 0) {
            if (self.get(n).unwrap() == 0) {
                n -= 1;
                let _ = result.pop();
                continue;
            }

            break;
        }

        result
    }
}
