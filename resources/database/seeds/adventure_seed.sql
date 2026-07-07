-- Sample adventure module: a single 64x64 outdoor map ("Trade Road") to
-- exercise the chunked/RLE map storage in migration 005. Terrain: mountain
-- border along the top, a north-south river with a road bridging it at
-- row 32, and a forest patch in the bottom-right quadrant.
--
-- row_data lines are LF-separated RLE rows ("count:symbol,..."), one line
-- per grid row within the chunk, decoded against tile_legend by
-- MapService.bx's _decodeChunk()/_decodeRLE(). Chunk (chunk_x, chunk_y)
-- are 0-based; chunk_size 32 means chunk (0,0) covers map columns 1-32,
-- rows 1-32, chunk (1,0) covers columns 33-64, rows 1-32, etc.

USE gameserver;
SET NAMES utf8mb4;

INSERT INTO adventure_modules (slug, name, description, version)
VALUES (
    'lost-mines',
    'Lost Mines of the Trade Road',
    'A starter outdoor adventure: cross the river road to reach the bandit-held forest.',
    '1.0.0'
);
SET @module_id = LAST_INSERT_ID();

INSERT INTO adventure_maps (
    module_id, slug, name, width, height, chunk_size, tile_legend,
    player_spawn_x, player_spawn_y, opponent_spawn_x, opponent_spawn_y
) VALUES (
    @module_id, 'trade-road', 'The Trade Road', 64, 64, 32,
    '{"g":{"tile":"floor","decoration":"grass"},"r":{"tile":"floor","decoration":"road"},"w":{"tile":"wall","decoration":"water"},"m":{"tile":"wall","decoration":"mountain"},"t":{"tile":"wall","decoration":"forest"}}',
    10, 10, 36, 50
);
SET @map_id = LAST_INSERT_ID();

-- Chunk (0,0): map columns 1-32, rows 1-32. Mountain border (rows 1-2),
-- grass with the river's west bank (rows 3-31), road bridge (row 32).
INSERT INTO adventure_map_chunks (map_id, chunk_x, chunk_y, row_data) VALUES (
    @map_id, 0, 0,
    CONCAT_WS(CHAR(10),
        '32:m', '32:m',
        '29:g,3:w', '29:g,3:w', '29:g,3:w', '29:g,3:w', '29:g,3:w',
        '29:g,3:w', '29:g,3:w', '29:g,3:w', '29:g,3:w', '29:g,3:w',
        '29:g,3:w', '29:g,3:w', '29:g,3:w', '29:g,3:w', '29:g,3:w',
        '29:g,3:w', '29:g,3:w', '29:g,3:w', '29:g,3:w', '29:g,3:w',
        '29:g,3:w', '29:g,3:w', '29:g,3:w', '29:g,3:w', '29:g,3:w',
        '29:g,3:w', '29:g,3:w', '29:g,3:w', '29:g,3:w',
        '32:r'
    )
);

-- Chunk (1,0): map columns 33-64, rows 1-32. Mountain border, open grass
-- (east of the river), road bridge.
INSERT INTO adventure_map_chunks (map_id, chunk_x, chunk_y, row_data) VALUES (
    @map_id, 1, 0,
    CONCAT_WS(CHAR(10),
        '32:m', '32:m',
        '32:g', '32:g', '32:g', '32:g', '32:g',
        '32:g', '32:g', '32:g', '32:g', '32:g',
        '32:g', '32:g', '32:g', '32:g', '32:g',
        '32:g', '32:g', '32:g', '32:g', '32:g',
        '32:g', '32:g', '32:g', '32:g', '32:g',
        '32:g', '32:g', '32:g', '32:g',
        '32:r'
    )
);

-- Chunk (0,1): map columns 1-32, rows 33-64. Grass with the river's west
-- bank, unchanged all the way down (forest is entirely in chunk (1,1)).
INSERT INTO adventure_map_chunks (map_id, chunk_x, chunk_y, row_data) VALUES (
    @map_id, 0, 1,
    CONCAT_WS(CHAR(10),
        '29:g,3:w', '29:g,3:w', '29:g,3:w', '29:g,3:w', '29:g,3:w',
        '29:g,3:w', '29:g,3:w', '29:g,3:w', '29:g,3:w', '29:g,3:w',
        '29:g,3:w', '29:g,3:w', '29:g,3:w', '29:g,3:w', '29:g,3:w',
        '29:g,3:w', '29:g,3:w', '29:g,3:w', '29:g,3:w', '29:g,3:w',
        '29:g,3:w', '29:g,3:w', '29:g,3:w', '29:g,3:w', '29:g,3:w',
        '29:g,3:w', '29:g,3:w', '29:g,3:w', '29:g,3:w', '29:g,3:w',
        '29:g,3:w', '29:g,3:w'
    )
);

-- Chunk (1,1): map columns 33-64, rows 33-64. Open grass for 7 rows, then
-- the bandit forest fills the rest of the quadrant.
INSERT INTO adventure_map_chunks (map_id, chunk_x, chunk_y, row_data) VALUES (
    @map_id, 1, 1,
    CONCAT_WS(CHAR(10),
        '32:g', '32:g', '32:g', '32:g', '32:g', '32:g', '32:g',
        '7:g,25:t', '7:g,25:t', '7:g,25:t', '7:g,25:t', '7:g,25:t',
        '7:g,25:t', '7:g,25:t', '7:g,25:t', '7:g,25:t', '7:g,25:t',
        '7:g,25:t', '7:g,25:t', '7:g,25:t', '7:g,25:t', '7:g,25:t',
        '7:g,25:t', '7:g,25:t', '7:g,25:t', '7:g,25:t', '7:g,25:t'
    )
);

-- POI: bandit ambush encounter waiting in the forest.
INSERT INTO adventure_map_pois (map_id, x, y, poi_type, payload) VALUES (
    @map_id, 50, 50, 'encounter', '{"encounterId":"bandit_ambush"}'
);

-- POI: a small cache of loot near the player's spawn — picked up by
-- default.bx's _checkLoot() when the player walks onto (12, 10).
INSERT INTO adventure_map_pois (map_id, x, y, poi_type, payload) VALUES (
    @map_id, 12, 10, 'loot', '{"gold": 15, "items": [{"name": "Potion of Healing", "quantity": 1}]}'
);
