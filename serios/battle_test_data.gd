# battle_test_data.gd — test loadouts for the third-person siege sandbox.
# Power numbers are LOCKED values from GDD §5.1–5.3 (Common tier); names and
# attribute magnitudes are design placeholders.
# Controlled experiment: both heroes field IDENTICAL copies of the same two
# commanders (one Fire, one Light) so calculation output differences come
# purely from hero context (element match/mismatch, Fire▶Light ring, identity).
class_name BattleTestData

const COMMON_GEAR_TOTAL_PCT := 143.50   # GDD §5.3 (14,350 power)
const COMMANDER_PCT_EACH := 15.75       # GDD §5.2 Common (1,575 each)
const COMMANDER_SLOTS := 2              # GDD §5.2 Common
const TOTAL_POWER_PCT := 175.0          # 143.50 + 2 × 15.75 (17,500 power)

# Element superiority ring (locked): each element superior to exactly one
const SUPERIOR_TO := {
	"Earth": "Lightning",
	"Lightning": "Water",
	"Water": "Fire",
	"Fire": "Light",
	"Light": "Shadow",
	"Shadow": "Earth",
}

# Range counter triangle (locked): melee ▶ mid ▶ ranged ▶ melee
const RANGE_BEATS := {"melee": "mid", "mid": "ranged", "ranged": "melee"}

# GDD §5.3 Common tier per-item power values (percent)
const COMMON_GEAR_VALUES := {
	"Glyph": 34.44,
	"Weapon": 28.70,
	"Chest": 24.40,
	"Helmet": 17.22,
	"Gloves": 14.35,
	"Legs": 12.92,
	"Necklace": 7.18,
	"Ring": 4.30,
}

# The two shared commanders — identical copies on both heroes.
# Standardized attribute kit from Jaber's commander cards (2026-07-19).
# RULING: commanders always have exactly 3 attributes (Lv 1 / 5 / 10); the
# Lv 20 slot is the BOOSTER — it doubles one of the three, chosen at random
# per commander. The "Critical Damage @20" entry below stands in for the
# booster slot; both test commanders are below Lv 20 so it never activates.
const COMMANDERS := [
	{
		"name": "Vaelgor", "element": "Fire", "level": 12, "power_pct": 15.75,
		"attributes": [
			{"name": "Attack", "value": "+10%", "unlock": 1},
			{"name": "Physical Defense", "value": "+10%", "unlock": 5},
			{"name": "Max HP", "value": "+10%", "unlock": 10},
			{"name": "Critical Damage", "value": "+10%", "unlock": 20},
		],
	},
	{
		"name": "Aurelian", "element": "Light", "level": 11, "power_pct": 15.75,
		"attributes": [
			{"name": "Attack", "value": "+10%", "unlock": 1},
			{"name": "Physical Defense", "value": "+10%", "unlock": 5},
			{"name": "Max HP", "value": "+10%", "unlock": 10},
			{"name": "Critical Damage", "value": "+10%", "unlock": 20},
		],
	},
]

const HEROES := {
	"matches": {
		"name": "Matches",
		"element": "Fire",
		"tier": "Common",
		"identity": "Aggressive Mid-Ranged",
		"side": "Attacker",
		"troops": {"melee": 0.30, "mid": 0.50, "ranged": 0.20},
		"attributes": [
			{"name": "Mid-Range Attack Bonus", "value": "+18%"},
			{"name": "Attack Speed", "value": "+12%"},
			{"name": "Fire Element Power", "value": "+15%"},
		],
		"skills": {
			"hero": "Flashpoint",
			"weapon": "Searing Arc",
			"buff_trap": "Kindling Snare",
			"glyph": "Inferno Eruption",
		},
		"gear": [
			{"name": "Ember Seal", "slot": "Glyph", "pct": 34.44, "weight": 24, "skill": "Inferno Eruption",
				"attributes": [
					{"name": "Fire Attack", "mult": 0.75, "bucket": "element"},
					{"name": "Burn Resistance", "mult": 0.5, "bucket": "debuff_resist"},
					{"name": "Critical Damage", "mult": 0.6, "bucket": "crit"},
					{"name": "Attack", "mult": 0.5, "bucket": "attack"},
					{"name": "Max HP", "mult": 0.4, "bucket": "hp"},
				]},
			{"name": "Emberpike", "slot": "Weapon", "pct": 28.70, "weight": 20, "skill": "Searing Arc",
				"weapon_type": "Spear", "specialty": "Reach | Puncture",
				"attributes": [
					{"name": "Fire Attack", "mult": 0.8, "bucket": "element"},
					{"name": "Attack", "mult": 0.6, "bucket": "attack"},
					{"name": "Armor Penetration", "mult": 0.5, "bucket": "crit"},
					{"name": "Critical Damage", "mult": 0.4, "bucket": "crit"},
				]},
			{"name": "Ember Plate", "slot": "Chest", "pct": 24.40, "weight": 17,
				"attributes": [
					{"name": "Fire Resistance", "mult": 0.7, "bucket": "resist", "vs": "Fire"},
					{"name": "Defense", "mult": 0.6, "bucket": "defense"},
					{"name": "Max HP", "mult": 0.5, "bucket": "hp"},
					{"name": "Burn Resilience", "mult": 0.3, "bucket": "debuff_resist"},
				]},
			{"name": "Inferno Helm", "slot": "Helmet", "pct": 17.22, "weight": 12,
				"attributes": [
					{"name": "Fire Resistance", "mult": 0.8, "bucket": "resist", "vs": "Fire"},
					{"name": "Critical Damage", "mult": 0.6, "bucket": "crit"},
					{"name": "Max HP", "mult": 0.5, "bucket": "hp"},
				]},
			{"name": "Inferno Grips", "slot": "Gloves", "pct": 14.35, "weight": 10,
				"attributes": [
					{"name": "Fire Agility", "mult": 0.65, "bucket": "move"},
					{"name": "Critical Chance", "mult": 0.35, "bucket": "crit"},
				]},
			{"name": "Inferno Greaves", "slot": "Legs", "pct": 12.92, "weight": 9,
				"attributes": [
					{"name": "Molten Stride", "mult": 0.6, "bucket": "move"},
					{"name": "Burning Resolve", "mult": 0.4, "bucket": "defense"},
				]},
			{"name": "Inferno Amulet", "slot": "Necklace", "pct": 7.18, "weight": 5,
				"attributes": [
					{"name": "Fire Affinity", "mult": 1.0, "bucket": "element"},
				]},
			{"name": "Inferno Band", "slot": "Ring", "pct": 4.30, "weight": 3,
				"attributes": [
					{"name": "Blazing Fury", "mult": 1.0, "bucket": "attack"},
				]},
		],
	},
	"seer": {
		"name": "Seer",
		"element": "Light",
		"tier": "Common",
		"identity": "Defensive Melee",
		"side": "Defender",
		"troops": {"melee": 0.50, "mid": 0.20, "ranged": 0.30},
		"attributes": [
			{"name": "Melee Defense Bonus", "value": "+18%"},
			{"name": "Light Element Power", "value": "+15%"},
			{"name": "Trap Dismantle Chance", "value": "+10%"},
		],
		"skills": {
			"hero": "Aegis of Dawn",
			"weapon": "Radiant Edge",
			"buff_trap": "Blinding Ward",
			"glyph": "Radiant Judgement",
		},
		"gear": [
			{"name": "Lumen Crest", "slot": "Glyph", "pct": 34.44, "weight": 24, "skill": "Radiant Judgement",
				"attributes": [
					{"name": "Light Attack", "mult": 0.75, "bucket": "element"},
					{"name": "Divine Resistance", "mult": 0.5, "bucket": "resist", "vs": "Shadow"},
					{"name": "Critical Damage", "mult": 0.6, "bucket": "crit"},
					{"name": "Movement Speed", "mult": 0.5, "bucket": "move"},
					{"name": "Max HP", "mult": 0.4, "bucket": "hp"},
				]},
			{"name": "Sunblade", "slot": "Weapon", "pct": 28.70, "weight": 20, "skill": "Radiant Edge",
				"weapon_type": "Blade", "specialty": "Guard | Riposte",
				"attributes": [
					{"name": "Light Attack", "mult": 0.8, "bucket": "element"},
					{"name": "Divine Resistance", "mult": 0.6, "bucket": "resist", "vs": "Shadow"},
					{"name": "Defense", "mult": 0.5, "bucket": "defense"},
					{"name": "Max HP", "mult": 0.4, "bucket": "hp"},
				]},
			{"name": "Lumen Plate", "slot": "Chest", "pct": 24.40, "weight": 17,
				"attributes": [
					{"name": "Light Resistance", "mult": 0.7, "bucket": "resist", "vs": "Light"},
					{"name": "Defense", "mult": 0.6, "bucket": "defense"},
					{"name": "Max HP", "mult": 0.5, "bucket": "hp"},
					{"name": "Debuff Resistance", "mult": 0.3, "bucket": "debuff_resist"},
				]},
			{"name": "Radiant Helm", "slot": "Helmet", "pct": 17.22, "weight": 12,
				"attributes": [
					{"name": "Light Resistance", "mult": 0.8, "bucket": "resist", "vs": "Light"},
					{"name": "Defense", "mult": 0.6, "bucket": "defense"},
					{"name": "Max HP", "mult": 0.5, "bucket": "hp"},
				]},
			{"name": "Radiant Grips", "slot": "Gloves", "pct": 14.35, "weight": 10,
				"attributes": [
					{"name": "Light Resistance", "mult": 0.6, "bucket": "resist", "vs": "Light"},
					{"name": "Dexterity", "mult": 0.25, "bucket": "attack_speed"},
				]},
			{"name": "Light Legs", "slot": "Legs", "pct": 12.92, "weight": 9,
				"attributes": [
					{"name": "Swift Stride", "mult": 0.6, "bucket": "move"},
					{"name": "Luminous Resilience", "mult": 0.4, "bucket": "defense"},
				]},
			{"name": "Light Necklace", "slot": "Necklace", "pct": 7.18, "weight": 5,
				"attributes": [
					{"name": "Light Affinity", "mult": 1.0, "bucket": "element"},
				]},
			{"name": "Light Ring", "slot": "Ring", "pct": 4.30, "weight": 3,
				"attributes": [
					{"name": "Radiant Focus", "mult": 1.0, "bucket": "crit"},
				]},
		],
	},
}

static func gear_total(hero_key: String) -> float:
	var total := 0.0
	for item in HEROES[hero_key]["gear"]:
		total += item["pct"]
	return total

static func total_power(hero_key: String) -> float:
	return gear_total(hero_key) + COMMANDER_SLOTS * COMMANDER_PCT_EACH

static func commander_matched(cmdr: Dictionary, hero_key: String) -> bool:
	return cmdr["element"] == HEROES[hero_key]["element"]

# Gear card model (Jaber's mockups, 2026-07-19):
# - attribute value = slot weight × per-attribute multiplier (Helmet 12% × 80% = +9.6%)
# - attribute COUNT follows weight (+1 per ~4%): Glyph 6 incl. its skill,
#   Weapon 5 incl. its skill, Chest 4, Helmet 3, Gloves 2, Legs 2,
#   Necklace 1, Ring 1
# - Glyph and Weapon carry the usable skills; skill power is separate
static func attr_value(item: Dictionary, attr: Dictionary) -> float:
	return float(item["weight"]) * float(attr["mult"])

# Bucketed totals of a hero's gear: attack / element / defense / hp /
# attack_speed / move / crit / debuff_resist, plus "resist" = {element: pct}
static func gear_bucket_totals(hero_key: String) -> Dictionary:
	var totals := {"attack": 0.0, "element": 0.0, "defense": 0.0, "hp": 0.0,
		"attack_speed": 0.0, "move": 0.0, "crit": 0.0, "debuff_resist": 0.0,
		"resist": {}}
	for item in HEROES[hero_key]["gear"]:
		for attr in item["attributes"]:
			var v := attr_value(item, attr)
			if attr["bucket"] == "resist":
				var vs: String = attr["vs"]
				totals["resist"][vs] = totals["resist"].get(vs, 0.0) + v
			else:
				totals[attr["bucket"]] += v
	return totals
