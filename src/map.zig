const std = @import("std");
const rl = @import("raylib");

const Error = error{MapNotInitialized};

pub const TileGraphics = struct {
    char: u8,
    fgColor: rl.Color,
    bgColor: rl.Color,

    pub fn init(char: u8, fgColor: rl.Color, bgColor: rl.Color) TileGraphics {
        return TileGraphics{ .char = char, .fgColor = fgColor, .bgColor = bgColor };
    }
};

pub const Tile = struct {
    walkable: bool,
    transparent: bool,
    dark: TileGraphics,

    pub fn init(walkable: bool, transparent: bool, dark: TileGraphics) Tile {
        return Tile{ .walkable = walkable, .transparent = transparent, .dark = dark };
    }
};

pub const FloorTile = Tile{ .walkable = true, .transparent = true, .dark = TileGraphics{
    .char = ' ',
    .fgColor = rl.Color.init(255, 255, 255, 255),
    .bgColor = rl.Color.init(50, 50, 150, 255),
} };

pub const WallTile = Tile{ .walkable = false, .transparent = false, .dark = TileGraphics{
    .char = ' ',
    .fgColor = rl.Color.init(255, 255, 255, 255),
    .bgColor = rl.Color.init(0, 0, 100, 255),
} };

pub const Map = struct {
    width: i32,
    height: i32,
    tiles: std.ArrayList(Tile),

    pub fn init(allocator: std.mem.Allocator, width: i32, height: i32) !Map {
        var newMap = Map{ .width = width, .height = height, .tiles = try std.ArrayList(Tile).initCapacity(allocator, @intCast(width * height)) };
        try newMap.tiles.appendNTimes(WallTile, @intCast(width * height));

        return newMap;
    }

    pub fn coordsToIndex(self: *const Map, x: i32, y: i32) ?usize {
      if (x < 0 or x >= self.width or y < 0 or y >= self.height) {
          return null; // TODO: return error?
      }
      return @intCast(y * self.width + x);
    }

    pub fn setTile(self: *Map, x: i32, y: i32, tile: Tile) void {
      if (self.coordsToIndex(x, y)) |index| {
          self.tiles.items[index] = tile;
      }
    }

    pub fn getTile(self: *const Map, x: i32, y: i32) ?Tile {
      if (self.coordsToIndex(x, y)) |index| {
          return self.tiles.items[index];
      }
      return null;
    }

    pub fn createRoom(self: *Map, x: i32, y: i32, width: i32, height: i32) void {
      var row: i32 = y;
      while (row < y + height) : (row += 1) {
        var col: i32 = x;
        while (col < x + width) : (col += 1) {
          if (row == y or row == y + height - 1 or col == x or col == x + width - 1) {
              self.setTile(col, row, WallTile);
          } else {
              self.setTile(col, row, FloorTile);
          }
        }
      }
    }

    pub fn createFloorRoom(self: *Map, x: i32, y: i32, width: i32, height: i32) void {
      var row: i32 = y;
      while (row < y + height) : (row += 1) {
        var col: i32 = x;
        while (col < x + width) : (col += 1) {
            self.setTile(col, row, FloorTile);
        }
      }
    }
};
