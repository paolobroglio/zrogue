const std = @import("std");
const debug = std.debug;
const as = @import("assetstore.zig");
const map = @import("map.zig");
const tileset = @import("tileset.zig");
const fov = @import("fov.zig");
const rl = @import("raylib");

pub const Error = enum {
  InitializationFailed, 
  DeinitializationFailed, 
  RunFailed,
  InputHandlingFailed,
  RenderingFailed,
  UpdateFailed
};

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

  visited_tiles_points: std.AutoHashMap(fov.Point, void),
  visible_tiles_points: std.AutoHashMap(fov.Point, void),

  player_position: rl.Vector2,

  pub fn init(allocator: std.mem.Allocator) Error!Game {
    return Game {
      .allocator = allocator,
      .window_width = 1280,
      .window_height = 800,
      .vsync = true,
      .highdpi = true,
      .fps = 60,
      .is_running = false,
      .asset_store = as.AssetStore.init(allocator),
      .game_map = undefined,
      .tileset = undefined,
      .visible_tiles_points = std.AutoHashMap(fov.Point, void).init(allocator),
      .visited_tiles_points = std.AutoHashMap(fov.Point, void).init(allocator),
      .player_position = rl.Vector2.zero(),
    };
  }
  pub fn deinit(self: *Game) Error!void {
    rl.closeWindow();
    self.asset_store.deinit();
    self.game_map.destroy();
    self.visited_tiles_points.deinit();
    self.visible_tiles_points.deinit();
  }
  fn setup(self: *Game) Error!void {
    rl.setConfigFlags(.{
      .window_highdpi = self.highdpi, 
      .window_resizable = false, 
      .vsync_hint = self.vsync
    });
    rl.initWindow(self.window_width, self.window_height, "ZRogue");
    rl.setTargetFPS(self.fps);

    try self.asset_store.addTexture("tileset", "resources/redjack16x16.png");
    self.game_map = try map.Map.generate(self.allocator, 80, 50);
    self.tileset = try tileset.Tileset.init("tileset", tileset.GlyphMapType.Cp437, 16.0);

    const starting_room = try self.game_map.startingRoom();
    self.player_position = rl.Vector2 {
        .x = starting_room.center().x * self.tileset.tile_size, 
        .y = starting_room.center().y * self.tileset.tile_size
    };
  }
  pub fn run(self: *const Game) Error!void {
    self.setup();
    const execute_loop = !rl.windowShouldClose() and self.is_running;
    while (execute_loop) {
      self.processInput();
      self.update();
      self.render();
    }
  }
  fn processInput() Error!void {}
  fn update(self: *Game) Error!void {
    const tile_size = self.tileset.tile_size;
    var target_position = self.player_position;
    if (rl.isKeyPressed(.right)) {
      target_position.x += tile_size;
    }
    if (rl.isKeyPressed(.left)) {
      target_position.x -= tile_size;
    }
    if (rl.isKeyPressed(.up)) {
      target_position.y -= tile_size;
    }
    if (rl.isKeyPressed(.down)) {
      target_position.y += tile_size;
    }
    var target_player_point: fov.Point = playerPositionToTilePosition(target_position);
    if (self.game_map.getTile(target_player_point.x, target_player_point.y).?.walkable) {
      self.player_position = target_position;
    } else {
      target_player_point = playerPositionToTilePosition(self.player_position);
    }

    var visible_tiles = try fov.computeFOV(self.allocator, target_player_point, 5, self.game_map);
    var it = visible_tiles.iterator();
    while (it.next())|entry| {
      try self.visited_tiles_points.put(entry.key_ptr.*, {});
    }
  }
  fn render(self: *Game) Error!void {
    const tileset_texture: rl.Texture2D = try self.asset_store.getTexture("tileset");
    const player_tile_coordinates = try self.tileset.getTileCoordinates('@');
    const wall_tile_coordinates = try self.tileset.getTileCoordinates('#');
    const floor_tile_coordinates = try self.tileset.getTileCoordinates('`');

    rl.beginDrawing();
    defer rl.endDrawing();

    rl.clearBackground(rl.Color.black);

    // DRAW PLAYER
    const player_dest_rect: rl.Rectangle = rl.Rectangle { 
      .x = self.player_position.x, 
      .y = self.player_position.y, 
      .height = self.tileset.tile_size, 
      .width = self.tileset.tile_size
    };
    rl.drawTexturePro(
      tileset_texture, 
      player_tile_coordinates.rect, 
      player_dest_rect, 
      .{.x = 0, .y = 0}, 
      0.0, 
      rl.Color.ray_white
    );

    // DRAW MAP
    for (self.game_map.tiles.items, 0..) |tile, index| {
      const x = @as(f32, @floatFromInt(index % self.map_width)) * self.tileset.tile_size;
      const y = @as(f32, @floatFromInt(index / self.map_width)) * self.tileset.tile_size;
            
      const tile_dest_rect = rl.Rectangle {
          .x = x,
          .y = y,
          .height = self.tileset.tile_size,
          .width = self.tileset.tile_size
      };
      const tile_src_rect = if (tile.walkable) 
          floor_tile_coordinates.rect
      else 
          wall_tile_coordinates.rect;

      const point = fov.Point{.x = tile.x, .y = tile.y};
      if (self.visible_tiles_points.contains(point)) {
        if (x > self.window_width or y > self.window_height) {
            debug.print("WARNING: Tile at ({}, {}) off screen\n", .{x, y});
        }
        const bg_color = tile.light.bgColor;
        // background
        rl.drawTexturePro(
            tileset_texture, 
            tile_src_rect, 
            tile_dest_rect, 
            .{.x = 0, .y = 0}, 
            0.0, 
            bg_color);
      } else {
        if (self.visited_tiles_points.contains(point)) {
          const bg_color = tile.dark.bgColor;
          rl.drawTexturePro(
              tileset_texture,
              tile_src_rect,
              tile_dest_rect,
              .{.x = 0, .y = 0}, 
              0.0, 
              bg_color);
        }
      }
    }
  }
  fn playerPositionToTilePosition(self: *Game, pos: rl.Vector2) fov.Point {
    return fov.Point{
        .x = @intFromFloat(pos.x / self.tileset.tile_size),
        .y = @intFromFloat(pos.y / self.tileset.tile_size),
    };
}
};