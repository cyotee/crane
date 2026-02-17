library;

use std::vec::*;
use ::utils::{numbers::*, test_helpers::With};

impl<T> Vec<T>
where
    T: Eq,
{
    pub fn index_of(self, value: T) -> Option<u64> {
        let mut i = 0;
        while (i < self.len()) {
            if value == self.get(i).unwrap() {
                return Some(i);
            }
            i += 1;
        }

        None
    }

    pub fn find_duplicate(self) -> Option<T> {
        let mut i = 0;

        while (i < self.len()) {
            let mut j = i + 1;
            while (j < self.len()) {
                if (self.get(i) == self.get(j)) {
                    return Some(self.get(i).unwrap());
                }

                j += 1;
            }

            i += 1;
        }

        None
    }

    fn sort(ref mut self)
    where
        T: Ord,
    {
        let mut n = self.len();
        while (n > 1) {
            let mut i = 0;
            while (i < n - 1) {
                if self.get(i).unwrap() > self.get(i + 1).unwrap() {
                    self.swap(i, i + 1);
                }
                i += 1;
            }
            n -= 1;
        }
    }
}

impl Vec<u256> {
    pub fn median(self) -> Option<u256> {
        match self.len() {
            0 => None,
            1 => Some(self.get(0).unwrap()),
            2 => Some(self.get(0).unwrap().avg_with(self.get(1).unwrap())),
            _ => {
                let mut values = self;

                values.sort();

                let mid = values.len() / 2;
                if (values.len() % 2 == 1) {
                    Some(values.get(mid).unwrap())
                } else {
                    Some(values.get(mid).unwrap().avg_with(values.get(mid - 1).unwrap()))
                }
            }
        }
    }
}

#[test]
fn test_median_single_value() {
    let data = Vec::<u256>::new().with(0x333u256);

    assert(data.median().unwrap() == 0x333u256);
}

#[test]
fn test_median_two_values() {
    let data = Vec::<u256>::new().with(0x333u256).with(0x222u256);

    assert(data.median().unwrap() == 0x2aau256);
}

#[test]
fn test_median_three_values() {
    let data = Vec::<u256>::new().with(0x444u256).with(0x222u256).with(0x333u256);

    assert(data.median().unwrap() == 0x333u256);
}

#[test]
fn test_median_four_values() {
    let data = Vec::<u256>::new().with(0x444u256).with(0x222u256).with(0x111u256).with(0x555u256);

    assert(data.median().unwrap() == 0x333u256);
}

#[test]
fn test_median_five_values() {
    let data = Vec::<u256>::new().with(0x444u256).with(0x222u256).with(0x111u256).with(0x333u256).with(0x555u256);

    assert(data.median().unwrap() == 0x333u256);
}

#[test]
fn test_median_three_other_values() {
    let data = Vec::<u256>::new().with(0x222u256).with(0x222u256).with(0x333u256);

    assert(data.median().unwrap() == 0x222u256);
}

#[test]
fn test_median_zero_values() {
    assert(Vec::<u256>::new().median() == None);
}

#[test]
fn test_find_duplicate() {
    let data = Vec::<u256>::new().with(0x444u256).with(0x222u256).with(0x333u256);

    assert(data.find_duplicate() == None);
}

#[test]
fn test_find_duplicate_one_element() {
    let data = Vec::<u256>::new().with(0x444u256).with(0x222u256).with(0x333u256);

    assert(data.find_duplicate() == None);
}

#[test]
fn test_find_duplicate_duplcated() {
    let data = Vec::<u256>::new().with(0x444u256).with(0x222u256).with(0x444u256);

    assert(data.find_duplicate().unwrap() == 0x444u256);
}

#[test]
fn test_find_duplicate_duplcated_nearby() {
    let data = Vec::<u256>::new().with(0x222u256).with(0x444u256).with(0x444u256);

    assert(data.find_duplicate().unwrap() == 0x444u256);
}

#[test]
fn test_find_duplicate_option_as_dup() {
    let data = Vec::<Option<u256>>::new().with(Some(0x444u256)).with(Some(0x444u256)).with(None);

    assert(data.find_duplicate().unwrap() == Some(0x444u256));
}
