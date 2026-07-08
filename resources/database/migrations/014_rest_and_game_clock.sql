-- Wires Short Rest/Long Rest to a real elapsed-time model instead of being
-- freely repeatable with no cost: each combat round advances a persisted
-- in-game clock by 6 seconds (the SRD's "a round is about 6 seconds" rule),
-- a Short Rest advances it by 1 hour, and a Long Rest by 8 hours — gated to
-- once per 24 in-game hours, per the "A character can't benefit from more
-- than one long rest in a 24-hour period" rule.
--
-- Also moves several previously "resets every encounter" resources onto
-- the real Short/Long Rest recharge rules instead: Second Wind and one Rage
-- use recover on a Short Rest (all Rage uses on a Long Rest); Breath Weapon,
-- Relentless Endurance, Heroic Inspiration, and Magic Initiate's bonus spell
-- only recover on a Long Rest.
ALTER TABLE characters
    ADD COLUMN game_clock_seconds BIGINT UNSIGNED NOT NULL DEFAULT 0,
    ADD COLUMN last_long_rest_seconds BIGINT UNSIGNED NULL,
    ADD COLUMN rages_used INT UNSIGNED NOT NULL DEFAULT 0,
    ADD COLUMN used_second_wind TINYINT(1) NOT NULL DEFAULT 0,
    ADD COLUMN used_breath_weapon TINYINT(1) NOT NULL DEFAULT 0,
    ADD COLUMN used_relentless_endurance TINYINT(1) NOT NULL DEFAULT 0,
    ADD COLUMN used_heroic_inspiration TINYINT(1) NOT NULL DEFAULT 0,
    ADD COLUMN used_magic_initiate_spell TINYINT(1) NOT NULL DEFAULT 0;
