-- Rest-state persistence: track hit dice spent and remaining spell slots between
-- encounters so short/long rest mechanics have persistent effect across sessions.
ALTER TABLE characters
    ADD COLUMN hit_dice_spent    TINYINT UNSIGNED NOT NULL DEFAULT 0,
    ADD COLUMN spent_spell_slots VARCHAR(500)     NOT NULL DEFAULT '{}';
