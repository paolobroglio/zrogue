const std = @import("std");
const debug = std.debug;
const as = @import("assetstore.zig");
const map = @import("map.zig");
const tileset = @import("tileset.zig");
const fov = @import("fov.zig");
const enmy = @import("enemy.zig");
const plr = @import("player.zig");
const item = @import("item.zig");
const rl = @import("raylib");
const combat = @import("combat.zig");
const ui = @import("ui.zig");
const hud = @import("hud.zig");
const probability = @import("probability.zig");

pub const Error = error{ InitializationFailed, DeinitializationFailed, RunFailed, InputHandlingFailed, RenderingFailed, UpdateFailed };

const Turn = enum { Player, Enemy };
const GameState = enum { MainMenu, Playing, PauseMenu, GameOver };

pub const Game = struct {
    allocator: std.mem.Allocator,
    // configurations
    window_width: i32,
    window_height: i32,
    vsync: bool,
    highdpi: bool,
    fps: i32,

    is_running: bool,
    game_state: GameState,

    asset_store: as.AssetStore,
    game_map: map.Map,
    tileset: tileset.Tileset,
    tileset_texture: rl.Texture2D,

    visited_tiles_points: std.AutoHashMap(fov.Point, void),
    visible_tiles_points: std.AutoHashMap(fov.Point, void),

    current_turn: Turn,
    player: plr.Player,
    enemies: std.ArrayList(enmy.Enemy),
    items: std.ArrayList(item.Item),

    main_menu_ui: ui.MainMenuUI,
    game_over_menu_ui: ui.GameOverUI,
    pause_menu_ui: ui.PauseMenuUI,
    hud: hud.HUD,

    camera: rl.Camera2D,

    pub fn init(allocator: std.mem.Allocator) Game {
        return Game{ .allocator = allocator, .window_width = 1280, .window_height = 800, .vsync = true, .highdpi = true, .fps = 60, .is_running = false, .game_state = GameState.MainMenu, .asset_store = as.AssetStore.init(allocator), .game_map = undefined, .tileset = undefined, .tileset_texture = undefined, .visible_tiles_points = std.AutoHashMap(fov.Point, void).init(allocator), .visited_tiles_points = std.AutoHashMap(fov.Point, void).init(allocator), .current_turn = Turn.Player, .player = plr.Player.init(allocator, rl.Vector2.zero(), '@'), .enemies = std.ArrayList(enmy.Enemy).init(allocator), .items = std.ArrayList(item.Item).init(allocator), .main_menu_ui = ui.MainMenuUI.init(), .pause_menu_ui = ui.PauseMenuUI.init(), .game_over_menu_ui = ui.GameOverUI.init(), .hud = undefined, .camera = undefined };
    }
    pub fn deinit(self: *Game) void {
        rl.closeWindow();
        self.asset_store.deinit();
        self.game_map.destroy();
        self.visited_tiles_points.deinit();
        self.visible_tiles_points.deinit();
        self.enemies.deinit();
        self.items.deinit();
        self.hud.deinit();
    }
    fn setup(self: *Game) Error!void {
        std.log.info("[ZRogue] Setup...", .{});
        rl.setConfigFlags(.{ .window_highdpi = self.highdpi, .window_resizable = false, .vsync_hint = self.vsync });
        rl.initWindow(self.window_width, self.window_height, "ZRogue");
        rl.setTargetFPS(self.fps);

        self.asset_store.addTexture("tileset", "resources/redjack16x16.png") catch |err| {
            std.log.err("Error adding texture: {}", .{err});
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

        const camera_x: f32 = @floatFromInt(self.window_width);
        const camera_y: f32 = @floatFromInt(self.window_height);

        self.camera = rl.Camera2D{ .offset = rl.Vector2{ .x = camera_x / 2.0, .y = camera_y / 2.0 }, .target = self.player.position, .rotation = 0.0, .zoom = 2.0 };
        self.hud = hud.HUD.init(self.allocator) catch |err| {
            std.log.err("Error initializing HUD: {}", .{err});
            return Error.InitializationFailed;
        };
    }
    pub fn run(self: *Game) Error!void {
        self.is_running = true;
        try self.setup();
        while (!rl.windowShouldClose() and self.is_running) {
            try self.update();
            try self.render();
        }
    }
    fn update(self: *Game) Error!void {
        switch (self.game_state) {
            GameState.MainMenu => {
                self.main_menu_ui.play_button.update();
                self.main_menu_ui.quit_button.update();

                if (self.main_menu_ui.play_button.is_pressed) {
                    try self.startNewGame();
                    self.game_state = GameState.Playing;
                }
                if (self.main_menu_ui.quit_button.is_pressed) {
                    self.is_running = false;
                }
                if (rl.isKeyPressed(.escape)) {
                    self.is_running = false;
                }
            },
            GameState.PauseMenu => {
                self.pause_menu_ui.main_menu_button.update();
                self.pause_menu_ui.options_button.update();
                self.pause_menu_ui.resume_button.update();

                if (self.pause_menu_ui.main_menu_button.is_pressed) {
                    try self.reset();
                    self.game_state = GameState.MainMenu;
                }
                if (self.pause_menu_ui.options_button.is_pressed) {
                    debug.print("Options menu", .{});
                }
                if (self.pause_menu_ui.resume_button.is_pressed) {
                    self.game_state = GameState.Playing;
                }
            },
            GameState.Playing => {
                if (rl.isKeyPressed(.m)) {
                    self.game_state = GameState.PauseMenu;
                    return;
                }
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
                    if (rl.isKeyPressed(.p)) {
                        // if current tile contains item, pick it up
                        const item_position = self.getItemAtCurrentPosition();
                        if (item_position != null) {
                            const i = self.items.items[item_position.?];
                            self.hud.addMessage("You picked up a {s}", .{i.name}, hud.HUDMessageType.Info) catch {};
                            const can_remove_item = self.updateItem(i) catch |err| {
                                std.log.err("Error updating item: {}", .{err});
                                return Error.UpdateFailed;
                            };
                            if (can_remove_item) {
                                _ = self.items.swapRemove(item_position.?);
                            }
                        }
                    }
                    const enemy_hit = self.checkEnemyHitByPlayer(target_position);
                    if (enemy_hit != null) {
                        const enemy_idx: usize = enemy_hit.?;
                        if (self.enemies.items[enemy_idx].combat_component.isDead()) {
                            self.hud.addMessage("{s}", .{"The enemy dies!"}, hud.HUDMessageType.Death) catch {};
                            _ = self.enemies.swapRemove(enemy_idx);
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
                self.updateCamera();
            },
            GameState.GameOver => {
                self.game_over_menu_ui.main_menu_button.update();
                self.game_over_menu_ui.restart_button.update();

                if (self.game_over_menu_ui.main_menu_button.is_pressed) {
                    try self.reset();
                    self.game_state = GameState.MainMenu;
                }
                if (self.game_over_menu_ui.restart_button.is_pressed) {
                    try self.reset();
                    try self.startNewGame();
                    self.game_state = GameState.Playing;
                }
            },
        }
    }
    fn updateCamera(self: *Game) void {
        const hud_height: f32 = 150.0;
        const available_height = @as(f32, @floatFromInt(self.window_height)) - hud_height;

        self.camera.target = self.player.position;
        self.camera.offset = rl.Vector2{
            .x = @as(f32, @floatFromInt(self.window_width)) / 2.0,
            .y = available_height / 2.0,
        };
    }
    fn updateItem(self: *Game, i: item.Item) !bool {
        // Consume
        if (i.isConsumable()) {
            if (i.getConsumableData()) |consumable_data| {
                self.player.combat_component.addHpClamped(consumable_data.healing_value);
                if (i.charges == 1) {
                    return true;
                }
                //i.charges -= 1;
            }
        } else if (i.isEquippable()) {
            try self.player.addItemToInventory(i);
            return true;
        }
        return false;
    }
    fn reset(self: *Game) Error!void {
        self.game_map.destroy();
        self.visited_tiles_points.clearRetainingCapacity();
        self.visible_tiles_points.clearRetainingCapacity();
        self.enemies.clearRetainingCapacity();
    }
    fn render(self: *Game) Error!void {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        switch (self.game_state) {
            GameState.MainMenu => {
                try self.renderMainMenu();
            },
            GameState.PauseMenu => {
                try self.renderPauseMenu();
            },
            GameState.Playing => {
                try self.renderPlayingGame();
            },
            GameState.GameOver => {
                try self.renderGameOverMenu();
            },
        }
    }
    fn renderGameOverMenu(self: *Game) Error!void {
        // Title
        const title = "GAME OVER";
        const title_font_size = 48;
        const title_width = rl.measureText(title, title_font_size);
        const title_x = (@as(f32, @floatFromInt(self.window_width)) - @as(f32, @floatFromInt(title_width))) / 2.0;
        rl.drawText(title, @intFromFloat(title_x), 200, title_font_size, rl.Color.red);

        // Death message
        const death_msg = "You have fallen in the depths...";
        const death_font_size = 20;
        const death_width = rl.measureText(death_msg, death_font_size);
        const death_x = (@as(f32, @floatFromInt(self.window_width)) - @as(f32, @floatFromInt(death_width))) / 2.0;
        rl.drawText(death_msg, @intFromFloat(death_x), 280, death_font_size, rl.Color.white);

        // Buttons
        self.game_over_menu_ui.restart_button.render();
        self.game_over_menu_ui.main_menu_button.render();

        // Instructions
        const instructions = "Press ENTER to restart or ESC for main menu";
        const inst_font_size = 16;
        const inst_width = rl.measureText(instructions, inst_font_size);
        const inst_x = (@as(f32, @floatFromInt(self.window_width)) - @as(f32, @floatFromInt(inst_width))) / 2.0;
        rl.drawText(instructions, @intFromFloat(inst_x), 600, inst_font_size, rl.Color.gray);
    }
    fn renderMainMenu(self: *Game) Error!void {
        const title = "ZRogue";
        const title_font_size = 72;
        const title_width = rl.measureText(title, title_font_size);
        const title_x = (@as(f32, @floatFromInt(self.window_width)) - @as(f32, @floatFromInt(title_width))) / 2.0;
        rl.drawText(title, @intFromFloat(title_x), 150, title_font_size, rl.Color.white);

        const subtitle = "A Roguelike Adventure";
        const subtitle_font_size = 24;
        const subtitle_width = rl.measureText(subtitle, subtitle_font_size);
        const subtitle_x = (@as(f32, @floatFromInt(self.window_width)) - @as(f32, @floatFromInt(subtitle_width))) / 2.0;
        rl.drawText(subtitle, @intFromFloat(subtitle_x), 240, subtitle_font_size, rl.Color.light_gray);

        self.main_menu_ui.play_button.render();
        self.main_menu_ui.quit_button.render();

        const instructions = "Press ENTER to play or ESC to quit";
        const inst_font_size = 16;
        const inst_width = rl.measureText(instructions, inst_font_size);
        const inst_x = (@as(f32, @floatFromInt(self.window_width)) - @as(f32, @floatFromInt(inst_width))) / 2.0;
        rl.drawText(instructions, @intFromFloat(inst_x), 650, inst_font_size, rl.Color.gray);
    }
    fn renderPlayingGame(self: *Game) Error!void {
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
        rl.beginMode2D(self.camera);
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

        // DRAW ITEMS
        for (self.items.items) |i| {
            const item_tile_coordinates = self.tileset.getTileCoordinates(i.glyph) catch |err| {
                std.log.err("Error getting texture coordinates for item: {}", .{err});
                return Error.RenderingFailed;
            };
            const tile_position = self.worldPositionToTilePosition(i.position);
            const item_dest_rect = rl.Rectangle{ .x = i.position.x, .y = i.position.y, .height = self.tileset.tile_size, .width = self.tileset.tile_size };
            if (self.visible_tiles_points.contains(tile_position)) {
                rl.drawTexturePro(self.tileset_texture, item_tile_coordinates.rect, item_dest_rect, .{ .x = 0, .y = 0 }, 0.0, rl.Color.green);
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

        rl.endMode2D();

        // RENDER HUD
        self.hud.render(self.window_width, self.window_height, self.player.combat_component.hp, self.player.combat_component.max_hp);
    }
    fn startNewGame(self: *Game) Error!void {
        std.log.info("[ZRogue] Starting new game...", .{});
        self.game_map = map.Map.generate(self.allocator, 80, 50, &self.enemies, &self.items) catch |err| {
            std.log.err("Error generating map: {}", .{err});
            return Error.InitializationFailed;
        };
        const starting_room = self.game_map.startingRoom() catch |err| {
            std.log.err("Error getting the starting room: {}", .{err});
            return Error.InitializationFailed;
        };
        self.player.position = rl.Vector2{ .x = starting_room.center().x * self.tileset.tile_size, .y = starting_room.center().y * self.tileset.tile_size };
        probability.initRandom();
        std.log.info("[ZRogue] Game started", .{});
    }
    fn renderPauseMenu(self: *Game) Error!void {
        // Semi-transparent overlay
        rl.drawRectangle(0, 0, self.window_width, self.window_height, rl.Color{ .r = 0, .g = 0, .b = 0, .a = 180 });

        // Title
        const title = "PAUSED";
        const title_font_size = 48;
        const title_width = rl.measureText(title, title_font_size);
        const title_x = (@as(f32, @floatFromInt(self.window_width)) - @as(f32, @floatFromInt(title_width))) / 2.0;
        rl.drawText(title, @intFromFloat(title_x), 200, title_font_size, rl.Color.white);

        // Buttons
        self.pause_menu_ui.resume_button.render();
        self.pause_menu_ui.options_button.render();
        self.pause_menu_ui.main_menu_button.render();

        // Instructions
        const instructions = "Press ESC to resume";
        const inst_font_size = 16;
        const inst_width = rl.measureText(instructions, inst_font_size);
        const inst_x = (@as(f32, @floatFromInt(self.window_width)) - @as(f32, @floatFromInt(inst_width))) / 2.0;
        rl.drawText(instructions, @intFromFloat(inst_x), 600, inst_font_size, rl.Color.gray);
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
                const player_combat_component = self.player.combatComponentWithBonuses();
                const combat_result = combat.simpleSubtraction(player_combat_component, &enemy.combat_component);

                self.hud.addMessage("You hit the {s} for {} damage!", .{ enemy.name, combat_result.damage_dealt }, hud.HUDMessageType.Combat) catch {};
                return i;
            }
        }
        return null;
    }
    fn getItemAtCurrentPosition(self: *Game) ?usize {
        for (self.items.items, 0..) |i, idx| {
            if (i.position.x == self.player.position.x and i.position.y == self.player.position.y) {
                return idx;
            }
        }
        return null;
    }
    fn isPositionWalkable(self: *Game, pos: rl.Vector2) bool {
        const tile_pos = self.worldPositionToTilePosition(pos);
        const tile = self.game_map.getTile(tile_pos.x, tile_pos.y);
        if (tile == null or !tile.?.walkable) {
            return false;
        }
        if (pos.x == self.player.position.x and pos.y == self.player.position.y) {
            return false;
        }
        for (self.enemies.items) |other_enemy| {
            if (other_enemy.position.x == pos.x and other_enemy.position.y == pos.y) {
                return false;
            }
        }
        return true;
    }
    fn getAdjacentWalkablePositions(self: *Game, current_pos: rl.Vector2, allocator: std.mem.Allocator) !std.ArrayList(rl.Vector2) {
        var positions = std.ArrayList(rl.Vector2).init(allocator);
        const tile_size = self.tileset.tile_size;

        // 8 directions: up, down, left, right
        const directions = [_]rl.Vector2{
            rl.Vector2{ .x = 0, .y = -tile_size }, // Up
            rl.Vector2{ .x = 0, .y = tile_size }, // Down
            rl.Vector2{ .x = -tile_size, .y = 0 }, // Left
            rl.Vector2{ .x = tile_size, .y = 0 }, // Right
        };

        for (directions) |direction| {
            const new_pos = rl.Vector2{
                .x = current_pos.x + direction.x,
                .y = current_pos.y + direction.y,
            };

            if (self.isPositionWalkable(new_pos)) {
                try positions.append(new_pos);
            }
        }

        return positions;
    }
    fn moveToward(current_pos: rl.Vector2, target_pos: rl.Vector2, tile_size: f32) rl.Vector2 {
        const dx = target_pos.x - current_pos.x;
        const dy = target_pos.y - current_pos.y;

        var move_x: f32 = 0;
        var move_y: f32 = 0;

        if (dx > 0) move_x = tile_size;
        if (dx < 0) move_x = -tile_size;
        if (dy > 0) move_y = tile_size;
        if (dy < 0) move_y = -tile_size;

        return rl.Vector2{
            .x = current_pos.x + move_x,
            .y = current_pos.y + move_y,
        };
    }
    fn moveEnemyRandomly(self: *Game, enemy: *enmy.Enemy) !void {
        const adjacent_positions = try self.getAdjacentWalkablePositions(enemy.position, self.allocator);
        defer adjacent_positions.deinit();

        if (adjacent_positions.items.len > 0) {
            // 70% chance to move, 30% chance to stay still
            if (std.crypto.random.intRangeAtMost(u8, 1, 100) <= 70) {
                const random_index = std.crypto.random.intRangeAtMost(usize, 0, adjacent_positions.items.len - 1);
                enemy.position = adjacent_positions.items[random_index];
            }
        }
    }
    fn executeEnemyTurn(self: *Game) void {
        const threshold_distance: f32 = 5.0;
        const sight_range: f32 = 8.0;

        for (self.enemies.items) |*enemy| {
            const dx: f32 = self.player.position.x - enemy.position.x;
            const dy: f32 = self.player.position.y - enemy.position.y;
            const chebyshev_distance = @divFloor(@max(@abs(dx), @abs(dy)), self.tileset.tile_size);
            const enemy_tile_pos = self.worldPositionToTilePosition(enemy.position);
            const can_see_player = self.visible_tiles_points.contains(enemy_tile_pos) or chebyshev_distance <= sight_range;
            if (chebyshev_distance == 1.0) {
                // TODO: change the behaviour of combat
                var player_combat_component = self.player.combatComponentWithBonuses();
                const combat_result = combat.simpleSubtraction(enemy.combat_component, &player_combat_component);
                self.player.combat_component.hp = player_combat_component.hp;
                self.hud.addMessage("{s} hits you for {} damage!", .{ enemy.name, combat_result.damage_dealt }, hud.HUDMessageType.Damage) catch {};
            } else if (can_see_player and chebyshev_distance <= threshold_distance) {
                const target_pos = moveToward(enemy.position, self.player.position, self.tileset.tile_size);
                if (self.isPositionWalkable(target_pos)) {
                    enemy.position = target_pos;
                } else {
                    self.moveEnemyRandomly(enemy) catch {};
                }
            } else {
                self.moveEnemyRandomly(enemy) catch {};
            }
        }
    }
    fn updateAfterCombat(self: *Game) void {
        if (self.player.combat_component.isDead()) {
            self.game_state = GameState.GameOver;
        }
    }
};
