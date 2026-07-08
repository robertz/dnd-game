-- Multiclassing: a character can gain levels in more than one class, per
-- the "Multiclassing" rules. `characters.class_id`/`level` keep meaning
-- exactly what they mean today (the character's original class and its
-- level in it) — this only adds storage for every class *beyond* that one,
-- so a single-class character (still the overwhelming default) has zero
-- rows in the new table and every existing query is unaffected.
CREATE TABLE character_multiclass_levels (
    id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    character_id  INT UNSIGNED NOT NULL,
    class_id      INT UNSIGNED NOT NULL,
    subclass_id   INT UNSIGNED NULL,
    level         TINYINT UNSIGNED NOT NULL DEFAULT 1,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_character_multiclass_levels (character_id, class_id),
    CONSTRAINT fk_multiclass_levels_character FOREIGN KEY (character_id) REFERENCES characters (id) ON DELETE CASCADE,
    CONSTRAINT fk_multiclass_levels_class FOREIGN KEY (class_id) REFERENCES classes (id) ON DELETE CASCADE,
    CONSTRAINT fk_multiclass_levels_subclass FOREIGN KEY (subclass_id) REFERENCES subclasses (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Which class the next automatic level-up (see CombatService._levelUp(),
-- triggered by XP crossing a threshold mid-combat) applies to. NULL means
-- "the character's original class" (today's behavior, unchanged) — set via
-- CombatService.startMulticlass()/setNextLevelClass(), a revisitable
-- character-sheet action, never auto-assigned.
ALTER TABLE characters
    ADD COLUMN next_level_class_id INT UNSIGNED NULL,
    ADD CONSTRAINT fk_characters_next_level_class FOREIGN KEY (next_level_class_id) REFERENCES classes (id) ON DELETE SET NULL;
