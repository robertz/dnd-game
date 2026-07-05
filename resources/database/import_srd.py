#!/usr/bin/env python3
"""
Parses classes.md, feats.md, and magic-items.md from the dnd-5e-srd-markdown
repo and emits a SQL seed file for the `gameserver` MySQL schema defined in
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

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--srd-path", type=Path, default=DEFAULT_SRD_PATH)
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT)
    args = parser.parse_args()

    classes = parse_classes(args.srd_path)
    feats = parse_feats(args.srd_path)
    items = parse_magic_items(args.srd_path)

    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", encoding="utf-8") as out:
        out.write("-- Auto-generated by resources/database/import_srd.py. Do not edit by hand.\n")
        out.write("USE gameserver;\n")
        out.write("SET NAMES utf8mb4;\n")
        emit_classes_sql(classes, out)
        emit_feats_sql(feats, out)
        emit_magic_items_sql(items, out)

    print(f"Parsed {len(classes)} classes, {sum(len(c['features']) for c in classes)} class features, "
          f"{sum(1 for c in classes if c['subclass'])} subclasses, {len(feats)} feats, {len(items)} magic items.")
    print(f"Wrote SQL seed file to {args.out}")


if __name__ == "__main__":
    main()
