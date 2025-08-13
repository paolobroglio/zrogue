const std = @import("std");

pub const CombatComponent = struct {
    max_hp: i8,
    hp: i8,
    defense: i8,
    power: i8,

    pub fn resetHp(self: *CombatComponent) void {
        self.hp = self.max_hp;
    }

    pub fn setHpClamped(self: *CombatComponent, hp: i8) void {
        self.hp = @max(0, @min(hp, self.max_hp));
    }

    pub fn addHpClamped(self: *CombatComponent, hp_to_add: i8) void {
        self.hp = @max(0, @min(self.hp+hp_to_add, self.max_hp));
    }

    pub fn isDead(self: *const CombatComponent) bool {
        return self.hp <= 0;
    }

    pub fn takeDamage(self: *CombatComponent, damage: i8) void {
        self.hp = @max(0, self.hp - damage);
    }
};
