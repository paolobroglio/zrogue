const std = @import("std");
const rl = @import("raylib");
const tset = @import("tileset.zig");
const component = @import("component.zig");
const inventory = @import("inventory.zig");
const items = @import("item.zig");

pub const Player = struct {
    // TransformComponent
    position: rl.Vector2,
    // RenderableComponent
    glyph: u32,
    // CombatComponent
    combat_component: component.CombatComponent,

    inventory: inventory.Inventory,

    pub fn init(allocator: std.mem.Allocator, position: rl.Vector2, glyph: u32) Player {
        return Player{ .position = position, .glyph = glyph, .combat_component = component.CombatComponent{ .max_hp = 10, .hp = 10, .defense = 5, .power = 2 }, .inventory = inventory.Inventory.init(allocator) };
    }

    pub fn addItemToInventory(self: *Player, item: items.Item) !void {
        try self.inventory.equip(item);
    }

    pub fn combatComponentWithBonuses(self: *const Player) component.CombatComponent {
        var power_bonus: i8 = 0;
        var defense_bonus: i8 = 0;
        for (self.inventory.backpack.items) |i| {
            if (i.isWeapon()) {
                if (i.getWeaponData()) |weapon_data| {
                    power_bonus += weapon_data.att_bonus;
                }
            } else if (i.isArmor()) {
                if (i.getArmorData()) |armor_data| {
                    defense_bonus += armor_data.def_bonus;
                }
            }
        }

        return component.CombatComponent{ .power = self.combat_component.power + power_bonus, .hp = self.combat_component.hp, .defense = self.combat_component.defense + defense_bonus, .max_hp = self.combat_component.max_hp };
    }
};
