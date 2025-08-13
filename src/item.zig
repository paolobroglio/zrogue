const std = @import("std");
const rl = @import("raylib");
const component = @import("component.zig");

pub const ItemType = enum {
  Consumable
};

pub const ConsumableData = struct {
  healing_value: i8
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
    charges: u8,

    pub fn healthPotion(position: rl.Vector2) Item {
        return Item{
            .position = position,
            .glyph = 'p',
            .name = "Health Potion",
            .description = "Restores 5 HP",
            .data = ItemData {
              .Consumable = ConsumableData {
                .healing_value = 5
              }
            },
            .charges = 1
        };
    }

    pub fn getConsumableData(self: *const Item) ?ConsumableData {
        return switch (self.data) {
            .Consumable => |data| data
        };
    }

    pub fn isConsumable(self: *const Item) bool {
        return self.getItemType() == ItemType.Consumable;
    }

    fn getItemType(self: *const Item) ItemType {
        return @as(ItemType, self.data);
    }
};

// Using weighted choice for item drops
// fn generateRandomItem(position: rl.Vector2) ?Item {
//     const item_types = [_][]const u8{ "health_potion", "sword", "armor", "nothing" };
//     const drop_weights = [_]u32{ 40, 20, 15, 25 }; // 40%, 20%, 15%, 25%
    
//     if (probability.weightedChoice([]const u8, &item_types, &drop_weights)) |item_type| {
//         if (std.mem.eql(u8, item_type, "health_potion")) {
//             return Item.healthPotion(position);
//         } else if (std.mem.eql(u8, item_type, "sword")) {
//             return Item.sword(position);
//         } else if (std.mem.eql(u8, item_type, "armor")) {
//             return Item.leatherArmor(position);
//         }
//     }
//     return null; // No item dropped
// }