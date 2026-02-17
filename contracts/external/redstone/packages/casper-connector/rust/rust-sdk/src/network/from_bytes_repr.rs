use crate::network::specific::VALUE_SIZE;

pub trait FromBytesRepr<T> {
    fn from_bytes_repr(bytes: T) -> Self;
}

pub trait Sanitized {
    fn sanitized(self) -> Self;
}

impl Sanitized for Vec<u8> {
    fn sanitized(self) -> Self {
        if self.len() <= VALUE_SIZE {
            return self;
        }

        let index = self.len().max(VALUE_SIZE) - VALUE_SIZE;
        let remainder = &self[0..index];

        if remainder != vec![0; index] {
            panic!("Number to big: {:?} digits", self.len())
        }

        self[index..].into()
    }
}

#[cfg(test)]
mod tests {
    use crate::network::{
        from_bytes_repr::FromBytesRepr,
        specific::{U256, VALUE_SIZE},
    };

    #[cfg(target_arch = "wasm32")]
    use wasm_bindgen_test::wasm_bindgen_test as test;

    #[cfg(feature = "network_radix")]
    use crate::network::radix::u256_ext::U256Ext;

    #[test]
    fn test_from_bytes_repr_single() {
        let vec = vec![1];
        let result = U256::from_bytes_repr(vec);

        assert_eq!(result, U256::from(1u32));
    }

    #[test]
    fn test_from_bytes_repr_double() {
        let vec = vec![1, 2];
        let result = U256::from_bytes_repr(vec);

        assert_eq!(result, U256::from(258u32));
    }

    #[test]
    fn test_from_bytes_repr_simple() {
        let vec = vec![1, 2, 3];
        let result = U256::from_bytes_repr(vec);

        assert_eq!(result, U256::from(66051u32));
    }

    #[test]
    fn test_from_bytes_repr_bigger() {
        let vec = vec![101, 202, 255];
        let result = U256::from_bytes_repr(vec);

        assert_eq!(result, U256::from(6671103u32));
    }

    #[test]
    fn test_from_bytes_repr_empty() {
        let result = U256::from_bytes_repr(Vec::new());

        assert_eq!(result, U256::from(0u8));
    }

    #[test]
    fn test_from_bytes_repr_trailing_zeroes() {
        let vec = vec![1, 2, 3, 0];
        let result = U256::from_bytes_repr(vec);

        assert_eq!(result, U256::from(16909056u32));
    }

    #[test]
    fn test_from_bytes_repr_leading_zeroes() {
        let vec = vec![0, 1, 2, 3];
        let result = U256::from_bytes_repr(vec);

        assert_eq!(result, U256::from(66051u32));
    }

    #[allow(clippy::legacy_numeric_constants)]
    #[test]
    fn test_from_bytes_repr_max() {
        let vec = vec![255; VALUE_SIZE];
        let result = U256::from_bytes_repr(vec);

        assert_eq!(result, U256::max_value());
    }

    #[test]
    fn test_from_bytes_repr_min() {
        let vec = vec![0; VALUE_SIZE];
        let result = U256::from_bytes_repr(vec);

        assert_eq!(result, U256::from(0u8));
    }

    #[should_panic(expected = "Number to big")]
    #[test]
    fn test_from_bytes_repr_too_long() {
        let x = VALUE_SIZE as u8 + 1;
        let vec = (1..=x).collect();

        U256::from_bytes_repr(vec);
    }

    #[allow(clippy::legacy_numeric_constants)]
    #[test]
    fn test_from_bytes_repr_too_long_but_zeroes() {
        let mut vec = vec![255; VALUE_SIZE + 1];
        vec[0] = 0;
        let result = U256::from_bytes_repr(vec);

        assert_eq!(result, U256::max_value());
    }
}
