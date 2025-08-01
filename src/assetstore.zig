const std = @import("std");
const rl = @import("raylib");

pub const Error = error {
  AssetNotFound, AssetNotLoaded
};

pub const AssetStore = struct {
  textures: std.StringHashMap(rl.Texture2D),
  allocator: std.mem.Allocator,

  pub fn init(allocator: std.mem.Allocator) AssetStore {
    return AssetStore {
      .textures = std.StringHashMap(rl.Texture2D).init(allocator),
      .allocator = allocator
    };
  }
  pub fn deinit(self: *AssetStore) void {
    self.clear();
    self.textures.deinit();
  }
  pub fn addTexture(self: *AssetStore, texture_id: []const u8, texture_path: [:0]const u8) !void {
    const owned_key = try self.allocator.dupe(u8, rl.Texture2D);
    errdefer self.allocator.free(owned_key);

    const texture = rl.loadTexture(texture_path) catch |err| {
      self.allocator.free(owned_key);
      return err;
    };

    try self.textures.put(texture_id, texture);
  }
  pub fn getTexture(self: *const AssetStore, texture_id: []const u8) Error!rl.Texture2D {
    return self.textures.get(texture_id) orelse Error.AssetNotFound;
  }
  pub fn hasTexture(self: *const AssetStore, texture_id: []const u8) bool {
    return self.textures.contains(texture_id);
  }
  pub fn removeTexture(self: *AssetStore, texture_id: []const u8) bool {
    if (self.textures.fetchRemove(texture_id)) |kv| {
      rl.unloadTexture(kv.value);
      self.allocator.free(kv.key);
      return true;
    }
    return false;
  }
  fn clear(self: *AssetStore) void {
    var iterator = self.textures.iterator();
    while (iterator.next()) |entry| {
        rl.unloadTexture(entry.value_ptr.*);
        self.allocator.free(entry.key_ptr.*);
    }
    self.textures.clearAndFree();
  }
};