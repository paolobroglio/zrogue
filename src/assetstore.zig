const std = @import("std");
const rl = @import("raylib");

pub const Error = error {
  AssetNotFound
};

pub const AssetStore = struct {
  textures: std.StringHashMap(*rl.Texture2D),
  allocator: std.mem.Allocator,

  pub fn init(allocator: std.mem.Allocator) AssetStore {
    return AssetStore {
      .textures = std.StringHashMap(*rl.Texture2D).init(allocator),
      .allocator = allocator
    };
  }
  pub fn addTexture(self: *AssetStore, textureId: []const u8, texturePath: [:0]const u8) !void {
    const texture_ptr = try self.allocator.create(rl.Texture2D);
    texture_ptr.* = try rl.loadTexture(texturePath);
    try self.textures.put(textureId, texture_ptr);
  }
  pub fn getTexture(self: *const AssetStore, textureId: []const u8) Error!rl.Texture2D {
    const texture_ptr = self.textures.get(textureId) orelse Error.AssetNotFound;
    return (try texture_ptr).*;
  }
  pub fn deinit(self: *AssetStore) void {
      self.clear();
      self.textures.deinit();
  }
  fn clear(self: *AssetStore) void {
    var texturesIt = self.textures.valueIterator();
    while (texturesIt.next()) |textureValue| {
      const texturePtr = textureValue.*;
      const texture = texturePtr.*;
      rl.unloadTexture(texture);
      self.allocator.destroy(texturePtr);
    } 
    self.textures.clearAndFree();
  }
};