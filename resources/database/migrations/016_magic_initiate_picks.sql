-- Magic Initiate feat spell/cantrip picks: how many cantrips the character
-- still needs to choose (starts at 2 when the feat is granted, decrements on
-- each pick until 0) and whether the 1st-level spell pick is still pending.
ALTER TABLE characters
    ADD COLUMN pending_magic_initiate_cantrips INT NOT NULL DEFAULT 0,
    ADD COLUMN pending_magic_initiate_spell    TINYINT(1) NOT NULL DEFAULT 0;
