const std = @import("std");
const rl = @import("raylib");
const component = @import("component.zig");

pub const CombatResult = struct {
    damage_dealt: i8,
    attacker_hp_after: i8,
    defender_hp_after: i8,
    attacker_died: bool,
    defender_died: bool,
    was_critical: bool = false,
    was_blocked: bool = false,
};

pub fn simpleSubtraction(attacker: component.CombatComponent, defender: *component.CombatComponent) CombatResult {
    const raw_damage = attacker.power - defender.defense;
    const final_damage = @max(1, raw_damage);

    defender.takeDamage(final_damage);

    return CombatResult{
        .damage_dealt = final_damage,
        .attacker_hp_after = attacker.hp,
        .defender_hp_after = defender.hp,
        .attacker_died = attacker.isDead(),
        .defender_died = defender.isDead(),
    };
}
