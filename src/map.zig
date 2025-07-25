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

pub const Room = struct {
  x: i32,
  y: i32,
  width: i32,
  height: i32,

  pub fn init(x: i32, y: i32, width: i32, height: i32) Room {
    return Room {
      .x = x,
      .y = y,
      .width = width,
      .height = height
    };
  }

  pub fn center(self: *const Room) rl.Vector2 {
    return rl.Vector2 {
      .x = @floatFromInt(self.x + @divFloor(self.width, 2)),
      .y = @floatFromInt(self.y + @divFloor(self.height, 2))
    };
  }

  pub fn isPointInside(self: *const Room, point: rl.Vector2) bool {
    return point.x >= self.x and
           point.x < self.x + self.width and
           point.y >= self.y and
           point.y < self.y + self.height;
  }

  pub fn isRoomIntersecting(self: *const Room, other_room: Room) bool {
    return self.x <= other_room.x + other_room.width and
    self.x + self.width >= other_room.x and
    self.y <= other_room.y + other_room.height and
    self.y + self.height >= other_room.y;
  }
};

pub const Map = struct {
    width: i32,
    height: i32,
    tiles: std.ArrayList(Tile),
    rooms: std.ArrayList(Room),

    pub fn init(allocator: std.mem.Allocator, width: i32, height: i32) !Map {
        var newMap = Map{ 
          .width = width, 
          .height = height, 
          .tiles = try std.ArrayList(Tile).initCapacity(allocator, @intCast(width * height)),
          .rooms = std.ArrayList(Room).init(allocator) 
        };

        try newMap.tiles.appendNTimes(WallTile, @intCast(width * height));

        return newMap;
    }

    pub fn startingRoom(self: *const Map) !Room {
      if (self.rooms.items.len > 0){
        return self.rooms.items[0]; // TODO: make this safer
      }
      return Error.MapNotInitialized;
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

    pub fn createFloorRoom(self: *Map, x: i32, y: i32, width: i32, height: i32) void {
        var row: i32 = y;
        while (row < y + height) : (row += 1) {
            var col: i32 = x;
            while (col < x + width) : (col += 1) {
                self.setTile(col, row, FloorTile);
            }
        }
    }

    pub fn generate(allocator: std.mem.Allocator, width: i32, height: i32) !Map {
        var game_map = try init(allocator, width, height);

        const max_rooms:i32 = 30;
        const room_max_size: i32 = 10;
        const room_min_size: i32 = 6;

        for (0..max_rooms) |i| {
          const room_width: i32 = std.crypto.random.intRangeAtMost(i32, room_min_size, room_max_size);
          const room_height: i32 = std.crypto.random.intRangeAtMost(i32, room_min_size, room_max_size);

          const x = std.crypto.random.intRangeAtMost(i32, 0, width - room_width - 1);
          const y = std.crypto.random.intRangeAtMost(i32, 0, height - room_height - 1);

          const new_room = Room.init(x, y, room_width, room_height);

          var skip_room = false;
          for (game_map.rooms.items) |room| {
            if (room.isRoomIntersecting(new_room)){
              skip_room = true;
            }
          }

          if (skip_room) {
            continue;
          }

          game_map.createFloorRoom(x, y, room_width, room_height);

          if (i > 0) { // start carving tunnels from the second room
            const prev_room_center = game_map.rooms.getLast().center();
            const new_room_center = new_room.center();

            game_map.tunnelBetween(prev_room_center, new_room_center);
          }

          try game_map.rooms.append(new_room);
        }
        return game_map;
    }

    pub fn tunnelBetween(self: *Map, pointA: rl.Vector2, pointB: rl.Vector2) void {
        const x1: i32 = @intFromFloat(pointA.x);
        const y1: i32 = @intFromFloat(pointA.y);
        const x2: i32 = @intFromFloat(pointB.x);
        const y2: i32 = @intFromFloat(pointB.y);

        if (std.crypto.random.boolean()) {
            self.carveHorizontalTunnel(x1, x2, y1);
            self.carveVerticalTunnel(y1, y2, x2);
        } else {
            self.carveVerticalTunnel(y1, y2, x1);
            self.carveHorizontalTunnel(x1, x2, y2);
        }
    }

    fn carveHorizontalTunnel(self: *Map, x1: i32, x2: i32, y: i32) void {
        const start = @min(x1, x2);
        const end = @max(x1, x2);
        for (@intCast(start)..@intCast(end + 1)) |x| {
            self.setTile(@intCast(x), y, FloorTile);
        }
    }

    fn carveVerticalTunnel(self: *Map, y1: i32, y2: i32, x: i32) void {
        const start = @min(y1, y2);
        const end = @max(y1, y2);
        for (@intCast(start)..@intCast(end + 1)) |y| {
            self.setTile(x, @intCast(y), FloorTile);
        }
    }
};
