-- Adventure modules: packaged sets of maps a player can load after character
-- selection. Maps are stored chunked and RLE-encoded (see MapService.bx's
-- _encodeRLE/_decodeChunk) rather than as a flat tile grid, since outdoor
-- maps span far more tiles than the hand-authored dungeon levels and have
-- long same-terrain runs that RLE compresses heavily. Chunking (fixed-size
-- sub-grids referenced by chunk_x/chunk_y) lets a viewport read pull only
-- the chunks it overlaps instead of decoding an entire large map.

CREATE TABLE adventure_modules (
    id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    slug         VARCHAR(100)  NOT NULL,
    name         VARCHAR(150)  NOT NULL,
    description  TEXT,
    version      VARCHAR(20)   NOT NULL DEFAULT '1.0.0',
    created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_adventure_modules_slug (slug)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE adventure_maps (
    id                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    module_id         INT UNSIGNED NOT NULL,
    slug              VARCHAR(100)  NOT NULL,
    name              VARCHAR(150)  NOT NULL,
    width             INT UNSIGNED NOT NULL,
    height            INT UNSIGNED NOT NULL,
    chunk_size        INT UNSIGNED NOT NULL DEFAULT 32,
    tile_legend       TEXT NOT NULL,
    player_spawn_x    INT UNSIGNED NOT NULL,
    player_spawn_y    INT UNSIGNED NOT NULL,
    opponent_spawn_x  INT UNSIGNED NOT NULL,
    opponent_spawn_y  INT UNSIGNED NOT NULL,
    created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_module_map (module_id, slug),
    CONSTRAINT fk_maps_module FOREIGN KEY (module_id) REFERENCES adventure_modules (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- row_data holds one RLE-encoded row per line (LF-separated), each row a
-- comma-separated list of "count:symbol" tokens decoded against the owning
-- map's tile_legend. A chunk covers up to chunk_size x chunk_size tiles;
-- edge chunks on a map whose dimensions don't divide evenly are shorter/
-- narrower, not padded.
CREATE TABLE adventure_map_chunks (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    map_id      INT UNSIGNED NOT NULL,
    chunk_x     INT UNSIGNED NOT NULL,
    chunk_y     INT UNSIGNED NOT NULL,
    row_data    MEDIUMTEXT NOT NULL,
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_map_chunk (map_id, chunk_x, chunk_y),
    CONSTRAINT fk_chunks_map FOREIGN KEY (map_id) REFERENCES adventure_maps (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Points of interest: encounter triggers, loot, NPCs, map-to-map transitions.
-- Kept separate from the tile grid since these are sparse and queried by
-- position, not decoded wholesale with the terrain.
CREATE TABLE adventure_map_pois (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    map_id      INT UNSIGNED NOT NULL,
    x           INT UNSIGNED NOT NULL,
    y           INT UNSIGNED NOT NULL,
    poi_type    VARCHAR(50) NOT NULL,
    payload     TEXT,
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pois_map FOREIGN KEY (map_id) REFERENCES adventure_maps (id) ON DELETE CASCADE,
    INDEX idx_pois_map_xy (map_id, x, y)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
