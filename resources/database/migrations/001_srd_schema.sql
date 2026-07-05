-- SRD reference data schema: classes, feats, and magic items.
-- Source: D&D 5e SRD 5.2.1 Markdown (dnd-5e-srd-markdown), imported via
-- resources/database/import_srd.py. Safe to re-run: drops and recreates.

CREATE DATABASE IF NOT EXISTS gameserver CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE gameserver;

DROP TABLE IF EXISTS class_features;
DROP TABLE IF EXISTS subclasses;
DROP TABLE IF EXISTS classes;
DROP TABLE IF EXISTS feats;
DROP TABLE IF EXISTS magic_items;

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
