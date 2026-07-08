# WIP: Character Creation / Species / Background Gaps

Status as of the species+background wiring work (`species`, `species_traits`,
`conditions`, `backgrounds` tables imported from the 2014 SRD via
`resources/database/import_legacy_srd.py`, wired into
`CharacterService.bx`/`CombatService.bx`/`characterCreation.bx`).

## 1. Only one background exists
The 2014 SRD content in `dnd-5e-srd` only ships **Acolyte** under its
license — `backgroundOptions` now offers just that one choice. Criminal,
Sage, and Soldier (previously hardcoded, 2024-ruleset) are gone.

- The 2024-ruleset equivalents (Acolyte, Criminal, Sage, Soldier) exist in
  full in `/Users/rob/Development/dnd-5e-srd-markdown/character-origins.md`,
  but importing them isn't a drop-in: 2024 backgrounds grant an ability
  score choice (+2/+1 or +1/+1/+1 across a named set of three abilities)
  and a specific Feat — neither of which the current `backgrounds` table
  has columns for (it's shaped for 2014 Acolyte: skill/tool proficiencies,
  bonus languages, one feature).
- 2024 species (Goliath, Orc — also in character-origins.md) grant **zero**
  ability bonus at all in that ruleset (all ability bonuses moved to
  background); the current `species` table assumes every species carries a
  bonus. Naively mixing 2014 species + 2024 backgrounds (or vice versa)
  would leave a character with no ability bonus from either source.
- Decision needed: extend both tables to hold the 2024 shape as optional
  columns and accept a mixed-ruleset roster, or skip Goliath/Orc/Criminal/
  Sage/Soldier entirely to keep the roster ruleset-pure to 2014.

## 2. Backgrounds are display-only, not mechanical
**Partially resolved.** A skill-check system now exists
(`CombatService.bx`: `SKILL_ABILITIES`, `TRAIT_SKILL_GRANTS`,
`resolveSkillProficiencies()`/`_skillProficienciesFromTraits()`,
`rollSkillCheck()`, `_skillProficiencyBonus()`), and a character's
background skill proficiencies (Acolyte: Insight, Religion) plus
skill-granting species traits (Keen Senses -> Perception, Menacing ->
Intimidation, Skill Versatility -> auto-picked Insight+Perception, no
skill-picker UI exists) are resolved into a real `skillProficiencies` array
on the combat player struct and shown on the character sheet. It's wired
into the one existing combat mechanic that needed it: `attemptGrapple()`/
`attemptShove()` now only add Proficiency Bonus for a side that's actually
proficient in Athletics (attacker) or Athletics/Acrobatics (defender),
instead of unconditionally assuming every combatant is proficient.

**Update:** a class skill-picker step now exists too. `CombatService.
parseClassSkillChoice()` parses `classes.skill_proficiencies` ("Choose 2:
Athletics, Insight, ..." or Bard's "Choose any 3 skills" -> all 18 SRD
skills) into `{count, options}`; Step 1 (Class) of the wizard shows the
picker once a class is selected and requires exactly `count` picks before
advancing. The choice is stored on `characters.chosen_skill_proficiencies`
(migration `011_character_class_skills.sql`, comma list — background/
species skills aren't stored, since those are re-derived by name every
time) and merged into the same `skillProficiencies` array everywhere else
reads it (`CombatService.loadCharacter()`, `CharacterService.
getCharacterSheet()` via `_mergeSkills()`).

Still missing: there's no broader skill-check use beyond grapple/shove's
Athletics/Acrobatics — no Perception/Stealth/Insight moment exists anywhere
in the game, since combat is still the entire interactive loop (confirmed:
no trap/search/door/social-encounter content exists in the adventure-module
schema or seeds). `rollSkillCheck()` is built and tested but has nothing
else to call it yet.

## 3. Most species traits are inert flavor text
**Updated:** seven trait names are now wired to real combat mechanics (see
`CombatService.bx`'s `_resolveSpeciesMechanics()`): Lucky, Relentless
Endurance, Breath Weapon, Fey Ancestry, Gnome Cunning, Dwarven Toughness,
and (newly added) **Savage Attacks** (Half-Orc: one extra weapon damage die
on a melee critical hit — `resolveAttack()`, tested in
`CombatServiceSpec.bx`).

Still stored in `species_traits` but **not** hooked up to anything:
Stonecunning, Keen Senses, Trance, Halfling Nimbleness, Naturally Stealthy,
Menacing, Infernal Legacy, Elf Weapon Training, Cantrip, Extra Language,
Artificer's Lore, Tinker. Scoped these out deliberately — they all need a
system that doesn't exist yet (skill checks/proficiency, a Hide/stealth
action, a lighting/vision model, or innate-spellcasting-outside-class-
casting), not just a lookup. Halfling Nimbleness turned out to be moot: the
player's `movePlayer()`/`pathDistance()` already ignore occupied squares
entirely when computing path distance, so there's no "can't squeeze past a
larger creature" restriction to exempt Halflings from in the first place.

## 4. Ability-choice picker doesn't exclude the fixed-bonus ability
**Resolved.** `characterCreation.bx` now has `choiceAbilityOptions(detail)`,
filtering out any ability with a nonzero fixed species bonus — used both by
the template (Charisma no longer even renders as a card for Half-Elf) and
by `toggleChoiceAbility()` itself (rejects the ability server-side too, not
just a UI-only fix, in case of a stale/replayed click). Verified live: a
preselected Half-Elf's picker shows only str/dex/con/int/wis, never cha.

## 5. Darkvision and languages are inert
Resolved by `resolveSpecies()` and shown in the Origin step, but nothing in
the app has a lighting/vision mechanic or a language-gated check for them
to affect.

## 6. Conditions table is unused
**Resolved.** `CombatService.conditionDescription(name)` looks up a
condition's SRD rules text from the `conditions` table. `default.bxm`'s
player/foe condition lists now render each condition as its own
`.condition-chip` (styled in `Main.bxm`) with a `title` tooltip holding the
full rules text, instead of a flat comma-joined string — verified live
(forced a "Poisoned" condition onto the player mid-encounter and confirmed
the chip and tooltip text render). `default.bx` exposes the lookup via a
`conditionDescription()` wrapper, the same pattern already used for
`wallAutotileClass()`/`itemIsUsable()`. Tested in `CombatServiceSpec.bx`.

## 7. Level-1 class features were never granted (found while implementing subclasses/feats)
**Resolved.** `_grantNewFeatures()` (`CombatService.bx`) — the function that
records a class's features into `character_features` — was only ever
invoked from `_levelUp()`, i.e. only when a character gains XP and crosses
a level threshold. A brand-new level-1 character never "levels up" into
level 1, so every level-1 class feature (Barbarian's Rage and Unarmored
Defense, Rogue's Sneak Attack/Expertise/Thieves' Cant, every class's
Spellcasting/Weapon Mastery, etc.) was silently never recorded for any
character, ever — confirmed empty on a live level-3 "Dev" character before
this fix. `CharacterService._grantLevelOneClassFeatures()` now grants them
at creation, the same way `_grantNewFeatures()` does at level-up.

**Update:** Rage, Sneak Attack, Second Wind, Expertise, and Weapon Mastery
now have real mechanical hooks (see the new item below) — the "flavor-only
name" gap below is resolved for these five specifically. Every other class
feature name (Channel Divinity, Metamagic, Wild Shape, Stunning Strike,
Cunning Action, and the ~100 other higher-level/subclass features across
all 12 classes) is still name-only, by explicit scope decision — full
coverage of every class's entire feature list remains a much larger,
separate undertaking than was justified here.

## 7a. Rage / Sneak Attack / Second Wind / Expertise / Weapon Mastery mechanics
**Resolved** (the 5 features named in #7's note above, chosen as the
highest-impact subset rather than attempting all ~100+ feature names across
12 classes — see "Priority if picked back up" for what's still flavor-only).
All read `player.features` the same way Extra Attack/Fighting Style already
did — no new grant-time code was needed, since `_grantLevelOneClassFeatures()`/
`_grantNewFeatures()` (#7) already recorded these correctly; only the
*mechanics that consume them* were missing.

- **Second Wind** (Fighter 1): `useSecondWind()` — a bonus action, healing
  1d10 + Fighter level. **Update (see #12)**: originally reset every
  encounter; now persists across encounters and only recovers on a Short
  or Long Rest, per the real rule.
- **Rage** (Barbarian 1): `startRage()`/`endRage()` — a bonus action,
  `player.ragesRemaining` uses from the SRD's per-long-rest table (2 at
  1st, up to 6 at 17th+). **Update (see #12)**: originally reset every
  encounter; `player.ragesUsed` now persists across encounters (mirroring
  `spentSpellSlots`), recovering one use on a Short Rest and all of them
  on a Long Rest. While raging: +2/
  +3/+4 (by level) damage on melee weapon hits (`resolveAttack()`), Advantage
  on Strength saving throws (`rollSavingThrow()`), and resistance to
  Bludgeoning/Piercing/Slashing damage. **Simplified**: doesn't auto-end if
  you don't attack/take damage on your turn (RAW) — only ends via `endRage()`
  or the encounter ending; and the damage bonus applies to *any* melee weapon
  while raging rather than only Strength-based ones (this app doesn't track
  which ability a Finesse attack actually used).
- **Sneak Attack** (Rogue 1): once per turn, on a hit with a Finesse or
  ranged weapon made with Advantage, extra `ceil(level/2)d6` damage (doubled
  on a crit). **Simplified**: RAW also allows it without Advantage if
  another of the target's enemies is within 5 ft. — not modeled, since
  `resolveAttack()` doesn't have full battlefield adjacency for arbitrary
  attacker/defender pairs. In practice this still triggers via any of the
  app's existing Advantage sources (Restrained/Blinded/helpless/Prone-in-
  melee target, Pack Tactics, etc.).
- **Expertise** (Rogue 1, Bard 2, Ranger 9): doubles Proficiency Bonus for
  2 player-chosen skills (must already be proficient) — a new
  `characters.expertise_skills` column (migration `013_expertise_and_rage.sql`),
  `pendingExpertiseChoice()`/`chooseExpertise()` (never auto-assigned, per
  the standing rule), surfaced as a "Choose Expertise" character-sheet panel.
  Expertise skills get an asterisk and an "(Expertise)" tooltip note on the
  sheet's skill chips.
- **Weapon Mastery** (Barbarian/Fighter/Paladin/Ranger/Rogue 1): all 8 SRD
  mastery properties (`weapons.mastery` — already-existing data, previously
  unused) now do something in `resolveAttack()`/`offHandAttack()`: Vex
  (Advantage on your next attack vs. the same target), Sap (Disadvantage on
  the target's next attack), Slow (-10 ft. Speed on a damaging hit, until
  the following round), Topple (Constitution save or fall Prone), Graze
  (ability-modifier damage even on a miss), Cleave (also strikes one other
  adjacent hostile for the same damage), Push (shoves the target 10 ft.
  away, blocked by walls), and Nick (the off-hand attack skips the bonus
  action, once per turn). **Simplified**: no per-weapon "which masteries do
  you know" choice — every weapon with a mastery property works
  automatically for a character with the Weapon Mastery feature (RAW limits
  this to a class/level-scaled number of weapons); Push ignores the SRD's
  "Large or smaller" size restriction (size isn't tracked); Cleave/Push
  needed `resolveAttack()` to gain an optional trailing `state` parameter
  for grid/multi-opponent access — defaults to `{}` so every existing call
  site (including all prior unit tests) is unaffected.

18 new unit tests added (`CombatServiceSpec.bx`) covering all of the above;
live-verified end-to-end via the debug-handler pattern (a real Rogue/
Barbarian/Fighter loaded from the DB, Expertise chosen, Sneak Attack/Rage/
Second Wind/Sap all fired correctly), then the debug code was fully reverted.

## 7b. Paladin's Smite, and a level-up spell-slot staleness bug found while adding it
Reported: "Paladin's Smite is not showing for paladin in combat actions."
Investigating turned up two separate issues:

- **Paladin's Smite itself was simply never implemented — resolved.**
  `smiteAttack( state, slotLevel )` makes one melee weapon attack (reusing
  `playerAttack()`) and, only if it actually hits, spends a spell slot at
  the chosen level for Divine Smite's bonus Radiant damage: 2d8 for a
  1st-level slot, +1d8 per level above 1st (capped at 5d8), +1 further d8
  against a Fiend or Undead. No slot is spent on a miss. The combat screen
  shows one "Smite (Lv N)" button per available slot level, right next to
  Attack, for a character with the "Paladin's Smite" feature and a melee
  weapon equipped. **Simplified** from the real rule (which lets you decide
  to smite *after* seeing the attack roll) into "commit before you know if
  you'll hit" — functionally identical in outcome, since a miss never costs
  a slot either way, and this app has no other precedent for a post-roll
  prompt to hang the real version off of.
- **Follow-up bug, found while live-verifying the above — resolved.**
  `_levelUp()` never recomputed `player.spellSlots` after incrementing
  `player.level`, only `_assignSpellcasting()` did (called from
  `loadCharacter()`/`longRest()`, i.e. only at the *start* of an encounter).
  A level-up happening mid-encounter — e.g. a Paladin reaching level 2 (and
  thus their first spell slot, and Paladin's Smite's only usable resource)
  by finishing off the monster in front of them — left `player.spellSlots`
  exactly as stale as it was at load time (often `{}`) for the rest of that
  encounter: every spell/cantrip/Smite button that depends on having a slot
  available would silently stay hidden until the player left combat and a
  fresh `loadCharacter()` recomputed it correctly. This affected every
  caster leveling up mid-fight, not just Paladins. Fixed by factoring the
  slot-table computation out into `_recomputeSpellSlots()`, shared by both
  `_assignSpellcasting()` and `_levelUp()`. Verified live: a level-1 Paladin
  given enough XP to reach level 5 in one `awardExperience()` call
  correctly ended up with `spellSlots = {"1":4, "2":1}` (previously `{}`),
  and could immediately Smite with the newly-available level-2 slot in the
  same encounter.

7 new unit tests added for `smiteAttack()`; the spell-slot staleness fix
has no automated test (would require a real DB-backed character via
`awardExperience()`, which this spec file's own header explicitly avoids
for kill/XP paths — same reasoning applies to level-up) — verified live only.

## 8. Subclasses were never assigned or granted
**Resolved, and made a real player choice (not auto-picked).** Every class
in this SRD dataset has exactly one subclass, unlocking at level 3
(confirmed via `MIN(class_features.level) WHERE subclass_id IS NOT NULL`,
grouped by class — all twelve are 3). `characters.subclass_id` existed but
was never set, and `_grantNewFeatures()`'s query explicitly excluded
`cf.subclass_id IS NOT NULL` rows — so no character ever received subclass
features (Fighter's Champion, Rogue's Thief, etc.), regardless of level.
`CombatService.pendingSubclassChoice(characterId)` now detects when a
character has reached the unlock level without a subclass chosen, and the
character sheet shows a "Choose Your Subclass" panel (`chooseSubclass()`)
— **skippable**: leaving it unchosen just means the panel reappears next
visit, no default gets assigned. Choosing retroactively grants every
subclass feature up to the character's current level, so leveling well
past 3 before deciding still works correctly. Verified live: a Rogue
leveled to 5 without choosing (panel persisted, pending stayed true), then
chose Thief and correctly received all 4 of its features (levels 1-3) in
one shot.

## 9. No feat-instead-of-Ability-Score-Improvement choice
**Resolved.** `applyAbilityScoreImprovement()`'s doc comment used to say
outright "this app doesn't model the alternative... since it has no
broader feat-selection UI at all." The level-up screen (`default.bxm`) now
has a third option, "Take a feat instead", offering
`CombatService.LEVEL_UP_FEAT_NAMES` (Alert, Grappler, Magic Initiate,
Savage Attacker, Skilled — the 5 feats with a real mechanical hook
elsewhere in `CombatService.bx`; the 6 "Boon of ..." epic-boon feats and
plain "Ability Score Improvement" as a feat have none and aren't offered).
`availableLevelUpFeats()` excludes a non-repeatable feat already held.
**Skilled** grants a real player choice of 3 skills via a secondary picker
(`asiSelectedSkills`/`toggleAsiSkill()`) rather than auto-picking — it had
no mechanical hook at all before this. Known limitation: `character_feats`
has a `UNIQUE(character_id, feat_id)` constraint, so re-taking a repeatable
feat (Magic Initiate, Skilled) at a later ASI doesn't add a second row —
Skilled's mechanical effect (3 more skills) still applies correctly since
that doesn't depend on the row existing twice, but there's no "times taken"
counter for feats that would need one.

## 10. Fighting Style and Half-Elf's Skill Versatility were auto-picked
**Resolved** (per the "never auto-assign a player choice" rule — see
memory). Two more silent auto-picks converted to real UI:
- **Fighting Style** (Fighter level 1, Fighter's "Additional Fighting
  Style" level 7, Paladin/Ranger level 2): used to auto-pick Archery/Great
  Weapon Fighting/Defense by equipped weapon type. `grantFightingStyle()`
  now takes an explicit style name instead of choosing one; the wizard's
  Class step shows a picker for Fighter's level-1 grant, and
  `CombatService.pendingFightingStyleChoice(characterId)` drives a
  character-sheet panel (same skippable/revisitable pattern as subclass,
  since it compares "how many Fighting-Style-granting features unlocked"
  vs. "how many Fighting Style feats actually chosen" rather than a
  one-shot flag) for the level-2/level-7 grants.
- **Skill Versatility** (Half-Elf's "2 skills of your choice"): used to
  auto-grant Insight+Perception via `TRAIT_SKILL_GRANTS`. Now a real
  picker on the Origin step (`selectedSpeciesSkills`/`toggleSpeciesSkill()`),
  driven by `CombatService.speciesSkillChoiceCount()`/`TRAIT_SKILL_CHOICE_COUNTS`
  and `allSkillNames()`. Stored in the same `chosen_skill_proficiencies`
  column as a class's chosen skills.

## 11. Combat service coverage audit (what CombatService.bx doesn't do)
Full survey, grepping actual call sites rather than assuming — everything
below is confirmed absent, not a guess:

- **Conditions: was 4 of 15, now 11 of 15 — resolved except Charmed,
  Deafened, and Exhaustion.** `CombatService.bx` now has `isIncapacitated()`
  (Incapacitated itself, or any condition whose own rules text includes
  it) and `isHelpless()`/`cantMove()` (Paralyzed, Petrified, Stunned,
  Unconscious — the four that also grant attackers Advantage, auto-fail
  the defender's Str/Dex saves, and lock Speed to 0):
    - **Blinded**: Disadvantage on the Blinded creature's own attacks;
      Advantage on attacks against it (`resolveAttack()`).
    - **Invisible**: the mirror image — Advantage on its own attacks,
      Disadvantage on attacks against it.
    - **Incapacitated** (+ Paralyzed/Petrified/Stunned/Unconscious, which
      include it): blocks the player's manual actions (`attack()`,
      `attemptGrapple()`, `attemptShove()`, `useBreathWeapon()`,
      `castCantrip()`, `castLeveledSpell()`, `offHandAttack()`, and
      mid-combat `useItem()` in `default.bx`), a Reaction
      (`checkOpportunityAttacks()`), and the enemy AI's entire turn
      (`_runOneOpponentTurn()`).
    - **Paralyzed/Petrified/Stunned/Unconscious**: Advantage to attacks
      against them (`resolveAttack()`), auto-fail Strength/Dexterity saves
      (`rollSavingThrow()`), Speed locked to 0 (`cantMove()`, used by
      `moveToward()`/`movePlayer()`/`tileReachable()` — extended from the
      Restrained-only check those already had).
    - **Paralyzed/Unconscious specifically**: any melee hit against them is
      an automatic Critical Hit (simplified from the SRD's "within 5 feet"
      to "any melee attack," since this app doesn't model reach weapons —
      melee already implies adjacency).
    - **Petrified**: resistance to all damage regardless of type (on top of
      the Advantage/auto-fail-save/no-movement effects above).

  Verified live: a Stunned opponent's turn is skipped entirely
  ("is incapacitated and can't act", no movement); a Petrified defender's
  attack log shows "(Advantage)" and correctly halves 10 flat damage to 5.
  9 new unit tests added.

  **Still unimplemented, deliberately:**
    - **Charmed** — RAW only blocks attacking *the specific charmer*, which
      needs source-creature tracking `addCondition()`'s `data` payload was
      never actually wired up for (same gap Frightened already had,
      simplified away there too) — and nothing in the game casts a Charm
      effect to test against, so a real implementation can't be verified
      end-to-end right now.
    - **Deafened** — fails ability checks requiring hearing; no such check
      exists anywhere in this game (same "no system to gate it" reasoning
      as most of #3/#11's skill-check gap).
    - **Exhaustion** — structurally different (6 cumulative numeric levels,
      not a boolean flag) and nothing currently grants it, so implementing
      the level-scaled effects (disadvantage on ability checks/attacks/
      saves, Speed halved then zeroed, HP max halved, death at 6) would be
      "correct but unreachable" scaffolding, same as the dead Boon feats —
      lowest priority of the three.
- **Spellcasting depth and concentration — resolved.** A character can now
  know more than one cantrip/leveled spell (`characters.known_cantrips`/
  `known_spells`, comma-separated lists — migration `012_multi_spell_known.sql`
  replaced the old single `known_cantrip`/`known_spell` columns).
  `CombatService._assignSpellcasting()` resolves every stored name into a
  full spell struct (via `lookupSpellByName()`), falling back to the old
  iconic/heal-preferring single auto-pick only when nothing's been chosen
  yet (a fresh caster, or Magic Initiate). `castCantrip(state, name)`/
  `castLeveledSpell(state, name)` take an optional exact spell name
  (defaulting to the first known one) so a caster with several known spells
  can pick which to cast — `default.bxm` now renders one Cast button per
  known cantrip/spell instead of a single fixed one.
    - **Learning new spells is a real, skippable/revisitable choice, never
      auto-granted** (per the standing "never auto-assign" rule) —
      `CombatService.pendingCantripChoice()`/`pendingSpellChoice()` compare
      how many cantrips/spells-of-the-current-max-slot-level a character
      *should* know at their level against how many they actually do, and
      `chooseCantrip()`/`chooseSpell()` (thin `CharacterService` wrappers)
      append the pick without ever replacing an existing one. Surfaced as
      "Learn a Cantrip"/"Learn a Level N Spell" panels on the character
      sheet, mirroring the existing subclass/fighting-style panels.
      **Deliberate simplification**: cantrips-known-by-level
      (`_expectedCantripCount()`) uses one uniform curve (2/3/4 at levels
      1/4/10) instead of each class's exact SRD table, and "how many spells
      known" uses "at least one known spell of the current max slot level"
      rather than the SRD's real per-class/per-level spells-known counts —
      consistent with how this app already treated spells-known before this
      fix (a single starting pick, not a tracked count).
    - The character sheet's existing "change your starting cantrip/spell"
      picker (`updateSpellChoices()`) still only edits the first (starting)
      list entry — spells learned later via the pending-choice panel are
      never touched by it.
    - **Follow-up fix**: the auto-pick fallback in `_assignSpellcasting()`
      originally applied to *any* class with no chosen cantrip/spell,
      including the half-casters (Paladin, Ranger) — who never get a
      creation-time Spells step at all (that step is full-caster only,
      correctly, since a half-caster has no spells until level 2). The
      practical effect: a level-2+ Paladin/Ranger was silently handed an
      auto-picked spell (e.g. Bless) every time they loaded, at the same
      time `pendingSpellChoice()` was *also* showing them a "Learn a
      Spell" panel — i.e. the choice panel existed, but wasn't actually
      gating anything, violating the "never auto-assign" rule. Fixed by
      gating the auto-pick fallback to `isFullCaster` (plus the existing
      Magic Initiate branch, unchanged) — a half-caster with nothing
      chosen now genuinely knows no spells until they use the pending-
      choice panel. Verified live: a fresh level-2 Paladin loads with
      empty `knownLeveledSpells`/`knownCantrips`, `pendingCantripChoice()`
      correctly never applies (Paladins get no cantrips), and
      `pendingSpellChoice()` offers their real level-1 spell list.
- **Concentration is now tracked, with one known limitation.**
  `_startConcentrating()`/`_checkConcentration()` implement the real rule:
  casting a `concentration: true` spell replaces whatever the caster was
  already concentrating on (logged, not silently dropped); taking damage
  triggers a Constitution save (DC = max(10, damage/2)) that ends
  concentration on a failure. Wired into every damage-application site (weapon
  attacks, spell attacks, breath weapons, monster special/legendary attacks).
  **Limitation, unchanged from before**: no spell in this app's data models a
  sustained combat effect (no Bless/Hunter's Mark-style ongoing buff), so
  losing concentration is currently bookkeeping + a log line, not an actual
  effect removal — there's nothing yet for it to remove.
- **No multiclassing** — one `class_id` per character, period.
- **Most granted class features are still name-only** (see #7/#7a/#7b) — as
  of #7b, `Extra Attack`/`Two Extra Attacks`/`Three Extra Attacks`,
  `Fighting Style`, `Ability Score Improvement`, `Rage`, `Sneak Attack`,
  `Second Wind`, `Expertise`, `Weapon Mastery`, and `Paladin's Smite` are
  read by name and have real mechanics. Everything else — each class's own
  "Spellcasting" feature row (spellcasting itself works, just independently
  of this feature row — see `_assignSpellcasting()`), Channel Divinity,
  Metamagic, Wild Shape, Cunning Action, Stunning Strike, Divine Order,
  Bardic Inspiration, and
  the ~100 other higher-level/subclass feature names across all 12
  classes — is still flavor-only.
- **6 of 17 feats are dead data** — the "Boon of ..." epic-boon feats
  (Combat Prowess, Dimensional Travel, Fate, Irresistible Offense, the
  Night Spirit, Truesight) have no grant path and no mechanical hook.
- **Most species traits are still flavor-only** (see #3) — 7 of ~19 affect
  combat; Stonecunning, Trance, Halfling Nimbleness, Naturally Stealthy,
  Infernal Legacy, Elf Weapon Training, Cantrip, Extra Language,
  Artificer's Lore, Tinker do nothing.
- **`rollSkillCheck()` has exactly one caller** — Athletics/Acrobatics in
  `attemptGrapple()`/`attemptShove()`. Perception, Stealth, Insight,
  Persuasion, etc. are proficiency-tracked but never rolled for anything
  (same gap as #2).
- **No vision/lighting model** — Darkvision is stored per species but
  nothing in combat cares about light level, hidden enemies, or a surprise
  round.

Everything else — attacks, saving throws, death saves, initiative,
opportunity attacks, legendary actions, Parry, Magic Resistance, cover,
grapple/shove, leveling/HP/proficiency progression, ASI-or-feat,
subclass/fighting-style choice, 11 of 15 conditions, spellcasting depth/
concentration, and (as of this update) Rage/Sneak Attack/Second Wind/
Expertise/Weapon Mastery — is real and working; this list is specifically
what isn't.

**Known flaky test (pre-existing, unrelated to any fix above)**:
"does not auto-crit a ranged hit against a Paralyzed defender"
(`CombatServiceSpec.bx`) occasionally fails when a natural 20 crit lands
and doubles the 1-damage roll to 2 — the test doesn't account for its own
~5% crit chance. Same root cause as the other previously-noted flaky test
("doubles damage against a vulnerable damage type").

## 12. Short Rest / Long Rest had no real time cost — resolved
Previously: Short Rest and Long Rest could be taken freely, any number of
times, any time the player wasn't in combat — Long Rest in particular could
be spammed back-to-back for a full, instant, unlimited reset. Meanwhile a
whole set of resources (Rage uses, Second Wind, Breath Weapon, Relentless
Endurance, Heroic Inspiration, Magic Initiate's bonus spell) silently reset
on every fresh encounter load instead of on an actual rest, which was
itself a documented simplification ("no long-rest tracking across
encounters exists here"). Requested: wire rest to the actual SRD rules,
using the fact that a combat round is ~6 seconds as the base unit.

**Resolved.** Migration `014_rest_and_game_clock.sql` adds a persisted
in-game clock (`characters.game_clock_seconds`) plus the columns needed to
carry the resources below across encounters (`rages_used`,
`used_second_wind`, `used_breath_weapon`, `used_relentless_endurance`,
`used_heroic_inspiration`, `used_magic_initiate_spell`,
`last_long_rest_seconds`).

- **The clock**: `startNewRound()` advances it by `SECONDS_PER_ROUND` (6)
  every combat round, so the passage of time in a fight is reflected
  too, not just during rests.
- **Short Rest** (`shortRest(player, diceCount)`): now a real ~1-hour
  activity — advances the clock by `SHORT_REST_SECONDS` (3600) regardless
  of how many Hit Dice are spent, matching the SRD's "spend one or more
  Hit Dice as part of the same 1-hour rest" (previously each hit-die-spend
  click was implicitly its own separate, free, instant rest). `diceCount`
  can be 0 — still worth taking purely to recover Second Wind and one Rage
  use, per those features' own "regain ... when you finish a Short Rest"
  text.
- **Long Rest** (`longRest(player)`): now an 8-hour activity
  (`LONG_REST_SECONDS`) that's blocked — a no-op, returning
  `{success:false, hoursUntilNext}` — if one was already completed within
  the last 24 in-game hours (`LONG_REST_COOLDOWN_SECONDS`,
  `hoursUntilNextLongRest()`), per the "can't benefit from more than one
  Long Rest in a 24-hour period" rule. On success, also now resets every
  Long-Rest-only resource below (previously only HP/hit dice/spell slots).
- **Rage/Second Wind/Breath Weapon/Relentless Endurance/Heroic
  Inspiration/Magic Initiate's bonus spell**: all now persist across
  encounters (`loadCharacter()` reads their real state instead of
  hardcoding it fresh every load) and only recharge via an actual rest —
  Second Wind and one Rage use on a Short Rest, everything on a Long Rest,
  exactly matching each feature's own SRD text. `_recomputeRagesRemaining()`
  mirrors the existing `_recomputeSpellSlots()` pattern (derives the
  displayed `ragesRemaining` from the persisted `ragesUsed` count and the
  level-based max), called on load, on level-up, and after any rest.
- **UI** (`default.bxm`): the Rest panel now shows a "Day N, HH:MM"
  in-game-clock reading, a +/- stepper for how many Hit Dice to spend on
  the next Short Rest (rather than one hit-die-spend button per click),
  and disables/annotates the Long Rest button with an ETA
  (`hoursUntilNextLongRest()`) while its cooldown is active.

15 new unit tests added covering the clock tick, multi-die Short Rest
healing, resource recharge timing (Short vs. Long Rest), and the 24-hour
Long Rest cooldown (both blocked and allowed-again cases); live-verified
end-to-end via the debug-handler pattern (5 simulated combat rounds ticking
the clock, a 2-die Short Rest, a successful Long Rest, an immediately-
blocked second Long Rest, and a third Long Rest succeeding again after
simulating 25 more in-game hours), then the debug code was fully reverted.

**Deliberate simplifications kept**: no downtime/travel time model outside
of combat and rests (the clock only advances via combat rounds and the two
rest actions themselves — walking around the dungeon between fights costs
no time); Short Rest has no upper limit on how many can be taken per day
(matches RAW, which only limits Long Rest); exhaustion/food/water aren't
modeled, so nothing else currently reads the clock besides rest gating.

**Follow-up regression, found and fixed same day**: reported as "started a
new battle with 0 HP." `default.bx`'s `onMount()` auto-heals a character
who loads at 0 HP (persisted from a defeat, or from being stabilized-but-
unconscious) by calling `longRest()` — but once the 24-hour cooldown
existed, that call could now silently fail (`{success:false}`) if the
player had genuinely taken a Long Rest within the last 24 in-game hours
before their defeat, leaving them stuck at 0 HP with no way to recover
(`canRest()` also blocks manual resting immediately post-defeat). Fixed by
adding `longRest(player, ignoreCooldown)` — `onMount()`'s auto-heal now
passes `true`, bypassing the gate, while the player-facing Rest panel's
`takeLongRest()` still always respects it. 1 new unit test added; verified
live (a character with a recent Long Rest, defeated and reloaded at 0 HP,
now correctly heals to full despite being within the cooldown window).

## 13. Defeated mobs stayed in the sidebar forever, ungracefully grayed out
Requested: a smooth blink-then-disappear animation for a defeated mob's
sidebar card, and defeated opponents should stop appearing in the sidebar
entirely (previously they showed forever, `stat-card-down`-grayed, once
downed — `default.bx`'s `_updateCombatState()` forced `opp.visible = true`
unconditionally on death with no expiry).

**Resolved.** `CombatService._checkDefenderDefeated()` (the single place
every death path already funnels through — direct hits, Cleave's second
target, opportunity attacks, everything) now stamps
`defender.defeatedAtRound = state.round` the moment a monster is confirmed
dead (mirrored in `offHandAttack()`'s separate inline defeat-check, the one
death path that doesn't go through `_checkDefenderDefeated()`). The
sidebar's per-foe `<bx:if>` in `default.bxm` now reads: show if alive, OR
if `defeatedAtRound == round` (i.e. only for the remainder of the round it
died in) — once the round advances, the card drops out of the render
entirely, no lingering forever-grayed corpse. A new `mob-defeated`
`@keyframes` animation (`Main.bxm`) — a couple of opacity blinks, then a
fade+shrink to invisible, `animation-fill-mode: forwards` — plays via a new
`.stat-card-defeated` class added alongside the existing `.stat-card-down`
the instant a foe's HP hits 0. Since CBWIRE (like Livewire) patches the DOM
rather than replacing it, the animation fires once when the class first
appears and simply holds its end state on any subsequent re-render with an
unchanged class list — no JS needed.

1 new unit test added (`defeatedAtRound` gets stamped on the mob that died,
not on one that's still alive, in a multi-mob encounter). **Not** visually
verified in a live browser session — reaching an actual kill in the
running dev character's current dungeon session was taking too many
exploration turns to be worth the time in this pass; the change is a
straightforward, deterministic template conditional plus standard CSS
keyframes, and is covered by the round-tracking unit test above, but
actually watching the blink-and-fade animation play in a browser is still
worth doing before calling this fully done.

**Follow-up, same feature area:** the original animation's triple opacity
blink read as jarring rather than smooth. Replaced `mob-defeated`'s
keyframes (`Main.bxm`) with a single-pass sequence — one brief red
`box-shadow` flash to register the kill, a short hold, then one continuous
fade + slight shrink + grayscale to invisible — instead of oscillating
opacity three times.

## 14. Spell slots weren't visible during combat, and unaffordable spells could still be "cast"
The action bar gave no indication of remaining spell slots, and a caster
could click "Cast [spell]" for a spell whose level they had no slots left
for (the attempt would just silently no-op inside `_castLeveledSpellFor()`).

**Resolved.** `CombatService._hasSpellResource()` (previously used only by
the enemy AI to decide whether casting was worth attempting) was made
public as `hasSpellResource()` and reused by the wire/template: `default.bxm`
now renders a chip row above the action bar (one chip per spell level the
caster has, dimmed once that level is fully spent) and disables a leveled
spell's "Cast" button (with a tooltip) once `hasSpellResource()` is false
for its level. Cantrip buttons are untouched since they don't consume slots.

5 new unit tests for `hasSpellResource()`. **Not** visually verified in a
live browser session, for the same reason as #13 — the change is template
markup gated by an already-tested pure function, but seeing the chip
styling and disabled-button state actually render is still worth a quick
look.

## 15. Auto-battle could get stuck running forever on some maps
Reported: on some maps, auto-battle stayed active indefinitely even after
the only reachable mob was defeated. Root cause: a remaining opponent
positioned somewhere the player's pathfinding can't reach (e.g. water-only
terrain a land-bound character can't cross, or a maze pocket with no route
through) — and symmetrically, that opponent often can't reach the player
either. Neither `playerDecideAndAct()` nor `_runOneOpponentTurn()` treat
"can't reach" as an error, so the fight just logged "can't reach" every
round forever with `wire:poll` calling `autoStep()` forever alongside it.

**Resolved.** Added `state.roundHadAction`, set `true` at every point a
combatant actually lands an attack, casts a spell, or uses a special
attack (`playerDecideAndAct()`, the opponent weapon-attack loop,
`_useMonsterSpecialAttack()`, `_castCantripFor()`/`_castLeveledSpellFor()`),
and reset to `false` at the top of `startNewRound()`. `default.bx`'s
`autoStep()` now tracks `staleAutoRounds`, incrementing it whenever a full
round completes with `roundHadAction` still false and resetting it to 0
otherwise; after 3 consecutive dead rounds it stops auto-battle and logs
"Auto-battle stopped — no one can reach an opponent. Try moving manually."
so the player regains manual control instead of it spinning forever. This
only affects auto-battle's own stopping condition — movement/pathing
itself (and why a mob ended up somewhere unreachable in the first place)
is unchanged.

3 new/updated unit tests confirm `roundHadAction` is set on a landed
attack, stays false on a move-only/no-reach turn, and is reset by
`startNewRound()`. Also live-verified end-to-end via a temporary debug
handler that reproduced the exact reported scenario (a Giant Sea Horse
sealed off from the player by a wall with no gap) and ran the real
`autoStep()`-equivalent loop against production `CombatService` code —
confirmed `staleAutoRounds` reaches 3 and auto-battle stops itself with
neither side ever able to land a hit, then removed the debug code
(verified via `diff` against the committed version).

## Priority if picked back up
1. #1 — needs a decision (schema extension vs. staying 2014-pure) before any code.
2. Full mechanics for the remaining ~100 inert class feature names (see
   #7/#7a/#11) — Channel Divinity, Metamagic, Wild Shape, Cunning Action,
   Stunning Strike, and every other higher-level/subclass feature across
   all 12 classes — is the largest remaining item, effectively "implement
   the rest of each class's gameplay loop," not a quick follow-up. Rage/
   Sneak Attack/Second Wind/Expertise/Weapon Mastery are done (#7a).
3. A new non-combat gameplay moment (Perception/Insight/Stealth check) for
   `rollSkillCheck()` to gate is still open from #2, and still additive.
4. Multiclassing and the remaining conditions (Charmed/Deafened/Exhaustion)
   are the next-biggest gaps after class feature mechanics.
5. Charmed, Deafened, Exhaustion (#11) and the 6 dead-data Boon feats only
   matter once something in the game actually inflicts/offers them — low
   priority until paired with new monster abilities or the feat list
   actually growing.
