const std = @import("std");
const debug = std.debug;
const rl = @import("raylib");
const tileset = @import("tileset.zig");
const assetstore = @import("assetstore.zig");
const map = @import("map.zig");

const tile_size = 16.0;

const mapWidth = 80;
const mapHeight = 45;

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

    const cp437Tileset = try tileset.Tileset.init("tileset", tileset.GlyphMapType.Cp437, tile_size);
    const tilesetTexture: rl.Texture2D = try assets.getTexture("tileset");

    const playerTileCoordinates = try cp437Tileset.getTileCoordinates('@');
    const wallTileCoordinates = try cp437Tileset.getTileCoordinates('#');
    const floorTileCoordinates = try cp437Tileset.getTileCoordinates(' ');

    const game_map = try map.Map.generate(allocator, mapWidth, mapHeight);

    const starting_room = try game_map.startingRoom();

    var playerPosition = Position {
        .x = starting_room.center().x * tile_size, 
        .y = starting_room.center().y * tile_size
    };

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

        const destRect: rl.Rectangle = rl.Rectangle { 
            .x = playerPosition.x, 
            .y = playerPosition.y, 
            .height = tile_size, 
            .width = tile_size
        };

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);
        
        rl.drawTexturePro(tilesetTexture, playerTileCoordinates.rect, destRect, .{.x = 0, .y = 0}, 0.0, rl.Color.ray_white);

        // MAP DRAWING
        const tiles_per_row = mapWidth;
        for (game_map.tiles.items, 0..) |tile, index| {
            const x = @as(f32, @floatFromInt(index % tiles_per_row)) * tile_size;
            const y = @as(f32, @floatFromInt(index / tiles_per_row)) * tile_size;
            const tileDestRect = rl.Rectangle {
                .x = x,
                .y = y,
                .height = tile_size,
                .width = tile_size
            };
            const srcRect = if (tile.walkable) 
                floorTileCoordinates.rect
            else 
                wallTileCoordinates.rect;
            
            
            rl.drawTexturePro(tilesetTexture, srcRect, tileDestRect, .{.x = 0, .y = 0}, 0.0, rl.Color.white);
        }

        //----------------------------------------------------------------------------------
    }

    assets.deinit();
}
