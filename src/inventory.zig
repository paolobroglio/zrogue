const std = @import("std");
const item = @import("item.zig");

pub const Inventory = struct {
    backpack: std.ArrayList(item.Item),
    //equipment: std.StringHashMap(item.Item),

    pub fn init(allocator: std.mem.Allocator) Inventory {
        return Inventory{
            .backpack = std.ArrayList(item.Item).init(allocator),
            //.equipment = equipment
        };
    }

    pub fn equip(self: *Inventory, item_to_equip: item.Item) !void {
        try self.backpack.append(item_to_equip);
    }
};
