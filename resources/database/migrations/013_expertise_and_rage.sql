-- Expertise (Rogue 1, Bard 2, Ranger 9): a comma list of skill names the
-- character has doubled their proficiency bonus for, chosen by the player
-- via CombatService.pendingExpertiseChoice()/chooseExpertise() — never
-- auto-assigned, per the standing "player always chooses" rule.
ALTER TABLE characters
    ADD COLUMN expertise_skills TEXT NULL;
