-- Stores the player's chosen class skill proficiencies from character
-- creation (e.g. a Fighter's "Choose 2 of Acrobatics/Animal Handling/.../
-- Survival" per classes.skill_proficiencies), as a comma-separated list of
-- skill names. Background- and species-trait-granted skills aren't stored
-- here — those are re-derived on demand from `backgrounds`/`species_traits`
-- by name (see CombatService.resolveSkillProficiencies()), but a class's
-- skill choice is a player decision with no other record of it.
ALTER TABLE characters
    ADD COLUMN chosen_skill_proficiencies TEXT NULL;
