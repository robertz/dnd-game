-- Adds a structured mechanics layer on top of `spells`' free-text
-- `description`/`higher_level_text` columns, so CombatService (or any future
-- code) can look up "does this spell have a damage roll, a save, a heal" by
-- column instead of re-parsing prose every time. Populated by
-- resources/database/extract_spell_mechanics.py, which parses every spell's
-- description with regexes and fills in whatever it can confidently detect.
--
-- Most of the SRD's 312 spells are pure utility/effect text (teleportation,
-- illusions, buffs, forced movement, etc.) with no single damage/save/heal
-- roll to extract — those are left as effect_type = 'utility' with the rest
-- of the columns NULL. That's not a parsing failure; it's an accurate
-- reflection of spells this simple column set can't (and, for a lot of them,
-- shouldn't try to) fully mechanize.

ALTER TABLE spells
    ADD COLUMN effect_type  ENUM('attack', 'save', 'heal', 'utility') NOT NULL DEFAULT 'utility' AFTER higher_level_text,
    ADD COLUMN attack_type  ENUM('melee', 'ranged')                   NULL     AFTER effect_type,
    ADD COLUMN save_ability ENUM('str', 'dex', 'con', 'int', 'wis', 'cha') NULL AFTER attack_type,
    ADD COLUMN save_effect  ENUM('half', 'none')                      NULL     AFTER save_ability,
    ADD COLUMN damage_dice  VARCHAR(20)                                NULL     AFTER save_effect,
    ADD COLUMN damage_type  VARCHAR(50)                                NULL     AFTER damage_dice,
    ADD COLUMN heal_dice    VARCHAR(20)                                NULL     AFTER damage_type,
    ADD INDEX idx_spells_effect_type (effect_type);
