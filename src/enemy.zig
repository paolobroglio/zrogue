const std = @import("std");
const rl = @import("raylib");

pub const Enemy = struct { 
    position: rl.Vector2, 
    max_hp: i8, 
    hp: i8, 
    defense: i8, 
    power: i8,

    pub fn resetHp(self: *Enemy) void {
        self.hp = self.max_hp;
    }
    pub fn setHpClamped(self: *Enemy, hp: i8) void {
        self.hp = @max(0, @min(hp, self.max_hp));
    }

    pub fn warrior(position: rl.Vector2) Enemy {
        return Enemy {
            .position = position,
            .max_hp = 5,
            .hp = 5,
            .defense = 1,
            .power = 1
        };
    }
};

