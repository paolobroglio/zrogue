const std = @import("std");

var rng_initialized = false;
var rng: std.Random.DefaultPrng = undefined;

pub fn initRandom() void {
    const seed = @as(u64, @intCast(std.time.milliTimestamp()));
    rng = std.Random.DefaultPrng.init(seed);
    rng_initialized = true;
}

fn getRandom() std.Random {
    if (!rng_initialized) {
        initRandom();
    }
    return rng.random();
}

pub fn chance(percentage: u8) bool {
    if (percentage == 0) return false;
    if (percentage >= 100) return true;
    const random = getRandom();
    const roll = random.intRangeAtMost(u8, 1, 100);
    return roll <= percentage;
}

pub fn chanceF(probability: f32) bool {
    if (probability <= 0.0) return false;
    if (probability >= 1.0) return true;
    const random = getRandom();
    const roll = random.float(f32);
    return roll <= probability;
}

pub const Dice = enum {
    d4,
    d6,
    d8,
    d10,
    d12,
    d20,

    pub fn roll(count: u32, dice: Dice) u32 {
        const random = getRandom();
        const sides: u32 = switch (dice) {
            .d4 => 4,
            .d6 => 6,
            .d8 => 8,
            .d10 => 10,
            .d12 => 12,
            .d20 => 20,
        };
        var total: u32 = 0;
        var i: u32 = 0;
        while (i < count) : (i += 1) {
            total += random.intRangeAtMost(u32, 1, sides);
        }
        return total;
    }
};
