# battle_temp_model.gd — TEMPORARY combat model for the siege sandbox.
# LOCKED constants are GDD rules used verbatim and must not be tuned here.
# TEMP constants are placeholders awaiting the real stat model — tune freely.
class_name BattleTempModel

# --- LOCKED (GDD §5.2 / §5.5 / §6 / §7.6) ------------------------------------
const BASE_ATTACK := 100.0          # Common full-set anchor (§5.5)
const BASE_DEFENSE := 100.0         # Common full-set anchor (§5.5)
const BASE_HP := 1000.0             # Common full-set anchor (§5.5)
const MATCHED_SET_ELEMENT := 150.0  # full 8-piece matching set element total (§5.5)
const COMMANDER_ATTR_SCALE := 0.10  # a Commander grants 10% of the hero equivalent (§15.2)
const DEBUFF_NAMES := ["Poison", "Slow", "Stun", "Daze", "Burn", "Bleed", "Weak"]  # §7.1

# --- TEMP coefficients (placeholders — tune freely) ---------------------------
const RING_SUPERIORITY_MULT := 1.25   # damage mult for the elementally superior side
const RANGE_COUNTER_MULT := 1.25      # full-strength mult where a range type counters
const ELEMENT_EDGE_FACTOR := 0.2      # dmg scaling per 100% element-power advantage
const BASE_DPS_FACTOR := 0.08         # fraction of effective Attack dealt per second
const EXHAUST_DRAIN_RATE := 2.0       # exhaust %/sec while a force is in combat
const EXHAUST_FLOOR := 0.5            # damage mult at 0% exhaust (fully exhausted)
const DEBUFF_DPS_FACTOR := 0.002      # extra dps per % of debuff attribute (Burn/Daze...)

const CATS := ["melee", "mid", "ranged"]

static func _pct(s: String) -> float:
	return float(s.replace("+", "").replace("%", ""))

# Build a side's computed combat profile from the data file.
# This is where the hero-context differences appear: element-power attributes
# only count when their element matches the hero's.
static func side_profile(hero_key: String) -> Dictionary:
	var hero: Dictionary = BattleTestData.HEROES[hero_key]
	var gear := BattleTestData.gear_bucket_totals(hero_key)

	# TEMP simplification: crit (chance/damage/penetration) folds into attack
	var atk: float = gear["attack"] + gear["crit"]
	var def: float = gear["defense"]
	var hp: float = gear["hp"]
	var spd: float = gear["attack_speed"]
	var elem: float = gear["element"]
	var march: float = gear["move"]
	var resist: Dictionary = gear["resist"]
	var debuff: float = 0.0  # debuff pressure now comes from skills (later pass)

	var cat_atk := {"melee": 0.0, "mid": 0.0, "ranged": 0.0}
	var cat_def := {"melee": 0.0, "mid": 0.0, "ranged": 0.0}

	# Hero attributes (curated, full strength)
	for a in hero["attributes"]:
		var v := _pct(a["value"])
		match a["name"]:
			"Mid-Range Attack Bonus": cat_atk["mid"] += v
			"Melee Attack Bonus": cat_atk["melee"] += v
			"Ranged Attack Bonus": cat_atk["ranged"] += v
			"Melee Defense Bonus": cat_def["melee"] += v
			"Attack Speed": spd += v
			_:
				if a["name"].ends_with("Element Power"):
					if a["name"].begins_with(hero["element"]):
						elem += v  # off-element power is wasted (never a penalty)

	# Commander attributes (identical copies both sides — LOCKED 10% scale).
	# Only attributes whose unlock level is reached apply.
	for cmdr in BattleTestData.COMMANDERS:
		for a in cmdr["attributes"]:
			if int(a.get("unlock", 1)) > int(cmdr["level"]):
				continue
			var v := _pct(a["value"]) * COMMANDER_ATTR_SCALE
			match a["name"]:
				"Attack": atk += v
				"Physical Defense": def += v
				"Max HP": hp += v
				"Critical Damage": atk += v  # TEMP: crit folds into attack

	var attack_by_cat := {}
	var defense_by_cat := {}
	for cat in CATS:
		attack_by_cat[cat] = BASE_ATTACK * (1.0 + (atk + cat_atk[cat]) / 100.0)
		defense_by_cat[cat] = BASE_DEFENSE * (1.0 + (def + cat_def[cat]) / 100.0)

	return {
		"key": hero_key,
		"name": hero["name"],
		"element": hero["element"],
		"troops": hero["troops"],
		"attack_by_cat": attack_by_cat,
		"defense_by_cat": defense_by_cat,
		"attack_speed": 1.0 + spd / 100.0,
		"hp_total": BASE_HP * (1.0 + hp / 100.0),
		"element_power": MATCHED_SET_ELEMENT + elem,
		"march_bonus": 1.0 + march / 100.0,
		"debuff_power": debuff,
		"resist": resist,
	}

# Army damage per second, attacker -> defender (composition-weighted).
# exhaust_frac: attacker's exhaust meter 0..1 (1 = fresh)
static func army_dps(attacker: Dictionary, defender: Dictionary, exhaust_frac := 1.0) -> float:
	var dps := 0.0
	for cat in CATS:
		var share: float = attacker["troops"][cat]
		if share <= 0.0:
			continue
		var raw: float = attacker["attack_by_cat"][cat] * attacker["attack_speed"] * BASE_DPS_FACTOR * share
		# Range counter: scaled by how much of the defender is the countered type
		var countered: String = BattleTestData.RANGE_BEATS[cat]
		raw *= 1.0 + (RANGE_COUNTER_MULT - 1.0) * defender["troops"][countered]
		dps += raw
	# Debuff pressure (Burn / Daze etc. as generic extra dps)
	dps += attacker["debuff_power"] * DEBUFF_DPS_FACTOR * BASE_ATTACK
	# Elemental ring: superior side only (inferiority is never a penalty)
	if BattleTestData.SUPERIOR_TO[attacker["element"]] == defender["element"]:
		dps *= RING_SUPERIORITY_MULT
	# Element power edge: only the higher side gains
	var edge: float = attacker["element_power"] - defender["element_power"]
	if edge > 0.0:
		dps *= 1.0 + edge / 100.0 * ELEMENT_EDGE_FACTOR
	# Defender mitigation (composition-weighted defense vs the anchor)
	var def_avg := 0.0
	for cat in CATS:
		def_avg += defender["defense_by_cat"][cat] * defender["troops"][cat]
	dps *= BASE_DEFENSE / maxf(def_avg, 1.0)
	# Elemental resistance vs the attacker's element (card resist rolls)
	var res: float = defender["resist"].get(attacker["element"], 0.0)
	dps *= 100.0 / (100.0 + res)
	# Exhaust: drained fighters hit softer, floored at EXHAUST_FLOOR
	dps *= EXHAUST_FLOOR + (1.0 - EXHAUST_FLOOR) * clampf(exhaust_frac, 0.0, 1.0)
	return dps

static func describe_matchup(att_key: String, def_key: String) -> Array:
	var a := side_profile(att_key)
	var d := side_profile(def_key)
	var lines := []
	for p in [a, d]:
		lines.append("[SERIOS] PROFILE %s (%s): atk m/mid/r %.0f/%.0f/%.0f · def m/mid/r %.0f/%.0f/%.0f · spd x%.2f · HP %.0f · elem %.1f · debuff %.0f%%" % [
			p["name"], p["element"],
			p["attack_by_cat"]["melee"], p["attack_by_cat"]["mid"], p["attack_by_cat"]["ranged"],
			p["defense_by_cat"]["melee"], p["defense_by_cat"]["mid"], p["defense_by_cat"]["ranged"],
			p["attack_speed"], p["hp_total"], p["element_power"], p["debuff_power"]])
	var dps_a := army_dps(a, d)
	var dps_d := army_dps(d, a)
	lines.append("[SERIOS] TEMP MODEL: %s -> %s %.2f dps (kills in ~%.0fs) | %s -> %s %.2f dps (kills in ~%.0fs)" % [
		a["name"], d["name"], dps_a, d["hp_total"] / maxf(dps_a, 0.01),
		d["name"], a["name"], dps_d, a["hp_total"] / maxf(dps_d, 0.01)])
	return lines
