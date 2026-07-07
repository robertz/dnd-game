-- SRD reference data schema: classes, feats, magic items, monsters, spells, and weapons.
-- Source: D&D 5e SRD 5.2.1 Markdown (dnd-5e-srd-markdown), imported via
-- resources/database/import_srd.py. Safe to re-run: drops and recreates.

CREATE DATABASE IF NOT EXISTS gameserver CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE gameserver;

DROP TABLE IF EXISTS character_inventory;
DROP TABLE IF EXISTS character_features;
DROP TABLE IF EXISTS character_feats;
DROP TABLE IF EXISTS characters;
DROP TABLE IF EXISTS class_features;
DROP TABLE IF EXISTS subclasses;
DROP TABLE IF EXISTS classes;
DROP TABLE IF EXISTS feats;
DROP TABLE IF EXISTS magic_items;
DROP TABLE IF EXISTS monsters;
DROP TABLE IF EXISTS spells;
DROP TABLE IF EXISTS weapons;

CREATE TABLE classes (
    id                          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name                        VARCHAR(100)  NOT NULL,
    primary_ability             VARCHAR(255),
    hit_die                     VARCHAR(50),
    saving_throw_proficiencies  VARCHAR(255),
    skill_proficiencies         TEXT,
    weapon_proficiencies        VARCHAR(255),
    tool_proficiencies          VARCHAR(255),
    armor_training               VARCHAR(255),
    starting_equipment          TEXT,
    becoming_text               LONGTEXT,
    created_at                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_classes_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE subclasses (
    id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    class_id     INT UNSIGNED NOT NULL,
    name         VARCHAR(150) NOT NULL,
    tagline      VARCHAR(255),
    description  LONGTEXT,
    created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_class_subclass (class_id, name),
    CONSTRAINT fk_subclasses_class FOREIGN KEY (class_id) REFERENCES classes (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE class_features (
    id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    class_id     INT UNSIGNED NOT NULL,
    subclass_id  INT UNSIGNED NULL,
    level        TINYINT UNSIGNED NOT NULL,
    sort_order   INT UNSIGNED NOT NULL,
    name         VARCHAR(150) NOT NULL,
    description  LONGTEXT,
    created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_features_class FOREIGN KEY (class_id) REFERENCES classes (id) ON DELETE CASCADE,
    CONSTRAINT fk_features_subclass FOREIGN KEY (subclass_id) REFERENCES subclasses (id) ON DELETE CASCADE,
    INDEX idx_features_class_level (class_id, level)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE feats (
    id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name             VARCHAR(150) NOT NULL,
    category         VARCHAR(50)  NOT NULL,
    prerequisite     VARCHAR(255),
    repeatable       BOOLEAN NOT NULL DEFAULT FALSE,
    repeatable_text  TEXT,
    description      LONGTEXT,
    created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_feats_name (name),
    INDEX idx_feats_category (category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE magic_items (
    id                       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name                     VARCHAR(150) NOT NULL,
    category                 VARCHAR(50)  NOT NULL,
    category_detail          VARCHAR(255),
    rarity                   VARCHAR(255),
    requires_attunement      BOOLEAN NOT NULL DEFAULT FALSE,
    attunement_requirement   VARCHAR(255),
    description              LONGTEXT,
    created_at               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_magic_items_name (name),
    INDEX idx_magic_items_category (category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE monsters (
    id                      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    group_name              VARCHAR(150) NOT NULL,
    name                    VARCHAR(150) NOT NULL,
    size                    VARCHAR(50),
    creature_type           VARCHAR(150),
    alignment               VARCHAR(100),
    armor_class             TINYINT UNSIGNED,
    initiative_modifier     TINYINT,
    initiative_score        TINYINT,
    hit_points              SMALLINT UNSIGNED,
    hit_dice                VARCHAR(50),
    speed                   VARCHAR(200),
    str                     TINYINT,
    dex                     TINYINT,
    con                     TINYINT,
    int_score               TINYINT,
    wis                     TINYINT,
    cha                     TINYINT,
    str_save                TINYINT,
    dex_save                TINYINT,
    con_save                TINYINT,
    int_save                TINYINT,
    wis_save                TINYINT,
    cha_save                TINYINT,
    skills                  TEXT,
    resistances             TEXT,
    immunities              TEXT,
    vulnerabilities         TEXT,
    gear                    TEXT,
    senses                  TEXT,
    languages               TEXT,
    cr                      VARCHAR(20),
    xp                      INT UNSIGNED,
    proficiency_bonus       TINYINT,
    traits_text             LONGTEXT,
    actions_text            LONGTEXT,
    bonus_actions_text      LONGTEXT,
    reactions_text          LONGTEXT,
    legendary_actions_text  LONGTEXT,
    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_monsters_name (name),
    INDEX idx_monsters_group (group_name),
    INDEX idx_monsters_cr (cr)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE spells (
    id                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name              VARCHAR(150) NOT NULL,
    level             TINYINT UNSIGNED NOT NULL,
    school            VARCHAR(100),
    classes           VARCHAR(255),
    casting_time      VARCHAR(255),
    `range`           VARCHAR(100),
    components        VARCHAR(255),
    duration          VARCHAR(255),
    description       LONGTEXT,
    higher_level_text TEXT,
    created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_spells_name (name),
    INDEX idx_spells_level (level),
    INDEX idx_spells_school (school)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE weapons (
    id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    category     VARCHAR(20)  NOT NULL,
    weapon_type  VARCHAR(10)  NOT NULL,
    damage       VARCHAR(50),
    damage_dice  VARCHAR(20),
    damage_type  VARCHAR(50),
    properties   TEXT,
    mastery      VARCHAR(50),
    weight       VARCHAR(20),
    cost         VARCHAR(20),
    created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_weapons_name (name),
    INDEX idx_weapons_category (category, weapon_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Saved player characters, plus their gained class features and carried
-- weapons. Ability scores, proficiency bonus, AC, and HP are stored as the
-- app already computes them (e.g. Unarmored Defense AC), rather than
-- re-derived from the rules in SQL. Combat/session state (grid position,
-- turn order) is intentionally NOT here — that belongs to a future
-- encounter/session table, not the character sheet itself.
CREATE TABLE characters (
    id                 INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name               VARCHAR(100) NOT NULL,
    class_id           INT UNSIGNED NOT NULL,
    subclass_id        INT UNSIGNED NULL,
    -- Flavor choices from Character Creation Step 2 (Origin) and Step 4
    -- (Alignment). Not mechanically modeled (no feat/skill grants from
    -- background, no species traits) — just recorded on the sheet.
    species            VARCHAR(50) NULL,
    background         VARCHAR(50) NULL,
    alignment          VARCHAR(50) NULL,
    level              TINYINT UNSIGNED NOT NULL DEFAULT 1,
    str                TINYINT UNSIGNED NOT NULL,
    dex                TINYINT UNSIGNED NOT NULL,
    con                TINYINT UNSIGNED NOT NULL,
    int_score          TINYINT UNSIGNED NOT NULL,
    wis                TINYINT UNSIGNED NOT NULL,
    cha                TINYINT UNSIGNED NOT NULL,
    proficiency_bonus  TINYINT UNSIGNED NOT NULL,
    armor_class        TINYINT UNSIGNED NOT NULL,
    hit_points         SMALLINT NOT NULL,
    max_hit_points     SMALLINT UNSIGNED NOT NULL,
    speed              SMALLINT UNSIGNED NOT NULL DEFAULT 30,
    experience_points  INT UNSIGNED NOT NULL DEFAULT 0,
    created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_characters_class FOREIGN KEY (class_id) REFERENCES classes (id) ON DELETE CASCADE,
    CONSTRAINT fk_characters_subclass FOREIGN KEY (subclass_id) REFERENCES subclasses (id) ON DELETE SET NULL,
    INDEX idx_characters_class (class_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Which class/subclass features (from the SRD rule set) a character has gained.
CREATE TABLE character_features (
    id                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    character_id      INT UNSIGNED NOT NULL,
    class_feature_id  INT UNSIGNED NOT NULL,
    created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_character_feature (character_id, class_feature_id),
    CONSTRAINT fk_character_features_character FOREIGN KEY (character_id) REFERENCES characters (id) ON DELETE CASCADE,
    CONSTRAINT fk_character_features_feature FOREIGN KEY (class_feature_id) REFERENCES class_features (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Feats a character has (currently just the one granted automatically by
-- their chosen background, per Character Creation Step 2).
CREATE TABLE character_feats (
    id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    character_id  INT UNSIGNED NOT NULL,
    feat_id       INT UNSIGNED NOT NULL,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_character_feat (character_id, feat_id),
    CONSTRAINT fk_character_feats_character FOREIGN KEY (character_id) REFERENCES characters (id) ON DELETE CASCADE,
    CONSTRAINT fk_character_feats_feat FOREIGN KEY (feat_id) REFERENCES feats (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Weapons a character carries. attack_bonus/damage_bonus are the character's
-- computed totals (ability modifier + proficiency, if proficient) for that
-- weapon, since those depend on the character, not the weapon itself.
-- category is how the character has this weapon equipped for combat purposes
-- ("melee" or "ranged") — kept separate from weapons.weapon_type because a
-- Thrown weapon (e.g. Javelin, weapon_type "Melee") can still be equipped as
-- a character's ranged option.
CREATE TABLE character_inventory (
    id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    character_id   INT UNSIGNED NOT NULL,
    weapon_id      INT UNSIGNED NOT NULL,
    category       VARCHAR(10) NOT NULL,
    equipped       BOOLEAN NOT NULL DEFAULT FALSE,
    quantity       SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    attack_bonus   TINYINT,
    damage_bonus   TINYINT,
    created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_character_weapon (character_id, weapon_id),
    CONSTRAINT fk_character_inventory_character FOREIGN KEY (character_id) REFERENCES characters (id) ON DELETE CASCADE,
    CONSTRAINT fk_character_inventory_weapon FOREIGN KEY (weapon_id) REFERENCES weapons (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
