-- Equipable armor and general (non-weapon) inventory items, plus a gold
-- currency column. Mirrors the weapons/character_inventory shape already
-- established in 001_srd_schema.sql: a reference table (armors/items) plus
-- a per-character join table with an "equipped"/"quantity" column.

CREATE TABLE armors (
    id                    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name                  VARCHAR(100) NOT NULL,
    -- 'light' | 'medium' | 'heavy' | 'shield'
    armor_type            VARCHAR(20)  NOT NULL,
    base_ac               TINYINT UNSIGNED NOT NULL,
    -- NULL = no cap (light armor adds full Dex mod); 2 = medium's cap;
    -- 0 = heavy armor ignores Dex entirely. Unused/irrelevant for shields
    -- (a shield's base_ac IS its flat AC bonus, added on top of body armor).
    max_dex_bonus         TINYINT NULL,
    strength_requirement  TINYINT UNSIGNED NULL,
    stealth_disadvantage  BOOLEAN NOT NULL DEFAULT FALSE,
    weight                VARCHAR(20),
    cost                  VARCHAR(20),
    created_at            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_armors_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Body armor (light/medium/heavy) and shields are independent equip slots —
-- see CharacterService.bx's setArmorEquipped() for the "only one of each
-- slot equipped at a time" rule, enforced in application code rather than
-- here since a shield and a body armor coexist but two body armors don't.
CREATE TABLE character_armor (
    id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    character_id  INT UNSIGNED NOT NULL,
    armor_id      INT UNSIGNED NOT NULL,
    equipped      BOOLEAN NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_character_armor (character_id, armor_id),
    CONSTRAINT fk_character_armor_character FOREIGN KEY (character_id) REFERENCES characters (id) ON DELETE CASCADE,
    CONSTRAINT fk_character_armor_armor FOREIGN KEY (armor_id) REFERENCES armors (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- General non-weapon, non-armor inventory: potions, treasure, and misc gear.
CREATE TABLE items (
    id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    -- 'consumable' | 'treasure' | 'misc'
    item_type    VARCHAR(20) NOT NULL,
    description  TEXT,
    weight       VARCHAR(20),
    cost         VARCHAR(20),
    created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_items_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE character_items (
    id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    character_id  INT UNSIGNED NOT NULL,
    item_id       INT UNSIGNED NOT NULL,
    quantity      SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_character_item (character_id, item_id),
    CONSTRAINT fk_character_items_character FOREIGN KEY (character_id) REFERENCES characters (id) ON DELETE CASCADE,
    CONSTRAINT fk_character_items_item FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE characters ADD COLUMN gold INT UNSIGNED NOT NULL DEFAULT 0;
