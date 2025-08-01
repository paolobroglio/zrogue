const std = @import("std");
const debug = std.debug;
const as = @import("assetstore.zig");
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
  // configurations
  window_width: i32,
  window_height: i32,
  vsync: bool,
  highdpi: bool,
  fps: i32,

  is_running: bool,

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
      .is_running = false,
      .asset_store = as.AssetStore.init(allocator),
      .map_width = 80, // window width / tile_size
      .map_height = 50 // window height / tile_size
    };
  }
  pub fn deinit(self: *Game) Error!void {
    rl.closeWindow();
    self.asset_store.deinit();
  }
  fn setup(self: *const Game) Error!void {
    rl.setConfigFlags(.{
      .window_highdpi = self.highdpi, 
      .window_resizable = false, 
      .vsync_hint = self.vsync
    });
    rl.initWindow(self.window_width, self.window_height, "ZRogue");
    rl.setTargetFPS(self.fps);
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
  fn update() Error!void {}
  fn render() Error!void {}
};