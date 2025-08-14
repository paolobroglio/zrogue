const std = @import("std");
const rl = @import("raylib");
const component = @import("component.zig");

pub const Enemy = struct {
    // Transform Component
    position: rl.Vector2,
    // RenderableComponent
    glyph: u32,
    // Combat Component
    combat_component: component.CombatComponent,
    name: []const u8,

    pub fn warrior(position: rl.Vector2) Enemy {
        return Enemy{ .position = position, .glyph = '☺', .combat_component = component.CombatComponent{ .max_hp = 5, .hp = 5, .defense = 1, .power = 1 }, .name = "Warrior" };
    }
};
