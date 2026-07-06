#!/usr/bin/env python3
"""
Parses every row in the `gameserver.spells` table's free-text `description`
column and extracts, where confidently detectable, the structured mechanics
added by migrations/002_spell_mechanics.sql: whether the spell is an attack-
roll, saving-throw, or healing effect, its damage/heal dice, damage type,
save ability, and (for saves) whether a success still takes half damage.

Most of the SRD's spells are pure utility/effect text with no single
damage/save/heal roll to extract (illusions, buffs, forced movement,
teleportation, etc.) — those are intentionally left as effect_type='utility'
with everything else NULL, since that's an accurate description of a spell
this simple a schema can't mechanize, not a parsing failure.

Known, deliberate gap: a handful of spells deal damage with no attack roll or
save at all (Magic Missile's auto-hit darts being the clearest example) —
this script doesn't try to detect that shape, to avoid false positives on the
much more common case of "damage" mentioned as a side-effect/rider (Hex,
Hunter's Mark, Divine Smite, Power Word Kill, etc.), so those are left as
'utility' too. See the CLAUDE.md-style note in migrations/002 for the same
caveat at the schema level.

Also worth knowing: this SRD import has zero level-0 (cantrip) spells at all
— `SELECT COUNT(*) FROM spells WHERE level = 0` is 0. Fire Bolt, Sacred
Flame, Vicious Mockery, Produce Flame, Eldritch Blast — none of them are in
this table. That's a gap in the original srd_seed.sql import, not something
this script can fix by parsing text that was never imported.

Usage:
    mysql -uroot gameserver --raw -N -e "SELECT JSON_ARRAYAGG(JSON_OBJECT(
        'id', id, 'name', name, 'description', description
    )) FROM spells;" > /tmp/spells_dump.json
    python3 extract_spell_mechanics.py /tmp/spells_dump.json --out seeds/spell_mechanics_update.sql
    mysql -uroot gameserver < seeds/spell_mechanics_update.sql
"""

import argparse
import json
import re
from collections import Counter
from pathlib import Path

DEFAULT_OUT = Path(__file__).resolve().parent / "seeds" / "spell_mechanics_update.sql"

ABILITY_MAP = {
    "strength": "str", "dexterity": "dex", "constitution": "con",
    "intelligence": "int", "wisdom": "wis", "charisma": "cha",
}

# How far past the triggering phrase (an attack-roll or saving-throw mention)
# to look for its damage dice — generous enough to span "On a hit/failed
# save, ... takes NdM Type damage", not so wide it picks up an unrelated
# damage mention from a later paragraph (e.g. a higher-level-damage rider).
DAMAGE_SEARCH_WINDOW = 400

DAMAGE_RE = re.compile(r"(\d+d\d+(?:\s*\+\s*\d+)?)\s+([A-Z][a-zA-Z]+)\s+damage")
ATTACK_ROLL_RE = re.compile(r"\b(melee|ranged)\s+spell\s+attack\b", re.IGNORECASE)
SAVING_THROW_RE = re.compile(
    r"\b(Strength|Dexterity|Constitution|Intelligence|Wisdom|Charisma)\s+saving\s+throw\b"
)
HEAL_RE_EQUAL_TO = re.compile(
    r"\bregains?\s+(?:a number of\s+)?Hit Points\s+equal\s+to\s+(\d+d\d+(?:\s*\+\s*\d+)?)",
    re.IGNORECASE,
)
HEAL_RE_DIRECT = re.compile(
    r"\bregains?\s+(\d+d\d+(?:\s*\+\s*\d+)?)\s+Hit Points\b", re.IGNORECASE
)


def _find_damage_near(description, start_pos):
    segment = description[start_pos:start_pos + DAMAGE_SEARCH_WINDOW]
    match = DAMAGE_RE.search(segment)
    if not match:
        return None
    dice = match.group(1).replace(" ", "")
    damage_type = match.group(2)
    return dice, damage_type


def classify(description):
    """
    Returns a dict of the columns to set for one spell, or None if nothing
    could be confidently extracted (caller leaves it as the utility default).
    """
    if not description:
        return None

    attack_match = ATTACK_ROLL_RE.search(description)
    if attack_match:
        damage = _find_damage_near(description, attack_match.end())
        if damage:
            dice, damage_type = damage
            return {
                "effect_type": "attack",
                "attack_type": attack_match.group(1).lower(),
                "damage_dice": dice,
                "damage_type": damage_type,
            }

    save_match = SAVING_THROW_RE.search(description)
    if save_match:
        damage = _find_damage_near(description, save_match.end())
        if damage:
            dice, damage_type = damage
            # "Half on a success" shows up in (at least) two phrasings in this
            # SRD text: the older two-sentence style ("On a failed save, ...
            # On a successful save, it takes half as much damage") and the
            # more common single-sentence 2024 style ("... on a failed save
            # or half as much damage on a successful one" — no literal
            # "successful save", just "successful one"). Rather than special-
            # case both phrasings, just check whether "half" damage wording
            # shows up anywhere in the same window the dice came from.
            window = description[save_match.end():save_match.end() + DAMAGE_SEARCH_WINDOW].lower()
            half_on_success = "half as much damage" in window or "half the damage" in window or "takes half" in window
            return {
                "effect_type": "save",
                "save_ability": ABILITY_MAP[save_match.group(1).lower()],
                "damage_dice": dice,
                "damage_type": damage_type,
                "save_effect": "half" if half_on_success else "none",
            }

    heal_match = HEAL_RE_EQUAL_TO.search(description) or HEAL_RE_DIRECT.search(description)
    if heal_match:
        return {"effect_type": "heal", "heal_dice": heal_match.group(1).replace(" ", "")}

    return None


def sql_escape(value):
    return "'" + str(value).replace("\\", "\\\\").replace("'", "\\'") + "'"


def build_update_sql(spell_id, fields):
    columns = ["effect_type"]
    values = [sql_escape(fields["effect_type"])]
    for column in ("attack_type", "save_ability", "save_effect", "damage_dice", "damage_type", "heal_dice"):
        columns.append(column)
        values.append(sql_escape(fields[column]) if column in fields else "NULL")
    assignments = ", ".join(f"{col} = {val}" for col, val in zip(columns, values))
    return f"UPDATE spells SET {assignments} WHERE id = {spell_id};"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("dump_json", help="Path to the JSON array dumped from the spells table")
    parser.add_argument("--out", default=str(DEFAULT_OUT), help="Output .sql file of UPDATE statements")
    args = parser.parse_args()

    with open(args.dump_json, encoding="utf-8", errors="replace") as f:
        spells = json.load(f)

    statements = []
    counts = Counter()
    examples = {"attack": [], "save": [], "heal": []}

    for spell in spells:
        fields = classify(spell.get("description"))
        effect_type = fields["effect_type"] if fields else "utility"
        counts[effect_type] += 1
        if fields:
            statements.append(build_update_sql(spell["id"], fields))
            if len(examples[effect_type]) < 5:
                examples[effect_type].append(spell["name"])

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("-- Generated by extract_spell_mechanics.py — do not hand-edit.\n")
        f.write("\n".join(statements) + "\n")

    total = len(spells)
    print(f"Processed {total} spells -> {out_path}")
    print(f"  attack:  {counts['attack']:>3}  e.g. {', '.join(examples['attack'])}")
    print(f"  save:    {counts['save']:>3}  e.g. {', '.join(examples['save'])}")
    print(f"  heal:    {counts['heal']:>3}  e.g. {', '.join(examples['heal'])}")
    print(f"  utility: {counts['utility']:>3}  (no single damage/save/heal roll to extract)")


if __name__ == "__main__":
    main()
