-- Designates one map per module as its entry point — the map the
-- module/map picker (moduleSelect.bx) sends the player straight into.
-- Other maps in a module are only reached by walking through an in-game
-- transition (adventure_map_pois, poi_type "transition"), not picked
-- directly from that menu.
ALTER TABLE adventure_maps
    ADD COLUMN is_entry TINYINT(1) NOT NULL DEFAULT 0;

-- Backfill: mark each existing module's first-created map (lowest id) as
-- its entry point, so already-seeded modules (e.g. lost-mines) keep
-- working without manual intervention.
UPDATE adventure_maps m
INNER JOIN (
    SELECT module_id, MIN(id) AS first_id FROM adventure_maps GROUP BY module_id
) first_map ON first_map.module_id = m.module_id AND first_map.first_id = m.id
SET m.is_entry = 1;
