const cp437 = @import("cp437.zig");
const rl = @import("raylib");

pub const GlyphMapType = enum { 
  Cp437 
};

const TilesetError = error{
  LoadFailed, CharMapNotFound
};

pub const Tileset = struct {
    textureId: []const u8,
    glyph_map_type: GlyphMapType,
    tile_width: u8,
    tile_height: u8,

    pub fn init(id: []const u8, glyph_map_type: GlyphMapType, tile_width: u8, tile_height: u8) TilesetError!Tileset {
        return Tileset{ 
          .textureId = id, 
          .glyph_map_type = glyph_map_type, 
          .tile_width = tile_width, 
          .tile_height = tile_height 
        };
    }
    pub fn getTileCoordinates(self: *const Tileset, char: u8) TilesetError!rl.Vector2 {
      switch(self.glyph_map_type) {
        GlyphMapType.Cp437 => {
          return cp437.getTextureCoordinates(char);
        }
      }
    }
};
