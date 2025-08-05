const cp437 = @import("cp437.zig");
const rl = @import("raylib");

pub const GlyphMapType = enum { Cp437 };

const TilesetError = error{ LoadFailed, CharMapNotFound };

const TileCoordinates = struct {
    rect: rl.Rectangle,
    fn init(vec: rl.Vector2, tileSize: f32) TileCoordinates {
        return TileCoordinates{ .rect = rl.Rectangle{ .x = vec.x * tileSize, .y = vec.y * tileSize, .height = tileSize, .width = tileSize } };
    }
};

pub const Tileset = struct {
    textureId: []const u8,
    glyph_map_type: GlyphMapType,
    tile_size: f32,

    pub fn init(id: []const u8, glyph_map_type: GlyphMapType, tile_size: f32) TilesetError!Tileset {
        return Tileset{
            .textureId = id,
            .glyph_map_type = glyph_map_type,
            .tile_size = tile_size,
        };
    }
    pub fn getTileCoordinates(self: *const Tileset, char: u32) TilesetError!TileCoordinates {
        switch (self.glyph_map_type) {
            GlyphMapType.Cp437 => {
                const textureCoordinates = cp437.getTextureCoordinates(char);
                return TileCoordinates.init(textureCoordinates, self.tile_size);
            },
        }
    }
};
