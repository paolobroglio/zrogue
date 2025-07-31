const std = @import("std");
const ArrayList = std.ArrayList;
const debug = std.debug;
const testing = std.testing;
const map = @import("map.zig");

pub const Point = struct {
  x: i32,
  y: i32,
  pub fn eql(a: Point, b: Point) bool {
    return a.x == b.x and a.y == b.y;
  }
  pub fn hash(self: Point) u64 {
    return std.hash.hash2(self.x, self.y);
  }
};

fn pointsWithinRadius(allocator: std.mem.Allocator, center: Point, radius: i32) !ArrayList(Point) {
  var points = ArrayList(Point).init(allocator);

  const radius_squared: i32 = radius * radius;


  const min_y = @max(center.y - radius, 0);
  const max_y = center.y + radius + 1;

  for (@intCast(min_y)..@intCast(max_y)) |y_size| {
    const y: i32 = @intCast(y_size);
    const min_x = @max(center.x - radius, 0);
    const max_x = center.x + radius + 1;
    for (@intCast(min_x)..@intCast(max_x)) |x_size| {
      const x: i32 = @intCast(x_size);
      const dx: i32 = x - center.x;
      const dy: i32 = y - center.y;
      const distance_squared: i32 = dx * dx + dy * dy;

      if (distance_squared <= radius_squared) {
        try points.append(Point {.x = x, .y = y});
      }
    }
  }
  return points;
}


pub fn castRay(allocator: std.mem.Allocator, start: Point, end: Point, m: map.Map) !ArrayList(Point) {
  var visited_tiles_coordinates = ArrayList(Point).init(allocator);

  // starting points
  var x_0: i32 = start.x;
  var y_0: i32 = start.y;
  // destination coordinates
  const x_1: i32 = end.x;
  const y_1: i32 = end.y;

  // Horizontal distance
  const dx: i32 = @intCast(@abs(x_1 - x_0));
  // Vertical distance ( WHY NEGATIVE ABS?)
  const abs_dy: i32 = @intCast(@abs(y_1 - y_0));
  const dy: i32 = -abs_dy;
  // Step direction (right/down 1 left/up -1)
  const x_step_direction: i32 = if (x_0 < x_1) 1 else -1;
  const y_step_direction: i32 = if (y_0 < y_1) 1 else -1;
  // Error accumulator that tracks how far off we are from the "ideal line"
  var error_accumulator: i32 = dx + dy;

  while (true) {
    // get tile or break (out of bounds)
    if (!m.tileExists(x_0, y_0)) break;
    try visited_tiles_coordinates.append(Point{.x = x_0, .y = y_0});
    //debug.print("visited tile: ({}, {})\n", .{x_0, y_0});
    // Destination reached
    if (x_0 == x_1 and y_0 == y_1) break;
    // Test error is still ok (e2 is multiplied by 2 to consider both axis)
    const error_both_axis = 2 * error_accumulator;
    // If error is ok we step horizontally while dy is added to error
    if (error_both_axis >= dy) {
      error_accumulator += dy;
      x_0 += x_step_direction;
    }
    // Same thing for y, we can step vertically
    if (error_both_axis <= dx) {
      error_accumulator += dx;
      y_0 += y_step_direction;
    }
  }

  return visited_tiles_coordinates;
}

pub fn computeFOV(allocator: std.mem.Allocator, center: Point, radius: i32, m: map.Map) !std.AutoHashMap(Point, void) {
  var visible = std.AutoHashMap(Point, void).init(allocator);

  const candidates = try pointsWithinRadius(allocator, center, radius);
  defer candidates.deinit();

  for (candidates.items) |target| {
      var ray_tiles_coordinates = try castRay(allocator,center, target, m);
      for (ray_tiles_coordinates.items) |coordinate_point| {
        const tile = m.getTile(coordinate_point.x, coordinate_point.y).?;
        if (!tile.transparent) break;
        try visible.put(coordinate_point, {});
      }
      ray_tiles_coordinates.deinit();
  }

  return visible;
}

test "cast ray" {
  const allocator = testing.allocator;

  const map_height = 10;
  const map_width = 10;

  const player_position = Point {
    .x = 5,
    .y = 5
  };

  const end_position = Point {
    .x = 1,
    .y = 1
  };

  const m = try map.Map.init(allocator, map_width, map_height);
  defer m.destroy();

  const visited_points= try castRay(allocator, player_position, end_position, m);
  defer visited_points.deinit();

  try testing.expect(visited_points.items.len == 5);
}

test "points within radius" {
    const allocator = std.testing.allocator;
    const center = Point{ .x = 5, .y = 5 };
    const radius: i32 = 1;

    var points = try pointsWithinRadius(allocator, center, radius);
    defer points.deinit();

    try std.testing.expect(points.items.len == 5);
}

test "points within radius with clamped values" {
    const allocator = std.testing.allocator;
    const center = Point{ .x = 5, .y = 5 };
    const radius: i32 = 6;

    var points = try pointsWithinRadius(allocator, center, radius);
    defer points.deinit();
}

test "compute FOV" {
  const allocator = testing.allocator;

  const map_height = 10;
  const map_width = 10;

  const player_position = Point {
    .x = 2,
    .y = 2
  };

  var m = try map.Map.init(allocator, map_width, map_height);
  defer m.destroy();

  m.createFloorRoom(1, 1, 5, 5);

  var fov_points = try computeFOV(allocator, player_position, 2, m);
  defer fov_points.deinit();

  var iterator = fov_points.keyIterator();

  while (iterator.next()) |entry| {
    debug.print("FOV POINT ({}, {})\n", .{
        entry.*.x,
        entry.*.y
    });
  }

  try testing.expect(iterator.len == 0);
}