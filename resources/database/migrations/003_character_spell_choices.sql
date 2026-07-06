-- Lets a full-caster character's player-chosen cantrip and 1st-level spell
-- persist across sessions, instead of always being auto-picked fresh on
-- every loadCharacter() call. Both are nullable: non-caster classes (and
-- every character created before this migration) simply have no stored
-- choice, in which case CombatService._assignSpellcasting() falls back to
-- its existing auto-pick logic (ICONIC_CANTRIP_BY_CLASS / HEAL_PREFERRING_CLASSES),
-- so this is backward-compatible with the existing 13-character roster.
ALTER TABLE characters
    ADD COLUMN known_cantrip VARCHAR(100) NULL AFTER experience_points,
    ADD COLUMN known_spell   VARCHAR(100) NULL AFTER known_cantrip;
