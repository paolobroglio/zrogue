const std = @import("std");
const rl = @import("raylib");
const tset = @import("tileset.zig");
const component = @import("component.zig");

pub const Player = struct {
    // TransformComponent
    position: rl.Vector2,
    // RenderableComponent
    glyph: u32,
    // CombatComponent
    combat_component: component.CombatComponent,

    pub fn init(position: rl.Vector2, glyph: u32) Player {
        return Player{
            .position = position,
            .glyph = glyph,
            .combat_component = component.CombatComponent{ .max_hp = 10, .hp = 10, .defense = 5, .power = 2 },
        };
    }
};
