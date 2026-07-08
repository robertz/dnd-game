-- Replaces the single knownCantrip/knownSpell fields with comma-separated
-- lists, so a caster can know more than one cantrip/leveled spell as they
-- level up (see CombatService.pendingCantripChoice()/pendingSpellChoices()
-- and CharacterService.learnCantrip()/learnSpell()). A character's starting
-- single choice from character creation still lands in these columns —
-- character creation itself is unchanged (a level 1 character only knows 1
-- of each either way).
ALTER TABLE characters
    ADD COLUMN known_cantrips TEXT NULL,
    ADD COLUMN known_spells   TEXT NULL;

UPDATE characters SET known_cantrips = known_cantrip WHERE known_cantrip IS NOT NULL;
UPDATE characters SET known_spells   = known_spell   WHERE known_spell   IS NOT NULL;

ALTER TABLE characters
    DROP COLUMN known_cantrip,
    DROP COLUMN known_spell;
