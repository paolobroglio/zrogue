const std = @import("std");
const rl = @import("raylib");

pub const HUDMessageType = enum {
    Info, // General information (white)
    Combat, // Combat actions (yellow)
    Damage, // Taking damage (red)
    Death, // Death messages (dark red)
    Success, // Positive actions (green)
    Warning, // Warnings (orange)

    pub fn getColor(self: HUDMessageType) rl.Color {
        return switch (self) {
            .Info => rl.Color.white,
            .Combat => rl.Color.yellow,
            .Damage => rl.Color{ .r = 255, .g = 100, .b = 100, .a = 255 }, // Light red
            .Death => rl.Color{ .r = 150, .g = 0, .b = 0, .a = 255 }, // Dark red
            .Success => rl.Color.lime,
            .Warning => rl.Color.orange,
        };
    }
};

pub const HUDMessage = struct {
    text: []const u8,
    message_type: HUDMessageType,
};

pub const HUD = struct {
    allocator: std.mem.Allocator,
    arena: std.heap.ArenaAllocator,
    message_log: std.ArrayList(HUDMessage),
    max_messages: usize,
    hud_height: f32,
    font: rl.Font,

    pub fn init(allocator: std.mem.Allocator) !HUD {
        const arena = std.heap.ArenaAllocator.init(allocator);
        const font = try rl.getFontDefault();
        return HUD{ .allocator = allocator, .arena = arena, .message_log = std.ArrayList(HUDMessage).init(allocator), .max_messages = 8, .hud_height = 150.0, .font = font };
    }

    pub fn deinit(self: *HUD) void {
        self.message_log.deinit();
        self.arena.deinit();
        // TODO: unload font
    }

    pub fn addMessage(self: *HUD, comptime fmt: []const u8, args: anytype, message_type: HUDMessageType) !void {
        if (self.message_log.items.len >= self.max_messages) {
            _ = self.message_log.orderedRemove(0);
        }
        const owned_message = try std.fmt.allocPrintZ(self.arena.allocator(), fmt, args);
        try self.message_log.append(HUDMessage{ .text = owned_message, .message_type = message_type });
    }

    pub fn render(self: *HUD, window_width: i32, window_height: i32, player_health: i32, player_max_health: i32) void {
        renderHealthBar(window_width, player_health, player_max_health);
        self.renderMessageLog(window_width, window_height);
    }

    fn renderHealthBar(window_width: i32, health: i32, max_health: i32) void {
        const bar_width: f32 = 200.0;
        const bar_height: f32 = 20.0;
        const bar_x: f32 = @as(f32, @floatFromInt(window_width)) - bar_width - 10.0;
        const bar_y: f32 = 10.0;

        // Background (empty health)
        rl.drawRectangle(@intFromFloat(bar_x), @intFromFloat(bar_y), @intFromFloat(bar_width), @intFromFloat(bar_height), rl.Color.dark_gray);

        // Health bar fill
        const health_percentage = @as(f32, @floatFromInt(health)) / @as(f32, @floatFromInt(max_health));
        const fill_width = bar_width * health_percentage;

        const bar_color = if (health_percentage > 0.6)
            rl.Color.green
        else if (health_percentage > 0.3)
            rl.Color.yellow
        else
            rl.Color.red;

        rl.drawRectangle(@intFromFloat(bar_x), @intFromFloat(bar_y), @intFromFloat(fill_width), @intFromFloat(bar_height), bar_color);

        // Border
        rl.drawRectangleLines(@intFromFloat(bar_x), @intFromFloat(bar_y), @intFromFloat(bar_width), @intFromFloat(bar_height), rl.Color.white);

        // Health text
        var health_buffer: [32]u8 = undefined;
        const health_text = std.fmt.bufPrintZ(&health_buffer, "{d}/{d}", .{ health, max_health }) catch "?/?";

        const text_width = rl.measureText(@ptrCast(health_text), 16);
        const text_x = bar_x + (bar_width / 2.0) - (@as(f32, @floatFromInt(text_width)) / 2.0);
        rl.drawText(@ptrCast(health_text), @intFromFloat(text_x), @intFromFloat(bar_y + 2), 16, rl.Color.white);
    }

    fn renderMessageLog(self: *HUD, window_width: i32, window_height: i32) void {
        const log_y = @as(f32, @floatFromInt(window_height)) - self.hud_height;

        // Background for message log
        rl.drawRectangle(0, @intFromFloat(log_y), window_width, @intFromFloat(self.hud_height), rl.Color{ .r = 20, .g = 20, .b = 20, .a = 200 });

        // Border line
        rl.drawLine(0, @intFromFloat(log_y), window_width, @intFromFloat(log_y), rl.Color.gray);

        const font_size: f32 = 13.0;
        const line_spacing: f32 = 18.0;
        var y_offset: f32 = log_y + 10.0;

        for (self.message_log.items) |message| {
            const color = message.message_type.getColor();
            rl.drawTextEx(self.font, @ptrCast(message.text), rl.Vector2{ .x = 10.0, .y = y_offset }, font_size, 1.0, color);
            y_offset += line_spacing;
        }
    }
};
