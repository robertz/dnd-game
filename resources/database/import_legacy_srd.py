#!/usr/bin/env python3
"""
Parses json/01 races.json, json/12 conditions.json, and json/03 beyond1st.json
from the dnd-5e-srd repo (2014-ruleset SRD converted to nested JSON) and
emits a SQL seed file for the `species`, `species_traits`, `conditions`, and
`backgrounds` tables defined in resources/database/migrations/
009_species_and_conditions.sql and 010_backgrounds.sql.

Race/background text is mostly free prose, but the parts character creation
actually needs to compute with (ability score bonuses, speed, darkvision,
size, languages, resistances, skill/tool proficiencies) are pulled out into
their own columns rather than stored as sentences. Traits/features without a
fixed shape (Trance, Fey Ancestry, Draconic Ancestry, Shelter of the
Faithful, ...) stay as named rows/columns holding their own prose.

Usage:
    python3 import_legacy_srd.py [--srd-path /path/to/dnd-5e-srd] [--out seeds/legacy_srd_seed.sql]
    mysql -uroot gameserver < resources/database/seeds/legacy_srd_seed.sql
"""

import argparse
import html
import json
import re
from pathlib import Path

DEFAULT_SRD_PATH = Path(__file__).resolve().parents[2].parent / "dnd-5e-srd"
DEFAULT_OUT = Path(__file__).resolve().parent / "seeds" / "legacy_srd_seed.sql"

TRAIT_RE = re.compile(r"^\*\*\*(.+?)\.\*\*\*\s*(.*)$", re.DOTALL)

ABILITY_COLUMNS = {
    "strength": "str_bonus",
    "dexterity": "dex_bonus",
    "constitution": "con_bonus",
    "intelligence": "int_bonus",
    "wisdom": "wis_bonus",
    "charisma": "cha_bonus",
}
WORD_NUMBERS = {"one": 1, "two": 2, "three": 3, "four": 4}

FIXED_ABILITY_RE = re.compile(r"[Yy]our (\w+) score increases by (\d+)")
ALL_ABILITIES_RE = re.compile(r"ability scores each increase by (\d+)")
CHOICE_ABILITY_RE = re.compile(
    r"(\w+) other ability scores? of (?:your|his|her|their) choice increase(?:s)? by (\d+)"
)
SIZE_RE = re.compile(r"[Yy]our size is (\w+)")
SPEED_RE = re.compile(r"(\d+)\s*feet")
DARKVISION_RE = re.compile(r"within (\d+) feet")
LANGUAGES_RE = re.compile(r"you can speak, read, and write ([^.]+)\.", re.IGNORECASE)
BONUS_LANGUAGE_RE = re.compile(r",?\s*and\s+one extra language of your choice", re.IGNORECASE)
RESISTANCE_RE = re.compile(r"resistance (?:to|against) (\w+) damage", re.IGNORECASE)
RESISTANCE_STOPWORDS = {"the", "this", "that", "your", "associated"}


def sql_escape(value):
    if value is None:
        return "NULL"
    return "'" + html.unescape(str(value)).replace("\\", "\\\\").replace("'", "\\'") + "'"


def sql_int(value):
    return "NULL" if value is None else str(value)


def render_table_as_text(table):
    """Render a {col: [values...]} table dict as plain reference text (not markdown)."""
    cols = list(table.keys())
    rows = list(zip(*[table[c] for c in cols]))
    if len(cols) == 2:
        return "\n".join(f"{row[0]}: {row[1]}" for row in rows)
    lines = []
    for row in rows:
        detail = "; ".join(f"{col}: {val}" for col, val in zip(cols[1:], row[1:]))
        lines.append(f"{row[0]} — {detail}")
    return "\n".join(lines)


def parse_content_block(content):
    """
    Split a race/condition `content` list into (intro_paragraphs, traits).
    traits is a list of (name, description) tuples. Table/list items
    encountered are appended (as plain text) to the preceding trait's
    description, or to the intro if no trait has been seen yet.
    """
    intro = []
    traits = []

    def append(rendered):
        if traits:
            name, desc = traits[-1]
            traits[-1] = (name, desc + "\n\n" + rendered)
        else:
            intro.append(rendered)

    for item in content:
        if isinstance(item, dict) and "table" in item:
            append(render_table_as_text(item["table"]))
        elif isinstance(item, list):
            append("\n".join(item))
        else:
            match = TRAIT_RE.match(item)
            if match:
                heading, body = match.group(1).strip(), match.group(2).strip()
                # Some SRD entries repeat the same "***Heading.***" a second
                # time (e.g. Dragonborn's "Draconic Ancestry" heading appears
                # once immediately before its table, then again before its
                # prose) — merge those into a single trait rather than two.
                if traits and traits[-1][0].lower() == heading.lower():
                    name, desc = traits[-1]
                    traits[-1] = (name, (desc + "\n\n" + body).strip() if body else desc)
                else:
                    traits.append((heading, body))
            elif traits:
                append(item)
            else:
                intro.append(item)
    return "\n\n".join(intro).strip() or None, traits


def parse_ability_bonuses(text):
    bonuses = {col: 0 for col in ABILITY_COLUMNS.values()}
    choice_count = 0
    choice_bonus = 0

    all_match = ALL_ABILITIES_RE.search(text)
    if all_match:
        amount = int(all_match.group(1))
        return {col: amount for col in bonuses}, 0, 0

    for ability, amount in FIXED_ABILITY_RE.findall(text):
        column = ABILITY_COLUMNS.get(ability.lower())
        if column:
            bonuses[column] = int(amount)

    choice_match = CHOICE_ABILITY_RE.search(text)
    if choice_match:
        count_word, amount = choice_match.groups()
        choice_count = WORD_NUMBERS.get(count_word.lower(), 0)
        choice_bonus = int(amount)

    return bonuses, choice_count, choice_bonus


def parse_languages(text):
    match = LANGUAGES_RE.search(text)
    if not match:
        return [], False
    raw = match.group(1)
    bonus_choice = bool(BONUS_LANGUAGE_RE.search(raw))
    raw = BONUS_LANGUAGE_RE.sub("", raw)
    parts = re.split(r",\s*(?:and\s+)?|\s+and\s+", raw)
    languages = [p.strip() for p in parts if p.strip()]
    return languages, bonus_choice


def parse_species_node(name, node):
    """Parse one race/subrace node (dict with 'content' plus optional nested subrace keys)."""
    description_parts, traits = parse_content_block(node["content"])
    description = [description_parts] if description_parts else []

    size = None
    speed = None
    darkvision = None
    languages = []
    bonus_language_choice = False
    resistances = []
    bonuses = {col: 0 for col in ABILITY_COLUMNS.values()}
    choice_count = 0
    choice_bonus = 0
    remaining_traits = []

    for trait_name, trait_desc in traits:
        key = trait_name.lower()
        resistance_matches = RESISTANCE_RE.findall(trait_desc)
        resistances.extend(
            m.title() for m in resistance_matches if m.lower() not in RESISTANCE_STOPWORDS
        )

        if key == "ability score increase":
            bonuses, choice_count, choice_bonus = parse_ability_bonuses(trait_desc)
            continue
        if key == "size":
            size_match = SIZE_RE.search(trait_desc)
            size = size_match.group(1) if size_match else None
            continue
        if key == "speed":
            speed_match = SPEED_RE.search(trait_desc)
            if speed_match:
                speed = int(speed_match.group(1))
            continue
        if key == "darkvision":
            dark_match = DARKVISION_RE.search(trait_desc)
            if dark_match:
                darkvision = int(dark_match.group(1))
            remaining_traits.append((trait_name, trait_desc))
            continue
        if key == "languages":
            languages, bonus_language_choice = parse_languages(trait_desc)
            continue
        if key in ("age", "alignment"):
            description.append(f"{trait_name}: {trait_desc}")
            continue
        remaining_traits.append((trait_name, trait_desc))

    subraces = [(key, value) for key, value in node.items() if key != "content"]

    return {
        "name": name,
        "description": "\n\n".join(description) or None,
        "size": size,
        "speed": speed,
        "darkvision": darkvision,
        **bonuses,
        "choice_ability_count": choice_count,
        "choice_ability_bonus": choice_bonus,
        "languages": ", ".join(languages) or None,
        "bonus_language_choice": bonus_language_choice,
        "resistances": ", ".join(sorted(set(resistances))) or None,
        "traits": remaining_traits,
        "subraces": subraces,
    }


def parse_species(srd_path):
    raw = json.loads((srd_path / "json" / "01 races.json").read_text(encoding="utf-8"))
    races_node = raw["Races"]
    species = []
    for race_name, race_body in races_node.items():
        if race_name == "Racial Traits":
            continue
        traits_key = f"{race_name} Traits"
        species.append(parse_species_node(race_name, race_body[traits_key]))
    return species


def emit_species_sql(species, out):
    out.write("\n-- species --------------------------------------------------------------\n")

    def emit_one(entry, parent_var):
        out.write(
            "INSERT INTO species "
            "(parent_species_id, name, size, speed, darkvision, str_bonus, dex_bonus, con_bonus, "
            "int_bonus, wis_bonus, cha_bonus, choice_ability_count, choice_ability_bonus, "
            "languages, bonus_language_choice, resistances, description) VALUES "
            f"({parent_var}, {sql_escape(entry['name'])}, {sql_escape(entry['size'])}, "
            f"{sql_int(entry['speed'])}, {sql_int(entry['darkvision'])}, "
            f"{entry['str_bonus']}, {entry['dex_bonus']}, {entry['con_bonus']}, "
            f"{entry['int_bonus']}, {entry['wis_bonus']}, {entry['cha_bonus']}, "
            f"{entry['choice_ability_count']}, {entry['choice_ability_bonus']}, "
            f"{sql_escape(entry['languages'])}, {1 if entry['bonus_language_choice'] else 0}, "
            f"{sql_escape(entry['resistances'])}, {sql_escape(entry['description'])});\n"
        )
        out.write("SET @species_id = LAST_INSERT_ID();\n")
        for sort_order, (trait_name, trait_desc) in enumerate(entry["traits"], start=1):
            out.write(
                "INSERT INTO species_traits (species_id, sort_order, name, description) VALUES "
                f"(@species_id, {sort_order}, {sql_escape(trait_name)}, {sql_escape(trait_desc)});\n"
            )
        if entry["subraces"]:
            out.write("SET @species_parent = @species_id;\n")
            for sub_name, sub_body in entry["subraces"]:
                sub_entry = parse_species_node(sub_name, sub_body)
                emit_one(sub_entry, "@species_parent")

    for entry in species:
        emit_one(entry, "NULL")


def parse_conditions(srd_path):
    raw = json.loads((srd_path / "json" / "12 conditions.json").read_text(encoding="utf-8"))
    node = raw["Appendix PH-A: Conditions"]
    conditions = []
    for name, body in node.items():
        if name == "content":
            continue
        content = body["content"] if isinstance(body, dict) else body
        paragraphs = []
        for item in content:
            if isinstance(item, dict) and "table" in item:
                paragraphs.append(render_table_as_text(item["table"]))
            else:
                paragraphs.append(item)
        conditions.append((name, "\n\n".join(paragraphs)))
    return conditions


def emit_conditions_sql(conditions, out):
    out.write("\n-- conditions ------------------------------------------------------------\n")
    for name, description in conditions:
        out.write(
            "INSERT INTO conditions (name, description) VALUES "
            f"({sql_escape(name)}, {sql_escape(description)});\n"
        )


LABEL_RE = re.compile(r"^\*\*(.+?):\*\*\s*(.*)$")
LABEL_COLUMN_MAP = {
    "skill proficiencies": "skill_proficiencies",
    "tool proficiencies": "tool_proficiencies",
    "equipment": "equipment_text",
}
BONUS_LANGUAGE_COUNT_RE = re.compile(r"(\w+) of your choice", re.IGNORECASE)
BACKGROUND_NON_ENTRY_KEYS = {
    "content", "Proficiencies", "Languages", "Equipment",
    "Suggested Characteristics", "Customizing a Background",
}


def parse_background_node(name, node):
    description = []
    fields = {"skill_proficiencies": None, "tool_proficiencies": None, "equipment_text": None}
    bonus_language_count = 0

    for item in node["content"]:
        match = LABEL_RE.match(item)
        if not match:
            description.append(item)
            continue
        label, value = match.group(1).strip().lower(), match.group(2).strip()
        if label == "languages":
            count_match = BONUS_LANGUAGE_COUNT_RE.search(value)
            if count_match:
                bonus_language_count = WORD_NUMBERS.get(count_match.group(1).lower(), 0)
            continue
        column = LABEL_COLUMN_MAP.get(label)
        if column:
            fields[column] = value

    feature_name = None
    feature_description = None
    for key, body in node.items():
        if key.startswith("Feature:"):
            feature_name = key.split(":", 1)[1].strip()
            feature_paragraphs = []
            for item in body["content"]:
                if isinstance(item, dict) and "table" in item:
                    feature_paragraphs.append(render_table_as_text(item["table"]))
                else:
                    feature_paragraphs.append(item)
            feature_description = "\n\n".join(feature_paragraphs)
            break

    return {
        "name": name,
        "description": "\n\n".join(description).strip() or None,
        "bonus_language_count": bonus_language_count,
        "feature_name": feature_name,
        "feature_description": feature_description,
        **fields,
    }


def parse_backgrounds(srd_path):
    raw = json.loads((srd_path / "json" / "03 beyond1st.json").read_text(encoding="utf-8"))
    node = raw["Beyond 1st Level"]["Backgrounds"]
    return [
        parse_background_node(name, body)
        for name, body in node.items()
        if name not in BACKGROUND_NON_ENTRY_KEYS
    ]


def emit_backgrounds_sql(backgrounds, out):
    out.write("\n-- backgrounds ------------------------------------------------------------\n")
    for entry in backgrounds:
        out.write(
            "INSERT INTO backgrounds "
            "(name, description, skill_proficiencies, tool_proficiencies, bonus_language_count, "
            "equipment_text, feature_name, feature_description) VALUES "
            f"({sql_escape(entry['name'])}, {sql_escape(entry['description'])}, "
            f"{sql_escape(entry['skill_proficiencies'])}, {sql_escape(entry['tool_proficiencies'])}, "
            f"{entry['bonus_language_count']}, {sql_escape(entry['equipment_text'])}, "
            f"{sql_escape(entry['feature_name'])}, {sql_escape(entry['feature_description'])});\n"
        )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--srd-path", type=Path, default=DEFAULT_SRD_PATH)
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT)
    args = parser.parse_args()

    species = parse_species(args.srd_path)
    conditions = parse_conditions(args.srd_path)
    backgrounds = parse_backgrounds(args.srd_path)

    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", encoding="utf-8") as out:
        out.write("-- Auto-generated by resources/database/import_legacy_srd.py. Do not edit by hand.\n")
        out.write("USE gameserver;\n")
        out.write("SET NAMES utf8mb4;\n")
        emit_species_sql(species, out)
        emit_conditions_sql(conditions, out)
        emit_backgrounds_sql(backgrounds, out)

    subrace_count = sum(len(e["subraces"]) for e in species)
    print(
        f"Parsed {len(species)} species ({subrace_count} subraces), {len(conditions)} conditions, "
        f"{len(backgrounds)} backgrounds."
    )
    print(f"Wrote SQL seed file to {args.out}")


if __name__ == "__main__":
    main()
