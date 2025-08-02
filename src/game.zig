const std = @import("std");
const debug = std.debug;
const as = @import("assetstore.zig");
const map = @import("map.zig");
const tileset = @import("tileset.zig");
const fov = @import("fov.zig");
const rl = @import("raylib");

pub const Error = error {
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

  pub fn init(allocator: std.mem.Allocator) Game {
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
  pub fn deinit(self: *Game) void {
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

    self.asset_store.addTexture("tileset", "resources/redjack16x16.png") catch |err| {
      std.log.err("Error adding texture: {}", .{err});
      return Error.InitializationFailed;
    };
    self.game_map = map.Map.generate(self.allocator, 80, 50) catch |err| {
      std.log.err("Error generating map: {}", .{err});
      return Error.InitializationFailed;
    };
    self.tileset = tileset.Tileset.init("tileset", tileset.GlyphMapType.Cp437, 16.0) catch |err| {
      std.log.err("Error initiliazing tileset: {}", .{err});
      return Error.InitializationFailed;
    };

    const starting_room = self.game_map.startingRoom() catch |err| {
      std.log.err("Error getting the starting room: {}", .{err});
      return Error.InitializationFailed;
    };
    self.player_position = rl.Vector2 {
        .x = starting_room.center().x * self.tileset.tile_size, 
        .y = starting_room.center().y * self.tileset.tile_size
    };
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
    var target_player_point: fov.Point = self.playerPositionToTilePosition(target_position);
    const target_tile = self.game_map.getTile(target_player_point.x, target_player_point.y);
    if (target_tile != null and target_tile.?.walkable) {
      self.player_position = target_position;
    } else {
      target_player_point = self.playerPositionToTilePosition(self.player_position);
    }
    self.visible_tiles_points.clearAndFree();
    self.visible_tiles_points = fov.computeFOV(self.allocator, target_player_point, 5, self.game_map) catch |err| {
      std.log.err("Error computing FOV: {}", .{err});
      return Error.RunFailed;
    };
    var it = self.visible_tiles_points.iterator();
    while (it.next())|entry| {
      self.visited_tiles_points.put(entry.key_ptr.*, {}) catch |err| {
        std.log.err("Error adding a visited tile point: {}", .{err});
        return Error.RunFailed;
      };
    }
  }
  fn render(self: *Game) Error!void {
    const tileset_texture: rl.Texture2D = self.asset_store.getTexture("tileset") catch |err| {
      std.log.err("Error getting texture for tileset: {}", .{err});
      return Error.RenderingFailed;
    };
    const player_tile_coordinates = self.tileset.getTileCoordinates('@') catch |err| {
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
      const map_width: usize = @intCast(self.game_map.width);
      const x = @as(f32, @floatFromInt(index % map_width)) * self.tileset.tile_size;
      const y = @as(f32, @floatFromInt(index / map_width)) * self.tileset.tile_size;
            
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