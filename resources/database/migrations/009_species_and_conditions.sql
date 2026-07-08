-- Species (races/subraces) and conditions reference data.
-- Source: D&D 5e SRD 2014 JSON (dnd-5e-srd repo, json/01 races.json and
-- json/12 conditions.json), imported via resources/database/import_legacy_srd.py.
-- Note: this content is 2014-ruleset, unlike the 2024-ruleset data in
-- 001_srd_schema.sql (imported from dnd-5e-srd-markdown).

DROP TABLE IF EXISTS species_traits;
DROP TABLE IF EXISTS species;
DROP TABLE IF EXISTS conditions;

-- Ability bonuses, speed, darkvision, size, and languages are stored as the
-- discrete values character creation actually needs (mirroring how
-- `characters` stores str/dex/.../cha as columns rather than prose), not as
-- the SRD's descriptive sentences. `choice_ability_count`/`choice_ability_bonus`
-- capture "N other ability scores of your choice increase by M" (e.g.
-- Half-Elf: 2 abilities of the player's choice, +1 each) since that choice
-- is made at character-creation time and isn't a fixed ability. Flavor prose
-- (age, alignment tendencies, culture) that no game logic reads is kept
-- together in `description` rather than split into columns that only look
-- structured.
CREATE TABLE species (
    id                      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    parent_species_id       INT UNSIGNED NULL,
    name                    VARCHAR(100) NOT NULL,
    size                    VARCHAR(20),
    speed                   SMALLINT UNSIGNED,
    darkvision              SMALLINT UNSIGNED NULL,
    str_bonus               TINYINT NOT NULL DEFAULT 0,
    dex_bonus               TINYINT NOT NULL DEFAULT 0,
    con_bonus               TINYINT NOT NULL DEFAULT 0,
    int_bonus               TINYINT NOT NULL DEFAULT 0,
    wis_bonus               TINYINT NOT NULL DEFAULT 0,
    cha_bonus               TINYINT NOT NULL DEFAULT 0,
    choice_ability_count    TINYINT UNSIGNED NOT NULL DEFAULT 0,
    choice_ability_bonus    TINYINT UNSIGNED NOT NULL DEFAULT 0,
    languages               VARCHAR(255),
    bonus_language_choice   BOOLEAN NOT NULL DEFAULT FALSE,
    resistances             VARCHAR(255),
    description             LONGTEXT,
    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_species_name (name),
    CONSTRAINT fk_species_parent FOREIGN KEY (parent_species_id) REFERENCES species (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE species_traits (
    id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    species_id   INT UNSIGNED NOT NULL,
    sort_order   INT UNSIGNED NOT NULL,
    name         VARCHAR(150) NOT NULL,
    description  LONGTEXT,
    created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_species_traits_species FOREIGN KEY (species_id) REFERENCES species (id) ON DELETE CASCADE,
    INDEX idx_species_traits_species (species_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE conditions (
    id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    description  LONGTEXT,
    created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_conditions_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
