const std = @import("std");
const debug = std.debug;
const as = @import("assetstore.zig");
const map = @import("map.zig");
const tileset = @import("tileset.zig");
const fov = @import("fov.zig");
const enmy = @import("enemy.zig");
const plr = @import("player.zig");
const rl = @import("raylib");
const combat = @import("combat.zig");

pub const Error = error{ InitializationFailed, DeinitializationFailed, RunFailed, InputHandlingFailed, RenderingFailed, UpdateFailed };

const Turn = enum { Player, Enemy };

pub const Game = struct {
    allocator: std.mem.Allocator,
    // configurations
    window_width: i32,
    window_height: i32,
    vsync: bool,
    highdpi: bool,
    fps: i32,

    is_running: bool,

    asset_store: as.AssetStore,
    game_map: map.Map,
    tileset: tileset.Tileset,
    tileset_texture: rl.Texture2D,

    visited_tiles_points: std.AutoHashMap(fov.Point, void),
    visible_tiles_points: std.AutoHashMap(fov.Point, void),

    current_turn: Turn,
    player: plr.Player,
    enemies: std.ArrayList(enmy.Enemy),

    pub fn init(allocator: std.mem.Allocator) Game {
        return Game{ .allocator = allocator, .window_width = 1280, .window_height = 800, .vsync = true, .highdpi = true, .fps = 60, .is_running = false, .asset_store = as.AssetStore.init(allocator), .game_map = undefined, .tileset = undefined, .tileset_texture = undefined, .visible_tiles_points = std.AutoHashMap(fov.Point, void).init(allocator), .visited_tiles_points = std.AutoHashMap(fov.Point, void).init(allocator), .current_turn = Turn.Player, .player = plr.Player.init(rl.Vector2.zero(), '@'), .enemies = std.ArrayList(enmy.Enemy).init(allocator) };
    }
    pub fn deinit(self: *Game) void {
        rl.closeWindow();
        self.asset_store.deinit();
        self.game_map.destroy();
        self.visited_tiles_points.deinit();
        self.visible_tiles_points.deinit();
        self.enemies.deinit();
    }
    fn setup(self: *Game) Error!void {
        rl.setConfigFlags(.{ .window_highdpi = self.highdpi, .window_resizable = false, .vsync_hint = self.vsync });
        rl.initWindow(self.window_width, self.window_height, "ZRogue");
        rl.setTargetFPS(self.fps);

        self.asset_store.addTexture("tileset", "resources/redjack16x16.png") catch |err| {
            std.log.err("Error adding texture: {}", .{err});
            return Error.InitializationFailed;
        };
        self.game_map = map.Map.generate(self.allocator, 80, 50, &self.enemies) catch |err| {
            std.log.err("Error generating map: {}", .{err});
            return Error.InitializationFailed;
        };
        self.tileset = tileset.Tileset.init("tileset", tileset.GlyphMapType.Cp437, 16.0) catch |err| {
            std.log.err("Error initiliazing tileset: {}", .{err});
            return Error.InitializationFailed;
        };
        self.tileset_texture = self.asset_store.getTexture("tileset") catch |err| {
            std.log.err("Error getting texture for tileset: {}", .{err});
            return Error.InitializationFailed;
        };
        const starting_room = self.game_map.startingRoom() catch |err| {
            std.log.err("Error getting the starting room: {}", .{err});
            return Error.InitializationFailed;
        };
        self.player.position = rl.Vector2{ .x = starting_room.center().x * self.tileset.tile_size, .y = starting_room.center().y * self.tileset.tile_size };
    }
    pub fn run(self: *Game) Error!void {
        self.is_running = true;
        try self.setup();
        while (!rl.windowShouldClose()) {
            try self.update();
            try self.render();
        }
    }
    fn update(self: *Game) Error!void {
        // PLAYER ACTIONS - every action taken by the player is a turn
        const tile_size = self.tileset.tile_size;
        if (self.current_turn == Turn.Player) {
            var target_position = self.player.position;
            if (rl.isKeyPressed(.right)) {
                target_position.x += tile_size;
                self.current_turn = Turn.Enemy;
            }
            if (rl.isKeyPressed(.left)) {
                target_position.x -= tile_size;
                self.current_turn = Turn.Enemy;
            }
            if (rl.isKeyPressed(.up)) {
                target_position.y -= tile_size;
                self.current_turn = Turn.Enemy;
            }
            if (rl.isKeyPressed(.down)) {
                target_position.y += tile_size;
                self.current_turn = Turn.Enemy;
            }
            const enemy_hit = self.checkEnemyHitByPlayer(target_position);
            if (enemy_hit != null) {
                const enemy_idx: usize = enemy_hit.?;
                if (self.enemies.items[enemy_idx].combat_component.isDead()) {
                    _ = self.enemies.orderedRemove(enemy_idx);
                }
            } else {
                // Check if the target position is a WALKABLE TILE
                var target_player_point: fov.Point = self.worldPositionToTilePosition(target_position);
                const target_tile = self.game_map.getTile(target_player_point.x, target_player_point.y);
                if (target_tile != null and target_tile.?.walkable) {
                    self.player.position = target_position;
                    // Compute FOV - we could avoid to compute the FOV if the player doesn't move!!! Also visited tiles would be the same as the previous iteration
                    self.visible_tiles_points.clearAndFree();
                    self.visible_tiles_points = fov.computeFOV(self.allocator, target_player_point, 5, self.game_map) catch |err| {
                        std.log.err("Error computing FOV: {}", .{err});
                        return Error.RunFailed;
                    };
                    // Compute Visited Tiles
                    var it = self.visible_tiles_points.iterator();
                    while (it.next()) |entry| {
                        self.visited_tiles_points.put(entry.key_ptr.*, {}) catch |err| {
                            std.log.err("Error adding a visited tile point: {}", .{err});
                            return Error.RunFailed;
                        };
                    }
                } else {
                    target_player_point = self.worldPositionToTilePosition(self.player.position);
                }
            }
        } else {
            self.executeEnemyTurn();
            self.current_turn = Turn.Player;
        }
        self.updateAfterCombat();
    }
    fn render(self: *Game) Error!void {
        const player_tile_coordinates = self.tileset.getTileCoordinates(self.player.glyph) catch |err| {
            std.log.err("Error getting texture coordinates for player: {}", .{err});
            return Error.RenderingFailed;
        };
        const wall_tile_coordinates = self.tileset.getTileCoordinates('#') catch |err| {
            std.log.err("Error getting texture coordinates for wall: {}", .{err});
            return Error.RenderingFailed;
        };
        const floor_tile_coordinates = self.tileset.getTileCoordinates('`') catch |err| {
            std.log.err("Error getting texture coordinates for floor: {}", .{err});
            return Error.RenderingFailed;
        };

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        // DRAW PLAYER
        const player_dest_rect: rl.Rectangle = rl.Rectangle{ .x = self.player.position.x, .y = self.player.position.y, .height = self.tileset.tile_size, .width = self.tileset.tile_size };
        rl.drawTexturePro(self.tileset_texture, player_tile_coordinates.rect, player_dest_rect, .{ .x = 0, .y = 0 }, 0.0, rl.Color.ray_white);

        // DRAW ENEMIES
        for (self.enemies.items) |enemy| {
            const enemy_tile_coordinates = self.tileset.getTileCoordinates(enemy.glyph) catch |err| {
                std.log.err("Error getting texture coordinates for enemy: {}", .{err});
                return Error.RenderingFailed;
            };
            const tile_position = self.worldPositionToTilePosition(enemy.position);
            const enemy_dest_rect = rl.Rectangle{ .x = enemy.position.x, .y = enemy.position.y, .height = self.tileset.tile_size, .width = self.tileset.tile_size };
            if (self.visible_tiles_points.contains(tile_position)) {
                rl.drawTexturePro(self.tileset_texture, enemy_tile_coordinates.rect, enemy_dest_rect, .{ .x = 0, .y = 0 }, 0.0, rl.Color.red);
            }
        }

        // DRAW MAP
        for (self.game_map.tiles.items, 0..) |tile, index| {
            const map_width: usize = @intCast(self.game_map.width);
            const x = @as(f32, @floatFromInt(index % map_width)) * self.tileset.tile_size;
            const y = @as(f32, @floatFromInt(index / map_width)) * self.tileset.tile_size;

            const tile_dest_rect = rl.Rectangle{ .x = x, .y = y, .height = self.tileset.tile_size, .width = self.tileset.tile_size };
            const tile_src_rect = if (tile.walkable)
                floor_tile_coordinates.rect
            else
                wall_tile_coordinates.rect;

            const point = fov.Point{ .x = tile.x, .y = tile.y };
            if (self.visible_tiles_points.contains(point)) {
                const bg_color = tile.light.bgColor;
                // background
                rl.drawTexturePro(self.tileset_texture, tile_src_rect, tile_dest_rect, .{ .x = 0, .y = 0 }, 0.0, bg_color);
            } else {
                if (self.visited_tiles_points.contains(point)) {
                    const bg_color = tile.dark.bgColor;
                    rl.drawTexturePro(self.tileset_texture, tile_src_rect, tile_dest_rect, .{ .x = 0, .y = 0 }, 0.0, bg_color);
                }
            }
        }
    }
    fn worldPositionToTilePosition(self: *Game, pos: rl.Vector2) fov.Point {
        return fov.Point{
            .x = @intFromFloat(pos.x / self.tileset.tile_size),
            .y = @intFromFloat(pos.y / self.tileset.tile_size),
        };
    }
    fn checkEnemyHitByPlayer(self: *Game, player_target_pos: rl.Vector2) ?usize {
        for (self.enemies.items, 0..) |*enemy, i| {
            if (enemy.position.x == player_target_pos.x and enemy.position.y == player_target_pos.y) {
                const combat_result = combat.simpleSubtraction(self.player.combat_component, &enemy.combat_component);
                std.log.info("Player hit enemy: {}!", .{combat_result});
                return i;
            }
        }
        return null;
    }
    fn executeEnemyTurn(self: *Game) void {
        const threshold_distance: f32 = 5.0;
        for (self.enemies.items) |enemy| {
            const dx: f32 = self.player.position.x - enemy.position.x;
            const dy: f32 = self.player.position.y - enemy.position.y;
            const chebyshev_distance = @divFloor(@max(@abs(dx), @abs(dy)), self.tileset.tile_size);
            //debug.print("Enemy at ({},{}) distance from player {}\n", .{ enemy.position.x, enemy.position.y, chebyshev_distance });
            if (chebyshev_distance == 1.0) {
                //debug.print("Enemy at ({},{}) attacks the player\n", .{ enemy.position.x, enemy.position.y });
                const combat_result = combat.simpleSubtraction(enemy.combat_component, &self.player.combat_component);
                std.log.info("Enemy hit player: {}!", .{combat_result});
            } else if (chebyshev_distance >= threshold_distance) {
                //debug.print("Enemy at ({},{}) doesn't move\n", .{ enemy.position.x, enemy.position.y });
            } else {
                //debug.print("Enemy at ({},{}) moves toward the player\n", .{ enemy.position.x, enemy.position.y });
            }
        }
    }
    fn updateAfterCombat(self: *Game) void {
        if (self.player.combat_component.isDead()) {
            std.log.info("GAME OVER!", .{});
        }
    }
};
