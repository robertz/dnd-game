-- Character backgrounds, per D&D 5e SRD 2014 JSON (dnd-5e-srd repo,
-- json/03 beyond1st.json -> "Beyond 1st Level" -> "Backgrounds"), imported
-- via resources/database/import_legacy_srd.py. The 2014 SRD only carries one
-- sample background (Acolyte, under Wizards' OGL); the table is shaped to
-- hold more if the source ever adds them.
--
-- Columns mirror the same "extract what character creation needs" shape as
-- 001_srd_schema.sql's `classes` table: skill_proficiencies/tool_proficiencies
-- as short comma lists, feature_name/feature_description as the one
-- mechanical (or story) benefit a background grants, bonus_language_count as
-- the number of free player-chosen languages. Roleplaying-only content
-- (Suggested Characteristics tables of personality traits/ideals/bonds/flaws)
-- isn't imported — nothing in character creation or combat reads it.
DROP TABLE IF EXISTS backgrounds;

CREATE TABLE backgrounds (
    id                     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name                   VARCHAR(100) NOT NULL,
    description            LONGTEXT,
    skill_proficiencies    VARCHAR(255),
    tool_proficiencies     VARCHAR(255),
    bonus_language_count   TINYINT UNSIGNED NOT NULL DEFAULT 0,
    equipment_text         TEXT,
    feature_name           VARCHAR(150),
    feature_description    LONGTEXT,
    created_at             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_backgrounds_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
