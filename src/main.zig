const std = @import("std");
const debug = std.debug;
const rl = @import("raylib");
const tileset = @import("tileset.zig");
const assetstore = @import("assetstore.zig");

const tile_size = 16.0;

const Position = struct {
    x: f32,
    y: f32
};

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 1280;
    const screenHeight = 800;

    rl.setConfigFlags(.{.window_highdpi = true, .window_resizable = false, .vsync_hint = true});

    rl.initWindow(screenWidth, screenHeight, "ZRogue");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    const allocator = std.heap.page_allocator;

    var assets = assetstore.AssetStore.init(allocator);
    try assets.addTexture("tileset", "resources/redjack16x16.png");

    var playerPosition = Position {.x = 400, .y = 250};

    const cp437Tileset = try tileset.Tileset.init("tileset", tileset.GlyphMapType.Cp437, 16);
    const tileCoordinates = try cp437Tileset.getTileCoordinates('@');
    const tilesetTexture: rl.Texture2D = try assets.getTexture("tileset"); 

    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) {
        // Update
        //----------------------------------------------------------------------------------
        if (rl.isKeyPressed(.right)) {
            playerPosition.x += tile_size;
        }
        if (rl.isKeyPressed(.left)) {
            playerPosition.x -= tile_size;
        }
        if (rl.isKeyPressed(.up)) {
            playerPosition.y -= tile_size;
        }
        if (rl.isKeyPressed(.down)) {
            playerPosition.y += tile_size;
        }
        //----------------------------------------------------------------------------------

        const destRect: rl.Rectangle = rl.Rectangle { .x = playerPosition.x, .y = playerPosition.y, .height = tile_size, .width = tile_size};
        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);
        
        rl.drawTexturePro(tilesetTexture, tileCoordinates.rect, destRect, .{.x = 0, .y = 0}, 0.0, rl.Color.ray_white);

        //----------------------------------------------------------------------------------
    }

    assets.deinit();
}
