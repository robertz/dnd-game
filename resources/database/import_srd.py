#!/usr/bin/env python3
"""
Parses classes.md, feats.md, magic-items.md, monsters-A-Z.md, spells.md, and
equipment.md from the dnd-5e-srd-markdown repo and emits a SQL seed file for
the `gameserver` MySQL schema defined in
resources/database/migrations/001_srd_schema.sql.

Usage:
    python3 import_srd.py [--srd-path /path/to/dnd-5e-srd-markdown] [--out seeds/srd_seed.sql]
    mysql -uroot gameserver < resources/database/seeds/srd_seed.sql
"""

import argparse
import re
from pathlib import Path

DEFAULT_SRD_PATH = Path(__file__).resolve().parents[2].parent / "dnd-5e-srd-markdown"
DEFAULT_OUT = Path(__file__).resolve().parent / "seeds" / "srd_seed.sql"


def sql_escape(value):
    if value is None:
        return "NULL"
    return "'" + str(value).replace("\\", "\\\\").replace("'", "\\'") + "'"


def sql_bool(value):
    return "1" if value else "0"


def clean_inline(text):
    """Strip markdown emphasis and stray whitespace from a short inline value."""
    if text is None:
        return None
    text = text.strip()
    text = re.sub(r"\*\*(.+?)\*\*", r"\1", text)
    text = re.sub(r"_(.+?)_", r"\1", text)
    text = re.sub(r"\s+", " ", text)
    return text.strip() or None


def clean_block(text):
    """Trim a multi-paragraph markdown block, keeping its own formatting intact."""
    if text is None:
        return None
    return text.strip("\n ").rstrip() or None


def split_sections(text, heading_prefix):
    """
    Split `text` on lines that start with `heading_prefix` (e.g. '## ' or '#### ').
    Returns a list of (heading_text, body) tuples. Content before the first
    matching heading is returned as a leading ("", body) tuple.
    """
    pattern = re.compile(r"^" + re.escape(heading_prefix) + r"(.+)$", re.MULTILINE)
    matches = list(pattern.finditer(text))
    sections = []
    if not matches:
        return [("", text)]
    if matches[0].start() > 0:
        sections.append(("", text[: matches[0].start()]))
    for i, m in enumerate(matches):
        end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        sections.append((m.group(1).strip(), text[m.end():end]))
    return sections


# --------------------------------------------------------------------------
# Classes
# --------------------------------------------------------------------------

TRAIT_KEY_MAP = {
    "primary ability": "primary_ability",
    "hit point die": "hit_die",
    "saving throw proficiencies": "saving_throw_proficiencies",
    "skill proficiencies": "skill_proficiencies",
    "weapon proficiencies": "weapon_proficiencies",
    "tool proficiencies": "tool_proficiencies",
    "armor training": "armor_training",
    "starting equipment": "starting_equipment",
}


def parse_traits_table(text):
    """Parse the '<table><tbody><tr><td>Key</td><td>Value</td></tr>...' core traits table."""
    fields = {v: None for v in TRAIT_KEY_MAP.values()}
    table_match = re.search(r"<table>.*?</table>", text, re.DOTALL)
    if not table_match:
        return fields
    rows = re.findall(r"<tr>\s*<td>(.*?)</td>\s*<td>(.*?)</td>\s*</tr>", table_match.group(0), re.DOTALL)
    for key, value in rows:
        key_norm = clean_inline(re.sub(r"<.*?>", "", key)).lower()
        col = TRAIT_KEY_MAP.get(key_norm)
        if col:
            fields[col] = clean_inline(re.sub(r"<.*?>", "", value))
    return fields


LEVEL_FEATURE_RE = re.compile(r"^Level (\d+):\s*(.+)$")


def parse_features(text):
    """Split a 'Class Features' or 'Subclass' body into (level, name, description) tuples."""
    features = []
    for heading, body in split_sections(text, "#### "):
        m = LEVEL_FEATURE_RE.match(heading)
        if not m:
            continue
        level = int(m.group(1))
        name = clean_inline(m.group(2))
        features.append((level, name, clean_block(body)))
    return features


def parse_classes(srd_path):
    raw = (srd_path / "classes.md").read_text(encoding="utf-8")
    classes = []

    for class_name, class_body in split_sections(raw, "## "):
        if not class_name:
            continue

        subsections = split_sections(class_body, "### ")
        leading = subsections[0][1] if subsections and subsections[0][0] == "" else ""
        traits = parse_traits_table(leading)

        becoming_text = None
        features = []
        subclass = None  # (name, tagline, description, features)

        for heading, body in subsections:
            if heading.startswith("Becoming a"):
                becoming_text = clean_block(body)
            elif heading.endswith("Class Features"):
                features = parse_features(body)
            elif heading.endswith("Spell List"):
                continue  # spells are out of scope for this import
            elif "Subclass:" in heading:
                subclass_name = clean_inline(heading.split("Subclass:", 1)[1])
                sub_sections = split_sections(body, "#### ")
                intro = sub_sections[0][1] if sub_sections[0][0] == "" else ""
                tagline_match = re.search(r"_(.+?)_", intro)
                tagline = clean_inline(tagline_match.group(1)) if tagline_match else None
                intro_wo_tagline = intro
                if tagline_match:
                    intro_wo_tagline = intro[tagline_match.end():]
                sub_features = parse_features(body)
                subclass = {
                    "name": subclass_name,
                    "tagline": tagline,
                    "description": clean_block(intro_wo_tagline),
                    "features": sub_features,
                }

        classes.append(
            {
                "name": clean_inline(class_name),
                "traits": traits,
                "becoming_text": becoming_text,
                "features": features,
                "subclass": subclass,
            }
        )

    return classes


def emit_classes_sql(classes, out):
    out.write("\n-- classes ------------------------------------------------------------\n")
    for cls in classes:
        t = cls["traits"]
        out.write(
            "INSERT INTO classes "
            "(name, primary_ability, hit_die, saving_throw_proficiencies, skill_proficiencies, "
            "weapon_proficiencies, tool_proficiencies, armor_training, starting_equipment, becoming_text) VALUES "
            f"({sql_escape(cls['name'])}, {sql_escape(t['primary_ability'])}, {sql_escape(t['hit_die'])}, "
            f"{sql_escape(t['saving_throw_proficiencies'])}, {sql_escape(t['skill_proficiencies'])}, "
            f"{sql_escape(t['weapon_proficiencies'])}, {sql_escape(t['tool_proficiencies'])}, "
            f"{sql_escape(t['armor_training'])}, {sql_escape(t['starting_equipment'])}, "
            f"{sql_escape(cls['becoming_text'])});\n"
        )
        out.write(f"SET @class_id = LAST_INSERT_ID();\n")

        sort_order = 0
        for level, name, description in cls["features"]:
            sort_order += 1
            out.write(
                "INSERT INTO class_features (class_id, subclass_id, level, sort_order, name, description) VALUES "
                f"(@class_id, NULL, {level}, {sort_order}, {sql_escape(name)}, {sql_escape(description)});\n"
            )

        sub = cls["subclass"]
        if sub:
            out.write(
                "INSERT INTO subclasses (class_id, name, tagline, description) VALUES "
                f"(@class_id, {sql_escape(sub['name'])}, {sql_escape(sub['tagline'])}, {sql_escape(sub['description'])});\n"
            )
            out.write("SET @subclass_id = LAST_INSERT_ID();\n")
            sort_order = 0
            for level, name, description in sub["features"]:
                sort_order += 1
                out.write(
                    "INSERT INTO class_features (class_id, subclass_id, level, sort_order, name, description) VALUES "
                    f"(@class_id, @subclass_id, {level}, {sort_order}, {sql_escape(name)}, {sql_escape(description)});\n"
                )


# --------------------------------------------------------------------------
# Feats
# --------------------------------------------------------------------------

FEAT_SUBTITLE_RE = re.compile(r"_(.+?) Feat(?:\s*\(Prerequisite:\s*(.+?)\))?_")


def parse_feats(srd_path):
    raw = (srd_path / "feats.md").read_text(encoding="utf-8")
    feats = []

    for heading, body in split_sections(raw, "### "):
        if not heading.endswith("Feats") or heading in ("Feat Descriptions",):
            continue
        category = clean_inline(heading[: -len(" Feats")])

        for feat_name, feat_body in split_sections(body, "#### "):
            if not feat_name:
                continue
            m = FEAT_SUBTITLE_RE.search(feat_body)
            prerequisite = clean_inline(m.group(2)) if m and m.group(2) else None

            repeatable = bool(re.search(r"_Repeatable\._", feat_body))
            repeatable_text = None
            rep_match = re.search(r"_Repeatable\._\s*(.+?)(?:\n\n|\Z)", feat_body, re.DOTALL)
            if rep_match:
                repeatable_text = clean_block(rep_match.group(1))

            description = feat_body
            if m:
                description = feat_body[m.end():]
            description = clean_block(description)

            feats.append(
                {
                    "name": clean_inline(feat_name),
                    "category": category,
                    "prerequisite": prerequisite,
                    "repeatable": repeatable,
                    "repeatable_text": repeatable_text,
                    "description": description,
                }
            )

    return feats


def emit_feats_sql(feats, out):
    out.write("\n-- feats ----------------------------------------------------------------\n")
    for feat in feats:
        out.write(
            "INSERT INTO feats (name, category, prerequisite, repeatable, repeatable_text, description) VALUES "
            f"({sql_escape(feat['name'])}, {sql_escape(feat['category'])}, {sql_escape(feat['prerequisite'])}, "
            f"{sql_bool(feat['repeatable'])}, {sql_escape(feat['repeatable_text'])}, {sql_escape(feat['description'])});\n"
        )


# --------------------------------------------------------------------------
# Magic items
# --------------------------------------------------------------------------

ITEM_SUBTITLE_RE = re.compile(r"^_(.+)_\s*$", re.MULTILINE)

# Category may itself contain a comma inside its own parenthetical, e.g.
# "Armor (Any Medium or Heavy, Except Hide Armor), Uncommon", so the split
# between category/detail and rarity can't just be the first top-level comma.
ITEM_CATEGORY_RE = re.compile(r"^(?P<category>[^(]+?)(?:\s*\((?P<detail>[^()]*)\))?\s*,\s*(?P<rarity>.+)$")


def parse_item_subtitle(subtitle):
    # e.g. "Armor (Any Medium or Heavy, Except Hide Armor), Uncommon"
    # e.g. "Wondrous Item, Rare (Requires Attunement by a Spellcaster)"
    m = ITEM_CATEGORY_RE.match(subtitle.strip())
    if m:
        category = clean_inline(m.group("category"))
        category_detail = clean_inline(m.group("detail"))
        rarity = clean_inline(m.group("rarity"))
    else:
        category = clean_inline(subtitle)
        category_detail = None
        rarity = None

    requires_attunement = bool(rarity and re.search(r"Requires Attunement", rarity, re.IGNORECASE))
    attunement_requirement = None
    if requires_attunement:
        att_match = re.search(r"Requires Attunement(?:\s+(by\s+.+?))?\)", rarity, re.IGNORECASE)
        if att_match and att_match.group(1):
            attunement_requirement = clean_inline(att_match.group(1))

    return category, category_detail, rarity, requires_attunement, attunement_requirement


RARITY_KEYWORDS_RE = re.compile(r"\b(common|uncommon|rare|legendary|artifact|varies)\b", re.IGNORECASE)


def parse_magic_items(srd_path):
    raw = (srd_path / "magic-items.md").read_text(encoding="utf-8")
    az_marker = "## Magic Items A"
    idx = raw.find(az_marker)
    if idx == -1:
        raise RuntimeError("Could not find 'Magic Items A-Z' section in magic-items.md")
    az_text = raw[idx:]

    items = []
    for item_name, item_body in split_sections(az_text, "#### "):
        if not item_name:
            continue

        subtitle_match = ITEM_SUBTITLE_RE.search(item_body)
        if not subtitle_match:
            continue
        category, category_detail, rarity, requires_attunement, attunement_requirement = parse_item_subtitle(
            subtitle_match.group(1)
        )

        # A handful of items (e.g. Figurine of Wondrous Power, Deck of Many Things)
        # embed a full nested creature stat block ("#### Name" / "_Size Type,
        # Alignment_") that isn't a real magic item entry. Its subtitle won't
        # contain a recognized rarity word, so fold it into the previous
        # item's description instead of creating a bogus row.
        if not rarity or not RARITY_KEYWORDS_RE.search(rarity):
            if items:
                items[-1]["description"] = clean_block(
                    (items[-1]["description"] or "") + f"\n\n#### {item_name}\n" + item_body
                )
            continue

        description = clean_block(item_body[subtitle_match.end():])

        items.append(
            {
                "name": clean_inline(item_name),
                "category": category,
                "category_detail": category_detail,
                "rarity": rarity,
                "requires_attunement": requires_attunement,
                "attunement_requirement": attunement_requirement,
                "description": description,
            }
        )

    return items


def emit_magic_items_sql(items, out):
    out.write("\n-- magic items -----------------------------------------------------------\n")
    for item in items:
        out.write(
            "INSERT INTO magic_items "
            "(name, category, category_detail, rarity, requires_attunement, attunement_requirement, description) VALUES "
            f"({sql_escape(item['name'])}, {sql_escape(item['category'])}, {sql_escape(item['category_detail'])}, "
            f"{sql_escape(item['rarity'])}, {sql_bool(item['requires_attunement'])}, "
            f"{sql_escape(item['attunement_requirement'])}, {sql_escape(item['description'])});\n"
        )


# --------------------------------------------------------------------------
# Monsters
# --------------------------------------------------------------------------

# Unicode minus (U+2212) is used in the SRD stat tables; normalize to ASCII.
def parse_signed_int(text):
    """Convert '+5', '−2', '+0', '−0' etc. to a Python int."""
    if text is None:
        return None
    text = text.strip().replace("−", "-").replace("−", "-")
    try:
        return int(text)
    except ValueError:
        return None


MONSTER_AC_RE = re.compile(r"\*\*AC\*\*\s+(\d+).*?\*\*Initiative\*\*\s+([+\-−–]\d+)\s+\((\d+)\)")
MONSTER_HP_RE = re.compile(r"\*\*HP\*\*\s+(\d+)\s+\(([^)]+)\)")
MONSTER_SPEED_RE = re.compile(r"\*\*Speed\*\*\s+(.+?)(?:\s*<br>|$)", re.MULTILINE)
MONSTER_CR_RE = re.compile(r"\*\*CR\*\*\s+(\S+)\s+\(XP\s+([\d,]+).*?PB\s+\+(\d+)\)", re.IGNORECASE)
MONSTER_BOLD_RE = re.compile(r"^\*\*(\w[\w\s]*?)\*\*\s+(.+?)(?:<br>|$)", re.MULTILINE)

ABILITY_ORDER = ["str", "dex", "con", "int_score", "wis", "cha"]


def parse_ability_table(text):
    """Extract ability scores and saves from the stat block HTML table."""
    table_m = re.search(r"<table>.*?</table>", text, re.DOTALL)
    if not table_m:
        return {}
    cells = re.findall(r"<td>(.*?)</td>", table_m.group(0), re.DOTALL)
    # Each ability occupies 4 cells: label, score, mod, save. There are 6 abilities.
    # The label cells contain <strong>STR</strong> etc.
    result = {}
    ability_cells = [c.strip() for c in cells]
    # Strip HTML tags from labels to get raw content, then group by 4
    i = 0
    ability_idx = 0
    while i + 3 < len(ability_cells) and ability_idx < 6:
        label = re.sub(r"<.*?>", "", ability_cells[i]).strip()
        score_text = re.sub(r"<.*?>", "", ability_cells[i + 1]).strip()
        save_text = re.sub(r"<.*?>", "", ability_cells[i + 3]).strip()
        if label.upper() in ("STR", "DEX", "CON", "INT", "WIS", "CHA"):
            key = ABILITY_ORDER[ability_idx]
            save_key = key.replace("_score", "") + "_save"
            try:
                result[key] = int(score_text)
            except ValueError:
                result[key] = None
            result[save_key] = parse_signed_int(save_text)
            ability_idx += 1
            i += 4
        else:
            i += 1
    return result


def parse_monster_section(text, heading):
    """Extract the body of a #### section (e.g. '#### Traits') from a stat block."""
    pattern = re.compile(r"^#### " + re.escape(heading) + r"\s*\n(?:<hr>\s*\n)?(.+?)(?=\n#### |\Z)", re.MULTILINE | re.DOTALL)
    m = pattern.search(text)
    return clean_block(m.group(1)) if m else None


def parse_monster_stat_block(group_name, name, text):
    """Parse a single ### stat block into a dict."""
    monster = {"group_name": group_name, "name": name}

    # _Size Type, Alignment_
    subtitle_m = re.search(r"^_(.+?)_", text, re.MULTILINE)
    if subtitle_m:
        parts = subtitle_m.group(1).split(",", 1)
        size_type = parts[0].strip()
        # The size is the first word; the rest is creature type.
        size_words = size_type.split()
        monster["size"] = size_words[0] if size_words else None
        monster["creature_type"] = " ".join(size_words[1:]) if len(size_words) > 1 else None
        monster["alignment"] = parts[1].strip() if len(parts) > 1 else None
    else:
        monster["size"] = monster["creature_type"] = monster["alignment"] = None

    ac_m = MONSTER_AC_RE.search(text)
    if ac_m:
        monster["armor_class"] = int(ac_m.group(1))
        monster["initiative_modifier"] = parse_signed_int(ac_m.group(2))
        monster["initiative_score"] = int(ac_m.group(3))
    else:
        monster["armor_class"] = monster["initiative_modifier"] = monster["initiative_score"] = None

    hp_m = MONSTER_HP_RE.search(text)
    if hp_m:
        monster["hit_points"] = int(hp_m.group(1))
        monster["hit_dice"] = hp_m.group(2).strip()
    else:
        monster["hit_points"] = monster["hit_dice"] = None

    speed_m = MONSTER_SPEED_RE.search(text)
    monster["speed"] = clean_inline(speed_m.group(1)) if speed_m else None

    monster.update(parse_ability_table(text))

    # Optional bold-prefixed detail lines
    for label, value in MONSTER_BOLD_RE.findall(text):
        key = label.strip().lower()
        val = clean_inline(re.sub(r"<.*?>", "", value))
        if key == "skills":
            monster["skills"] = val
        elif key == "resistances":
            monster["resistances"] = val
        elif key == "immunities":
            monster["immunities"] = val
        elif key == "vulnerabilities":
            monster["vulnerabilities"] = val
        elif key == "gear":
            monster["gear"] = val
        elif key == "senses":
            monster["senses"] = val
        elif key == "languages":
            monster["languages"] = val

    cr_m = MONSTER_CR_RE.search(text)
    if cr_m:
        monster["cr"] = cr_m.group(1)
        monster["xp"] = int(cr_m.group(2).replace(",", ""))
        monster["proficiency_bonus"] = int(cr_m.group(3))
    else:
        monster["cr"] = monster["xp"] = monster["proficiency_bonus"] = None

    for section in ("Traits", "Actions", "Bonus Actions", "Reactions", "Legendary Actions"):
        key = section.lower().replace(" ", "_") + "_text"
        monster[key] = parse_monster_section(text, section)

    return monster


def parse_monsters(srd_path):
    raw = (srd_path / "monsters-A-Z.md").read_text(encoding="utf-8")
    monsters = []

    for group_name, group_body in split_sections(raw, "## "):
        if not group_name:
            continue
        for variant_name, variant_body in split_sections(group_body, "### "):
            if not variant_name:
                continue
            monsters.append(parse_monster_stat_block(
                clean_inline(group_name),
                clean_inline(variant_name),
                variant_body,
            ))

    return monsters


def emit_monsters_sql(monsters, out):
    out.write("\n-- monsters --------------------------------------------------------------\n")
    for m in monsters:
        cols = (
            "group_name, name, size, creature_type, alignment, "
            "armor_class, initiative_modifier, initiative_score, hit_points, hit_dice, speed, "
            "str, dex, con, int_score, wis, cha, "
            "str_save, dex_save, con_save, int_save, wis_save, cha_save, "
            "skills, resistances, immunities, vulnerabilities, gear, senses, languages, "
            "cr, xp, proficiency_bonus, "
            "traits_text, actions_text, bonus_actions_text, reactions_text, legendary_actions_text"
        )

        def v(key):
            val = m.get(key)
            if val is None:
                return "NULL"
            if isinstance(val, (int, float)):
                return str(val)
            return sql_escape(val)

        vals = ", ".join(v(k) for k in [
            "group_name", "name", "size", "creature_type", "alignment",
            "armor_class", "initiative_modifier", "initiative_score", "hit_points", "hit_dice", "speed",
            "str", "dex", "con", "int_score", "wis", "cha",
            "str_save", "dex_save", "con_save", "int_save", "wis_save", "cha_save",
            "skills", "resistances", "immunities", "vulnerabilities", "gear", "senses", "languages",
            "cr", "xp", "proficiency_bonus",
            "traits_text", "actions_text", "bonus_actions_text", "reactions_text", "legendary_actions_text",
        ])
        out.write(f"INSERT INTO monsters ({cols}) VALUES ({vals});\n")


# --------------------------------------------------------------------------
# Spells
# --------------------------------------------------------------------------


# Leveled spells and cantrips use different subtitle shapes in the source
# markdown: "_Level 3 Evocation (Sorcerer, Wizard)_" vs. "_Evocation Cantrip
# (Sorcerer, Wizard)_" (school and "Cantrip" swap places, and there's no
# level number at all). The two alternatives below capture the school in a
# different group each (2 for leveled, 3 for cantrips) since it sits in a
# different position in the two shapes; see is_cantrip/school below.
SPELL_SUBTITLE_RE = re.compile(r"^_(?:Level (\d+) (\w+)|(\w+) Cantrip)\s+\(([^)]+)\)_", re.MULTILINE)
# Handles both "**Label:** Value" (colon inside bold) and "**Label**: Value" (outside).
SPELL_FIELD_RE = re.compile(r"^\*\*([^*:]+):?\*\*:?\s+(.+)$", re.MULTILINE)
HIGHER_LEVEL_RE = re.compile(r"_Using a Higher-Level Spell Slot\._\s*(.+?)(?=\n\n|\Z)", re.DOTALL)


def parse_spells(srd_path):
    raw = (srd_path / "spells.md").read_text(encoding="utf-8")

    descriptions_marker = "## Spell Descriptions"
    idx = raw.find(descriptions_marker)
    if idx == -1:
        raise RuntimeError("Could not find '## Spell Descriptions' in spells.md")
    az_text = raw[idx:]

    spells = []
    for spell_name, spell_body in split_sections(az_text, "#### "):
        if not spell_name or spell_name.strip() == "Spell Descriptions":
            continue

        subtitle_m = SPELL_SUBTITLE_RE.search(spell_body)
        if not subtitle_m:
            continue

        level_str = subtitle_m.group(1)
        is_cantrip = subtitle_m.group(3) is not None
        school = subtitle_m.group(3) if is_cantrip else subtitle_m.group(2)
        classes = subtitle_m.group(4)
        level = 0 if is_cantrip else int(level_str)

        fields = {}
        for field_name, field_val in SPELL_FIELD_RE.findall(spell_body):
            fields[field_name.strip().lower()] = clean_inline(field_val)

        higher_m = HIGHER_LEVEL_RE.search(spell_body)
        higher_level_text = clean_block(higher_m.group(1)) if higher_m else None

        # Strip the subtitle, bold field lines, and higher-level note from the description.
        desc = spell_body[subtitle_m.end():]
        desc = SPELL_FIELD_RE.sub("", desc)
        desc = HIGHER_LEVEL_RE.sub("", desc)
        desc = clean_block(desc)

        spells.append({
            "name": clean_inline(spell_name),
            "level": level,
            "school": clean_inline(school),
            "classes": clean_inline(classes),
            "casting_time": fields.get("casting time"),
            "range": fields.get("range"),
            "components": fields.get("components"),
            "duration": fields.get("duration"),
            "description": desc,
            "higher_level_text": higher_level_text,
        })

    return spells


def emit_spells_sql(spells, out):
    out.write("\n-- spells ----------------------------------------------------------------\n")
    for spell in spells:
        out.write(
            "INSERT INTO spells "
            "(name, level, school, classes, casting_time, `range`, components, duration, description, higher_level_text) VALUES "
            f"({sql_escape(spell['name'])}, {spell['level']}, {sql_escape(spell['school'])}, "
            f"{sql_escape(spell['classes'])}, {sql_escape(spell['casting_time'])}, "
            f"{sql_escape(spell['range'])}, {sql_escape(spell['components'])}, "
            f"{sql_escape(spell['duration'])}, {sql_escape(spell['description'])}, "
            f"{sql_escape(spell['higher_level_text'])});\n"
        )


# --------------------------------------------------------------------------
# Weapons
# --------------------------------------------------------------------------

WEAPON_TABLE_RE = re.compile(r"\*\*Weapons\*\*\s*\n<table>(.*?)</table>", re.DOTALL)
WEAPON_SUBTYPE_RE = re.compile(r"<th colspan[^>]*><em>([^<]+)</em></th>")


def parse_weapons(srd_path):
    raw = (srd_path / "equipment.md").read_text(encoding="utf-8")

    table_m = WEAPON_TABLE_RE.search(raw)
    if not table_m:
        raise RuntimeError("Could not find Weapons table in equipment.md")

    weapons = []
    current_category = "Simple"
    current_type = "Melee"

    rows = re.split(r"<tr>", table_m.group(1))
    for row in rows:
        subtype_m = WEAPON_SUBTYPE_RE.search(row)
        if subtype_m:
            label = subtype_m.group(1).strip()
            if "Martial" in label:
                current_category = "Martial"
            else:
                current_category = "Simple"
            current_type = "Ranged" if "Ranged" in label else "Melee"
            continue

        cells = re.findall(r"<td>(.*?)</td>", row, re.DOTALL)
        if len(cells) < 6:
            continue

        def cell(i):
            return clean_inline(re.sub(r"<.*?>", "", cells[i])) or None

        name = cell(0)
        if not name:
            continue

        damage_raw = cell(1) or ""
        # e.g. "1d6 Piercing" or "2d6 Slashing"
        damage_m = re.match(r"(\d+d\d+(?:\s*/\s*\d+d\d+)?)\s+(\w+)", damage_raw)
        damage_dice = damage_m.group(1) if damage_m else None
        damage_type = damage_m.group(2) if damage_m else None

        weapons.append({
            "name": name,
            "category": current_category,
            "weapon_type": current_type,
            "damage": damage_raw,
            "damage_dice": damage_dice,
            "damage_type": damage_type,
            "properties": cell(2),
            "mastery": cell(3),
            "weight": cell(4),
            "cost": cell(5),
        })

    return weapons


def emit_weapons_sql(weapons, out):
    out.write("\n-- weapons ---------------------------------------------------------------\n")
    for w in weapons:
        out.write(
            "INSERT INTO weapons "
            "(name, category, weapon_type, damage, damage_dice, damage_type, properties, mastery, weight, cost) VALUES "
            f"({sql_escape(w['name'])}, {sql_escape(w['category'])}, {sql_escape(w['weapon_type'])}, "
            f"{sql_escape(w['damage'])}, {sql_escape(w['damage_dice'])}, {sql_escape(w['damage_type'])}, "
            f"{sql_escape(w['properties'])}, {sql_escape(w['mastery'])}, {sql_escape(w['weight'])}, "
            f"{sql_escape(w['cost'])});\n"
        )


# --------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--srd-path", type=Path, default=DEFAULT_SRD_PATH)
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT)
    args = parser.parse_args()

    classes = parse_classes(args.srd_path)
    feats = parse_feats(args.srd_path)
    items = parse_magic_items(args.srd_path)
    monsters = parse_monsters(args.srd_path)
    spells = parse_spells(args.srd_path)
    weapons = parse_weapons(args.srd_path)

    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", encoding="utf-8") as out:
        out.write("-- Auto-generated by resources/database/import_srd.py. Do not edit by hand.\n")
        out.write("USE gameserver;\n")
        out.write("SET NAMES utf8mb4;\n")
        emit_classes_sql(classes, out)
        emit_feats_sql(feats, out)
        emit_magic_items_sql(items, out)
        emit_monsters_sql(monsters, out)
        emit_spells_sql(spells, out)
        emit_weapons_sql(weapons, out)

    print(
        f"Parsed {len(classes)} classes, {sum(len(c['features']) for c in classes)} class features, "
        f"{sum(1 for c in classes if c['subclass'])} subclasses, {len(feats)} feats, {len(items)} magic items, "
        f"{len(monsters)} monsters, {len(spells)} spells, {len(weapons)} weapons."
    )
    print(f"Wrote SQL seed file to {args.out}")


if __name__ == "__main__":
    main()
