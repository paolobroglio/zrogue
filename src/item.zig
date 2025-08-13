const std = @import("std");
const rl = @import("raylib");
const component = @import("component.zig");

pub const ItemType = enum {
  Consumable
};

pub const ConsumableData = struct {
  healing_value: i32,
  charges: i8
};

pub const ItemData = union(ItemType) {
  Consumable: ConsumableData
};

pub const Item = struct {
    // Transform Component
    position: rl.Vector2,
    // RenderableComponent
    glyph: u32,
    name: []const u8,
    description: []const u8,
    data: ItemData,

    pub fn healthPotion(position: rl.Vector2) Item {
        return Item{
            .position = position,
            .glyph = 'p',
            .name = "Health Potion",
            .description = "Restores 5 HP",
            .data = ItemData {
              .Consumable = ConsumableData {
                .healing_value = 5,
                .charges = 1
              }
            }
        };
    }
};