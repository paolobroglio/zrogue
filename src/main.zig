const std = @import("std");
const debug = std.debug;
const rl = @import("raylib");
const tileset = @import("tileset.zig");
const assetstore = @import("assetstore.zig");
const map = @import("map.zig");
const fov = @import("fov.zig");

const tile_size = 16.0;

const mapWidth = 80;
const mapHeight = 50;

fn playerPositionToTilePosition(pos: rl.Vector2) fov.Point {
    return fov.Point{
        .x = @intFromFloat(pos.x / tile_size),
        .y = @intFromFloat(pos.y / tile_size),
    };
}

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
    const floorTileCoordinates = try cp437Tileset.getTileCoordinates('`');

    const game_map = try map.Map.generate(allocator, mapWidth, mapHeight);
    defer game_map.destroy();

    const starting_room = try game_map.startingRoom();

    var player_position = rl.Vector2 {
        .x = starting_room.center().x * tile_size, 
        .y = starting_room.center().y * tile_size
    };

    var visited_tiles = std.AutoHashMap(fov.Point, void).init(allocator);
    defer visited_tiles.deinit();

    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) {
        // Update
        //----------------------------------------------------------------------------------
        var target_position = player_position;
        if (rl.isKeyPressed(.right)) {
            target_position.x += tile_size;
        }
        if (rl.isKeyPressed(.left)) {
            target_position.x -= tile_size;
        }
        if (rl.isKeyPressed(.up)) {
            target_position.y -= tile_size;
        }
        if (rl.isKeyPressed(.down)) {
            target_position.y += tile_size;
        }

        var target_player_point: fov.Point = playerPositionToTilePosition(target_position);
        if (game_map.getTile(target_player_point.x, target_player_point.y).?.walkable) {
            player_position = target_position;
        } else {
            target_player_point = playerPositionToTilePosition(player_position);
        }

        var visible_tiles = try fov.computeFOV(allocator, target_player_point, 5, game_map);
        var it = visible_tiles.iterator();
        while (it.next())|entry| {
            try visited_tiles.put(entry.key_ptr.*, {});
        }

        const destRect: rl.Rectangle = rl.Rectangle { 
            .x = player_position.x, 
            .y = player_position.y, 
            .height = tile_size, 
            .width = tile_size
        };

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);
        
        rl.drawTexturePro(tilesetTexture, playerTileCoordinates.rect, destRect, .{.x = 0, .y = 0}, 0.0, rl.Color.ray_white);

        for (game_map.tiles.items, 0..) |tile, index| {
            const x = @as(f32, @floatFromInt(index % mapWidth)) * tile_size;
            const y = @as(f32, @floatFromInt(index / mapWidth)) * tile_size;
            
            const tileDestRect = rl.Rectangle {
                .x = x,
                .y = y,
                .height = tile_size,
                .width = tile_size
            };
            const tileSrcRect = if (tile.walkable) 
                floorTileCoordinates.rect
            else 
                wallTileCoordinates.rect;

            const point = fov.Point{.x = tile.x, .y = tile.y};
            if (visible_tiles.contains(point)) {
                if (x > screenWidth or y > screenHeight) {
                    debug.print("WARNING: Tile at ({}, {}) off screen\n", .{x, y});
                }
                //const fg_color = tile.light.fgColor;
                const bg_color = tile.light.bgColor;
                // background
                rl.drawTexturePro(
                    tilesetTexture, 
                    tileSrcRect, 
                    tileDestRect, 
                    .{.x = 0, .y = 0}, 
                    0.0, 
                    bg_color
                );
                // foreground
                // rl.drawTexturePro(
                //     tilesetTexture, 
                //     tileSrcRect, 
                //     tileDestRect, 
                //     .{.x = 0, .y = 0}, 
                //     0.0, 
                //     fg_color
                // );
            } else {
                if (visited_tiles.contains(point)) {
                    //const fg_color = tile.dark.fgColor;
                    const bg_color = tile.dark.bgColor;
                    rl.drawTexturePro(
                        tilesetTexture,
                        tileSrcRect,
                        tileDestRect,
                        .{.x = 0, .y = 0}, 
                        0.0, 
                        bg_color);
                    // rl.drawTexturePro(
                    //     tilesetTexture, 
                    //     tileSrcRect, 
                    //     tileDestRect,
                    //     .{.x = 0, .y = 0}, 
                    //     0.0, 
                    //     fg_color);
                }
            }
        }

        //----------------------------------------------------------------------------------
        visible_tiles.clearRetainingCapacity();
    }

    assets.deinit();
}