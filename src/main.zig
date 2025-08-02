const std = @import("std");
const game = @import("game.zig");

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            std.log.err("GPA leak detected", .{});
        }
    }
    const allocator = gpa.allocator();

    var game_world = game.Game.init(allocator);
    defer game_world.deinit();

    game_world.run() catch |err| {
        std.log.err("Error running game: {}", .{err});
        return err;
    };
}