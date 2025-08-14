const std = @import("std");
const rl = @import("raylib");
const component = @import("component.zig");

pub const ItemType = enum { Consumable, Weapon, Armor };

pub const ConsumableData = struct { healing_value: i8 };
pub const WeaponData = struct { att_bonus: i8 };
pub const ArmorData = struct { def_bonus: i8 };

pub const ItemData = union(ItemType) { Consumable: ConsumableData, Weapon: WeaponData, Armor: ArmorData };

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
        return Item{ .position = position, .glyph = 'p', .name = "Health Potion", .description = "Restores 5 HP", .data = ItemData{ .Consumable = ConsumableData{ .healing_value = 5 } }, .charges = 1 };
    }

    pub fn sword(position: rl.Vector2) Item {
        return Item{ .position = position, .glyph = '/', .name = "Sword", .description = "Adds 1 to ATT", .data = ItemData{ .Weapon = WeaponData{ .att_bonus = 1 } }, .charges = 10 };
    }

    pub fn leatherHelmet(position: rl.Vector2) Item {
        return Item{ .position = position, .glyph = '♫', .name = "Leather Helmet", .description = "Adds 1 to DEF", .data = ItemData{ .Armor = ArmorData{ .def_bonus = 1 } }, .charges = 10 };
    }

    pub fn getConsumableData(self: *const Item) ?ConsumableData {
        return switch (self.data) {
            .Consumable => |data| data,
            else => null,
        };
    }

    pub fn isConsumable(self: *const Item) bool {
        return self.getItemType() == ItemType.Consumable;
    }

    pub fn isEquippable(self: *const Item) bool {
        return switch (self.getItemType()) {
            .Armor => true,
            .Weapon => true,
            else => false,
        };
    }

    pub fn isWeapon(self: *const Item) bool {
        return self.getItemType() == ItemType.Weapon;
    }

    pub fn isArmor(self: *const Item) bool {
        return self.getItemType() == ItemType.Armor;
    }

    pub fn getWeaponData(self: *const Item) ?WeaponData {
        return switch (self.data) {
            .Weapon => |data| data,
            else => null,
        };
    }

    pub fn getArmorData(self: *const Item) ?ArmorData {
        return switch (self.data) {
            .Armor => |data| data,
            else => null,
        };
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
