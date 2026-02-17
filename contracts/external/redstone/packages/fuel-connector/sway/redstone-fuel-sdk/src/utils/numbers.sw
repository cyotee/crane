library;

impl u256 {
    pub fn avg_with(self, other: Self) -> Self {
        self.rsh(1) + other.rsh(1) + (self % 2 + other % 2) / 2
    }
}

#[test]
fn test_avg_with() {
    assert(0x444u256.avg_with(0x222u256) == 0x333u256);
    assert(0x444u256.avg_with(0x444u256) == 0x444u256);
    assert(0x444u256.avg_with(0x0u256) == 0x222u256);
    assert(0x333u256.avg_with(0x222u256) == 0x2aau256);
    assert(0x333u256.avg_with(0x333u256) == 0x333u256);
    assert(0x0u256.avg_with(0x0u256) == 0x0u256);
    assert(u256::max().avg_with(u256::max()) == u256::max());
}
