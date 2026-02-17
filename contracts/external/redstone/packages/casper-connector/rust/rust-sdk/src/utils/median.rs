use crate::network::{assert::Assert, error::Error::ArrayIsEmpty, specific::U256};
use std::ops::{Add, Rem, Shr};

pub(crate) trait Median {
    type Item;

    fn median(self) -> Self::Item;
}

trait Avg {
    fn avg(self, other: Self) -> Self;
}

trait Averageable:
    Add<Output = Self> + Shr<Output = Self> + From<u8> + Rem<Output = Self> + Copy
{
}

impl Averageable for i32 {}

#[cfg(feature = "network_radix")]
impl Avg for U256 {
    fn avg(self, other: Self) -> Self {
        let one = 1u32;
        let two = U256::from(2u8);

        self.shr(one) + other.shr(one) + (self % two + other % two).shr(one)
    }
}

#[cfg(not(feature = "network_radix"))]
impl Averageable for U256 {}

impl<T> Avg for T
where
    T: Averageable,
{
    fn avg(self, other: Self) -> Self {
        let one = T::from(1);
        let two = T::from(2);

        self.shr(one) + other.shr(one) + (self % two + other % two).shr(one)
    }
}

impl<T> Median for Vec<T>
where
    T: Copy + Ord + Avg,
{
    type Item = T;

    fn median(self) -> Self::Item {
        let len = self.len();

        match len.assert_or_revert(|x| *x > 0, |_| ArrayIsEmpty) {
            1 => self[0],
            2 => self[0].avg(self[1]),
            3 => maybe_pick_median(self[0], self[1], self[2]).unwrap_or_else(|| {
                maybe_pick_median(self[1], self[0], self[2])
                    .unwrap_or_else(|| maybe_pick_median(self[1], self[2], self[0]).unwrap())
            }),
            _ => {
                let mut values = self;
                values.sort();

                let mid = len / 2;

                if len % 2 == 0 {
                    values[mid - 1].avg(values[mid])
                } else {
                    values[mid]
                }
            }
        }
    }
}

#[inline]
fn maybe_pick_median<T>(a: T, b: T, c: T) -> Option<T>
where
    T: PartialOrd,
{
    if (b >= a && b <= c) || (b >= c && b <= a) {
        Some(b)
    } else {
        None
    }
}

#[cfg(test)]
mod tests {
    use super::{Avg, Median};
    use crate::network::specific::U256;
    use itertools::Itertools;
    use std::fmt::Debug;

    #[cfg(target_arch = "wasm32")]
    use wasm_bindgen_test::wasm_bindgen_test as test;

    #[cfg(feature = "network_radix")]
    use crate::network::radix::u256_ext::U256Ext;

    #[allow(clippy::legacy_numeric_constants)]
    #[test]
    fn test_avg() {
        let u256 = U256::max_value(); // 115792089237316195423570985008687907853269984665640564039457584007913129639935
        let u256_max_sub_1 = u256 - U256::from(1u32);
        let u256max_div_2 = u256 / U256::from(2u32);

        assert_eq!(u256.avg(U256::from(0u8)), u256max_div_2);
        assert_eq!(u256.avg(U256::from(1u8)), u256max_div_2 + U256::from(1u8));
        assert_eq!(u256.avg(u256_max_sub_1), u256_max_sub_1);
        assert_eq!(u256.avg(u256), u256);

        assert_eq!((u256_max_sub_1).avg(U256::from(0u8)), u256max_div_2);
        assert_eq!((u256_max_sub_1).avg(U256::from(1u8)), u256max_div_2);
        assert_eq!((u256_max_sub_1).avg(u256_max_sub_1), u256_max_sub_1);
        assert_eq!((u256_max_sub_1).avg(u256), u256_max_sub_1);
    }

    #[test]
    #[should_panic(expected = "Array is empty")]
    fn test_median_empty_vector() {
        let vec: Vec<i32> = vec![];

        vec.median();
    }

    #[test]
    fn test_median_single_element() {
        assert_eq!(vec![1].median(), 1);
    }

    #[test]
    fn test_median_two_elements() {
        test_all_permutations(vec![1, 3], 2);
        test_all_permutations(vec![1, 2], 1);
        test_all_permutations(vec![1, 1], 1);
    }

    #[test]
    fn test_median_three_elements() {
        test_all_permutations(vec![1, 2, 3], 2);
        test_all_permutations(vec![1, 1, 2], 1);
        test_all_permutations(vec![1, 2, 2], 2);
        test_all_permutations(vec![1, 1, 1], 1);
    }

    #[test]
    fn test_median_even_number_of_elements() {
        test_all_permutations(vec![1, 2, 3, 4], 2);
        test_all_permutations(vec![1, 2, 4, 4], 3);
        test_all_permutations(vec![1, 1, 3, 3], 2);
        test_all_permutations(vec![1, 1, 3, 4], 2);
        test_all_permutations(vec![1, 1, 1, 3], 1);
        test_all_permutations(vec![1, 3, 3, 3], 3);
        test_all_permutations(vec![1, 1, 1, 1], 1);
        test_all_permutations(vec![1, 2, 3, 4, 5, 6], 3);
    }

    #[test]
    fn test_median_odd_number_of_elements() {
        test_all_permutations(vec![1, 2, 3, 4, 5], 3);
        test_all_permutations(vec![1, 1, 3, 4, 5], 3);
        test_all_permutations(vec![1, 1, 1, 4, 5], 1);
        test_all_permutations(vec![1, 1, 1, 3, 3], 1);
        test_all_permutations(vec![1, 1, 3, 3, 5], 3);

        test_all_permutations(vec![1, 2, 3, 5, 5], 3);
        test_all_permutations(vec![1, 2, 5, 5, 5], 5);
        test_all_permutations(vec![1, 1, 3, 3, 3], 3);
        test_all_permutations(vec![1, 3, 3, 5, 5], 3);

        test_all_permutations(vec![1, 2, 2, 2, 2], 2);
        test_all_permutations(vec![1, 1, 1, 1, 2], 1);
        test_all_permutations(vec![1, 1, 1, 1, 1], 1);

        test_all_permutations(vec![1, 2, 3, 4, 5, 6, 7], 4);
    }

    fn test_all_permutations<T: Copy + Ord + Avg + Debug>(numbers: Vec<T>, expected_value: T) {
        let perms: Vec<Vec<_>> = numbers.iter().permutations(numbers.len()).collect();

        for perm in perms {
            let p: Vec<_> = perm.iter().map(|&&v| v).collect();

            assert_eq!(p.median(), expected_value);
        }
    }
}
