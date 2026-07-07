-- Structured (JSON-array) monster attack/trait data, as an alternative to
-- the markdown-text columns (actions_text, traits_text, etc.) that
-- CombatService.bx currently regex-parses at combat time. Each column holds
-- a JSONSerialize'd array of {name, desc, attackBonus, damageDice,
-- damageBonus} structs (attackBonus/damageDice/damageBonus are 0/"" when
-- not applicable, e.g. a non-attack trait). NULL for all 235 legacy rows —
-- CombatService.bx falls back to the existing regex parsing whenever a
-- row's *_json column is empty, so old and new data coexist.
--
-- legendary_actions_json/reactions_json are populated for monsters that
-- have them, but nothing in CombatService.bx reads them yet — no legendary
-- action economy or per-monster Reaction mechanic exists in the combat
-- engine today. Storing the data now means a future feature doesn't need
-- another import pass.
ALTER TABLE monsters
    ADD COLUMN actions_json            TEXT NULL,
    ADD COLUMN special_abilities_json  TEXT NULL,
    ADD COLUMN legendary_actions_json  TEXT NULL,
    ADD COLUMN reactions_json          TEXT NULL;
