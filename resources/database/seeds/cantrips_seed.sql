
-- spells ----------------------------------------------------------------
INSERT INTO spells (name, level, school, classes, casting_time, `range`, components, duration, description, higher_level_text) VALUES ('Acid Splash', 0, 'Evocation', 'Sorcerer, Wizard', 'Action', '60 feet', 'V, S', 'Instantaneous', 'You create an acidic bubble at a point within range, where it explodes in a 5-foot-radius Sphere. Each creature in that Sphere must succeed on a Dexterity saving throw or take 1d6 Acid damage.

_Cantrip Upgrade._ The damage increases by 1d6 when you reach levels 5 (2d6), 11 (3d6), and 17 (4d6).', NULL);
INSERT INTO spells (name, level, school, classes, casting_time, `range`, components, duration, description, higher_level_text) VALUES ('Chill Touch', 0, 'Necromancy', 'Sorcerer, Warlock, Wizard', 'Action', 'Touch', 'V, S', 'Instantaneous', 'Channeling the chill of the grave, make a melee spell attack against a target within reach. On a hit, the target takes 1d10 Necrotic damage, and it can\'t regain Hit Points until the end of your next turn.

_Cantrip Upgrade._ The damage increases by 1d10 when you reach levels 5 (2d10), 11 (3d10), and 17 (4d10).', NULL);
INSERT INTO spells (name, level, school, classes, casting_time, `range`, components, duration, description, higher_level_text) VALUES ('Dancing Lights', 0, 'Illusion', 'Bard, Sorcerer, Wizard', 'Action', '120 feet', 'V, S, M (a bit of phosphorus)', 'Concentration, up to 1 minute', 'You create up to four torch-size lights within range, making them appear as torches, lanterns, or glowing orbs that hover for the duration. Alternatively, you combine the four lights into one glowing Medium form that is vaguely humanlike. Whichever form you choose, each light sheds Dim Light in a 10-foot radius.

As a Bonus Action, you can move the lights up to 60 feet to a space within range. A light must be within 20 feet of another light created by this spell, and a light vanishes if it exceeds the spell\'s range.', NULL);
INSERT INTO spells (name, level, school, classes, casting_time, `range`, components, duration, description, higher_level_text) VALUES ('Druidcraft', 0, 'Transmutation', 'Druid', 'Action', '30 feet', 'V, S', 'Instantaneous', 'Whispering to the spirits of nature, you create one of the following effects within range.

_Weather Sensor._ You create a Tiny, harmless sensory effect that predicts what the weather will be at your location for the next 24 hours. The effect might manifest as a golden orb for clear skies, a cloud for rain, falling snowflakes for snow, and so on. This effect persists for 1 round.

_Bloom._ You instantly make a flower blossom, a seed pod open, or a leaf bud bloom.

_Sensory Effect._ You create a harmless sensory effect, such as falling leaves, spectral dancing fairies, a gentle breeze, the sound of an animal, or the faint odor of skunk. The effect must fit in a 5-foot Cube.

_Fire Play._ You light or snuff out a candle, a torch, or a campfire.', NULL);
INSERT INTO spells (name, level, school, classes, casting_time, `range`, components, duration, description, higher_level_text) VALUES ('Eldritch Blast', 0, 'Evocation', 'Warlock', 'Action', '120 feet', 'V, S', 'Instantaneous', 'You hurl a beam of crackling energy. Make a ranged spell attack against one creature or object in range. On a hit, the target takes 1d10 Force damage.

_Cantrip Upgrade._ The spell creates two beams at level 5, three beams at level 11, and four beams at level 17. You can direct the beams at the same target or at different ones. Make a separate attack roll for each beam.', NULL);
INSERT INTO spells (name, level, school, classes, casting_time, `range`, components, duration, description, higher_level_text) VALUES ('Elementalism', 0, 'Transmutation', 'Druid, Sorcerer, Wizard', 'Action', '30 feet', 'V, S', 'Instantaneous', 'You exert control over the elements, creating one of the following effects within range.

_Beckon Air._ You create a breeze strong enough to ripple cloth, stir dust, rustle leaves, and close open doors and shutters, all in a 5-foot Cube. Doors and shutters being held open by someone or something aren\'t affected.

_Beckon Earth._ You create a thin shroud of dust or sand that covers surfaces in a 5-foot-square area, or you cause a single word to appear in your handwriting in a patch of dirt or sand.

_Beckon Fire._ You create a thin cloud of harmless embers and colored, scented smoke in a 5-foot Cube. You choose the color and scent, and the embers can light candles, torches, or lamps in that area. The smoke\'s scent lingers for 1 minute.

_Beckon Water._ You create a spray of cool mist that lightly dampens creatures and objects in a 5-foot Cube. Alternatively, you create 1 cup of clean water either in an open container or on a surface, and the water evaporates in 1 minute.

_Sculpt Element._ You cause dirt, sand, fire, smoke, mist, or water that can fit in a 1-foot Cube to assume a crude shape (such as that of a creature) for 1 hour.', NULL);
INSERT INTO spells (name, level, school, classes, casting_time, `range`, components, duration, description, higher_level_text) VALUES ('Fire Bolt', 0, 'Evocation', 'Sorcerer, Wizard', 'Action', '120 feet', 'V, S', 'Instantaneous', 'You hurl a mote of fire at a creature or an object within range. Make a ranged spell attack against the target. On a hit, the target takes 1d10 Fire damage. A flammable object hit by this spell starts burning if it isn\'t being worn or carried.

_Cantrip Upgrade._ The damage increases by 1d10 when you reach levels 5 (2d10), 11 (3d10), and 17 (4d10).', NULL);
INSERT INTO spells (name, level, school, classes, casting_time, `range`, components, duration, description, higher_level_text) VALUES ('Guidance', 0, 'Divination', 'Cleric, Druid', 'Action', 'Touch', NULL, 'Concentration, up to 1 minute', 'You touch a willing creature and choose a skill. Until the spell ends, the creature adds 1d4 to any ability check using the chosen skill.', NULL);
INSERT INTO spells (name, level, school, classes, casting_time, `range`, components, duration, description, higher_level_text) VALUES ('Light', 0, 'Evocation', 'Bard, Cleric, Sorcerer, Wizard', 'Action', 'Touch', 'V, M (a firefly or phosphorescent moss)', '1 hour', 'You touch one Large or smaller object that isn\'t being worn or carried by someone else. Until the spell ends, the object sheds Bright Light in a 20-foot radius and Dim Light for an additional 20 feet. The light can be colored as you like.

Covering the object with something opaque blocks the light. The spell ends if you cast it again.', NULL);
INSERT INTO spells (name, level, school, classes, casting_time, `range`, components, duration, description, higher_level_text) VALUES ('Mage Hand', 0, 'Conjuration', 'Bard, Sorcerer, Warlock, Wizard', 'Action', '30 feet', 'V, S', '1 minute', 'A spectral, floating hand appears at a point you choose within range. The hand lasts for the duration. The hand vanishes if it is ever more than 30 feet away from you or if you cast this spell again.

When you cast the spell, you can use the hand to manipulate an object, open an unlocked door or container, stow or retrieve an item from an open container, or pour the contents out of a vial.

As a Magic action on your later turns, you can control the hand thus again. As part of that action, you can move the hand up to 30 feet.

The hand can\'t attack, activate magic items, or carry more than 10 pounds.', NULL);
INSERT INTO spells (name, level, school, classes, casting_time, `range`, components, duration, description, higher_level_text) VALUES ('Mending', 0, 'Transmutation', 'Bard, Cleric, Druid, Sorcerer, Wizard', '1 minute', 'Touch', 'V, S, M (two lodestones)', 'Instantaneous', 'This spell repairs a single break or tear in an object you touch, such as a broken chain link, two halves of a broken key, a torn cloak, or a leaking wineskin. As long as the break or tear is no larger than 1 foot in any dimension, you mend it, leaving no trace of the former damage.

This spell can physically repair a magic item, but it can\'t restore magic to such an object.', NULL);
INSERT INTO spells (name, level, school, classes, casting_time, `range`, components, duration, description, higher_level_text) VALUES ('Message', 0, 'Transmutation', 'Bard, Druid, Sorcerer, Wizard', 'Action', '120 feet', 'S, M (a copper wire)', '1 round', 'You point toward a creature within range and whisper a message. The target (and only the target) hears the message and can reply in a whisper that only you can hear.

You can cast this spell through solid objects if you are familiar with the target and know it is beyond the barrier. Magical silence; 1 foot of stone, metal, or wood; or a thin sheet of lead blocks the spell.', NULL);
INSERT INTO spells (name, level, school, classes, casting_time, `range`, components, duration, description, higher_level_text) VALUES ('Minor Illusion', 0, 'Illusion', 'Bard, Sorcerer, Warlock, Wizard', 'Action', '30 feet', 'S, M (a bit of fleece)', '1 minute', 'You create a sound or an image of an object within range that lasts for the duration. See the descriptions below for the effects of each. The illusion ends if you cast this spell again.

If a creature takes a Study action to examine the sound or image, the creature can determine that it is an illusion with a successful Intelligence (Investigation) check against your spell save DC. If a creature discerns the illusion for what it is, the illusion becomes faint to the creature.

_Sound._ If you create a sound, its volume can range from a whisper to a scream. It can be your voice, someone else\'s voice, a lion\'s roar, a beating of drums, or any other sound you choose. The sound continues unabated throughout the duration, or you can make discrete sounds at different times before the spell ends.

_Image._ If you create an image of an object—such as a chair, muddy footprints, or a small chest—it must be no larger than a 5-foot Cube. The image can\'t create sound, light, smell, or any other sensory effect. Physical interaction with the image reveals it to be an illusion, since things can pass through it.', NULL);
INSERT INTO spells (name, level, school, classes, casting_time, `range`, components, duration, description, higher_level_text) VALUES ('Poison Spray', 0, 'Necromancy', 'Druid, Sorcerer, Warlock, Wizard', 'Action', '30 feet', 'V, S', 'Instantaneous', 'You spray toxic mist at a creature within range. Make a ranged spell attack against the target. On a hit, the target takes 1d12 Poison damage.

_Cantrip Upgrade._ The damage increases by 1d12 when you reach levels 5 (2d12), 11 (3d12), and 17 (4d12).', NULL);
INSERT INTO spells (name, level, school, classes, casting_time, `range`, components, duration, description, higher_level_text) VALUES ('Prestidigitation', 0, 'Transmutation', 'Bard, Sorcerer, Warlock, Wizard', 'Action', '10 feet', 'V, S', 'Up to 1 hour', 'You create a magical effect within range. Choose the effect from the options below. If you cast this spell multiple times, you can have up to three of its non-instantaneous effects active at a time.

_Sensory Effect._ You create an instantaneous, harmless sensory effect, such as a shower of sparks, a puff of wind, faint musical notes, or an odd odor.

_Fire Play._ You instantaneously light or snuff out a candle, a torch, or a small campfire.

_Clean or Soil._ You instantaneously clean or soil an object no larger than 1 cubic foot.

_Minor Sensation._ You chill, warm, or flavor up to 1 cubic foot of nonliving material for 1 hour.

_Magic Mark._ You make a color, a small mark, or a symbol appear on an object or a surface for 1 hour.

_Minor Creation._ You create a nonmagical trinket or an illusory image that can fit in your hand. It lasts until the end of your next turn. A trinket can deal no damage and has no monetary worth.', NULL);
INSERT INTO spells (name, level, school, classes, casting_time, `range`, components, duration, description, higher_level_text) VALUES ('Produce Flame', 0, 'Conjuration', 'Druid', 'Bonus Action', 'Self', 'V, S', '10 minutes', 'A flickering flame appears in your hand and remains there for the duration. While there, the flame emits no heat and ignites nothing, and it sheds Bright Light in a 20-foot radius and Dim Light for an additional 20 feet. The spell ends if you cast it again.

Until the spell ends, you can take a Magic action to hurl fire at a creature or an object within 60 feet of you. Make a ranged spell attack. On a hit, the target takes 1d8 Fire damage.

_Cantrip Upgrade._ The damage increases by 1d8 when you reach levels 5 (2d8), 11 (3d8), and 17 (4d8).', NULL);
INSERT INTO spells (name, level, school, classes, casting_time, `range`, components, duration, description, higher_level_text) VALUES ('Ray of Frost', 0, 'Evocation', 'Sorcerer, Wizard', 'Action', '60 feet', 'V, S', 'Instantaneous', 'A frigid beam of blue-white light streaks toward a creature within range. Make a ranged spell attack against the target. On a hit, it takes 1d8 Cold damage, and its Speed is reduced by 10 feet until the start of your next turn.

_Cantrip Upgrade._ The damage increases by 1d8 when you reach levels 5 (2d8), 11 (3d8), and 17 (4d8).', NULL);
INSERT INTO spells (name, level, school, classes, casting_time, `range`, components, duration, description, higher_level_text) VALUES ('Resistance', 0, 'Abjuration', 'Cleric, Druid', 'Action', 'Touch', NULL, 'Concentration, up to 1 minute', 'You touch a willing creature and choose a damage type: Acid, Bludgeoning, Cold, Fire, Lightning, Necrotic, Piercing, Poison, Radiant, Slashing, or Thunder. When the creature takes damage of the chosen type before the spell ends, the creature reduces the total damage taken by 1d4. A creature can benefit from this spell only once per turn.', NULL);
INSERT INTO spells (name, level, school, classes, casting_time, `range`, components, duration, description, higher_level_text) VALUES ('Sacred Flame', 0, 'Evocation', 'Cleric', 'Action', '60 feet', 'V, S', 'Instantaneous', 'Flame-like radiance descends on a creature that you can see within range. The target must succeed on a Dexterity saving throw or take 1d8 Radiant damage. The target gains no benefit from Half Cover or Three-Quarters Cover for this save.

_Cantrip Upgrade._ The damage increases by 1d8 when you reach levels 5 (2d8), 11 (3d8), and 17 (4d8).', NULL);
INSERT INTO spells (name, level, school, classes, casting_time, `range`, components, duration, description, higher_level_text) VALUES ('Shillelagh', 0, 'Transmutation', 'Druid', 'Bonus Action', 'Self', 'V, S, M (mistletoe)', '1 minute', 'A Club or Quarterstaff you are holding is imbued with nature\'s power. For the duration, you can use your spellcasting ability instead of Strength for the attack and damage rolls of melee attacks using that weapon, and the weapon\'s damage die becomes a d8. If the attack deals damage, it can be Force damage or the weapon\'s normal damage type (your choice).

The spell ends early if you cast it again or if you let go of the weapon.

_Cantrip Upgrade._ The damage die changes when you reach levels 5 (d10), 11 (d12), and 17 (2d6).', NULL);
INSERT INTO spells (name, level, school, classes, casting_time, `range`, components, duration, description, higher_level_text) VALUES ('Shocking Grasp', 0, 'Evocation', 'Sorcerer, Wizard', 'Action', 'Touch', 'V, S', 'Instantaneous', 'Lightning springs from you to a creature that you try to touch. Make a melee spell attack against the target. On a hit, the target takes 1d8 Lightning damage, and it can\'t make Opportunity Attacks until the start of its next turn.

_Cantrip Upgrade._ The damage increases by 1d8 when you reach levels 5 (2d8), 11 (3d8), and 17 (4d8).', NULL);
INSERT INTO spells (name, level, school, classes, casting_time, `range`, components, duration, description, higher_level_text) VALUES ('Sorcerous Burst', 0, 'Evocation', 'Sorcerer', 'Action', '120 feet', NULL, 'Instantaneous', 'You cast sorcerous energy at one creature or object within range. Make a ranged spell attack against the target. On a hit, the target takes 1d8 damage of a type you choose: Acid, Cold, Fire, Lightning, Poison, Psychic, or Thunder.

If you roll an 8 on a d8 for this spell, you can roll another d8, and add it to the damage. When you cast this spell, the maximum number of these d8s you can add to the spell\'s damage equals your spellcasting ability modifier.

_Cantrip Upgrade._ The damage increases by 1d8 when you reach levels 5 (2d8), 11 (3d8), and 17 (4d8).', NULL);
INSERT INTO spells (name, level, school, classes, casting_time, `range`, components, duration, description, higher_level_text) VALUES ('Spare the Dying', 0, 'Necromancy', 'Cleric, Druid', 'Action', '15 feet', 'V, S', 'Instantaneous', 'Choose a creature within range that has 0 Hit Points and isn\'t dead. The creature becomes Stable.

_Cantrip Upgrade._ The range doubles when you reach levels 5 (30 feet), 11 (60 feet), and 17 (120 feet).', NULL);
INSERT INTO spells (name, level, school, classes, casting_time, `range`, components, duration, description, higher_level_text) VALUES ('Starry Wisp', 0, 'Evocation', 'Bard, Druid', 'Action', '60 feet', 'V, S', 'Instantaneous', 'You launch a mote of light at one creature or object within range. Make a ranged spell attack against the target. On a hit, the target takes 1d8 Radiant damage, and until the end of your next turn, it emits Dim Light in a 10-foot radius and can\'t benefit from the Invisible condition.

_Cantrip Upgrade._ The damage increases by 1d8 when you reach levels 5 (2d8), 11 (3d8), and 17 (4d8).', NULL);
INSERT INTO spells (name, level, school, classes, casting_time, `range`, components, duration, description, higher_level_text) VALUES ('Thaumaturgy', 0, 'Transmutation', 'Cleric', 'Action', '30 feet', 'V', 'Up to 1 minute', 'You manifest a minor wonder within range. You create one of the effects below within range. If you cast this spell multiple times, you can have up to three of its 1-minute effects active at a time.

_Altered Eyes._ You alter the appearance of your eyes for 1 minute.

_Booming Voice._ Your voice booms up to three times as loud as normal for 1 minute. For the duration, you have Advantage on Charisma (Intimidation) checks.

_Fire Play._ You cause flames to flicker, brighten, dim, or change color for 1 minute.

_Invisible Hand._ You instantaneously cause an unlocked door or window to fly open or slam shut.

_Phantom Sound._ You create an instantaneous sound that originates from a point of your choice within range, such as a rumble of thunder, the cry of a raven, or ominous whispers.

_Tremors._ You cause harmless tremors in the ground for 1 minute.', NULL);
INSERT INTO spells (name, level, school, classes, casting_time, `range`, components, duration, description, higher_level_text) VALUES ('True Strike', 0, 'Divination', 'Bard, Sorcerer, Warlock, Wizard', 'Action', 'Self', 'S, M (a weapon with which you have proficiency and that is worth 1+ CP)', 'Instantaneous', 'Guided by a flash of magical insight, you make one attack with the weapon used in the spell\'s casting. The attack uses your spellcasting ability for the attack and damage rolls instead of using Strength or Dexterity. If the attack deals damage, it can be Radiant damage or the weapon\'s normal damage type (your choice).

_Cantrip Upgrade._ Whether you deal Radiant damage or the weapon\'s normal damage type, the attack deals extra Radiant damage when you reach levels 5 (1d6), 11 (2d6), and 17 (3d6).', NULL);
INSERT INTO spells (name, level, school, classes, casting_time, `range`, components, duration, description, higher_level_text) VALUES ('Vicious Mockery', 0, 'Enchantment', 'Bard', 'Action', '60 feet', 'V', 'Instantaneous', 'You unleash a string of insults laced with subtle enchantments at one creature you can see or hear within range. The target must succeed on a Wisdom saving throw or take 1d6 Psychic damage and have Disadvantage on the next attack roll it makes before the end of its next turn.

_Cantrip Upgrade._ The damage increases by 1d6 when you reach levels 5 (2d6), 11 (3d6), and 17 (4d6).', NULL);
