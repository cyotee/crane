library;

use std::vec::*;
use ::utils::{from_bytes::*, test_helpers::*, vec::*};

impl Vec<Vec<u256>> {
    pub fn aggregated(self) -> Vec<u256> {
        let mut aggregated = Vec::new();
        let mut i = 0;
        while (i < self.len()) {
            let values = self.get(i).unwrap();
            aggregated.push(values.median().unwrap());
            i += 1;
        }

        aggregated
    }
}

#[test]
fn test_aggregate_results() {
    let mut results = Vec::new();
    let mut aggr = Vec::new();
    let mut prices1 = Vec::new();
    prices1.push(0x222u256);
    aggr.push(0x222u256);

    let mut prices2 = Vec::new();
    prices2.push(0x333u256);
    prices2.push(0x111u256);
    prices2.push(0x222u256);
    aggr.push(0x222u256);

    let mut prices3 = Vec::new();
    prices3.push(0x555u256);
    prices3.push(0x111u256);
    aggr.push(0x333u256);

    results.push(prices1);
    results.push(prices2);
    results.push(prices3);

    assert(results.aggregated() == aggr);
}
