const std = @import("std");
const debug = std.debug;
const as = @import("assetstore.zig");

pub const Error = enum {
  InitializationFailed, 
  DeinitializationFailed, 
  RunFailed,
  InputHandlingFailed,
  RenderingFailed,
  UpdateFailed
};

pub const Game = struct {
  // configurations
  window_width: i32,
  window_height: i32,
  vsync: bool,
  highdpi: bool,
  fps: i32,

  asset_store: as.AssetStore,

  map_width: i32,
  map_height: i32,

  pub fn init(allocator: std.mem.Allocator) Error!Game {
    return Game {
      .window_width = 1280,
      .window_height = 800,
      .vsync = true,
      .highdpi = true,
      .fps = 60,
      .asset_store = as.AssetStore.init(allocator),
      .map_width = 80, // window width / tile_size
      .map_height = 50 // window height / tile_size
    };
  }
  pub fn deinit(self: *Game) Error!void {
    self.asset_store.deinit();
  }
  pub fn run() Error!void {}

  fn setup() Error!void {}
  fn processInput() Error!void {}
  fn update() Error!void {}
  fn render() Error!void {}
};