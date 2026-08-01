# third_person.gd — third-person siege sandbox (run with F6).
# Live TEMPORARY combat: Matches (attacker, joystick-driven general) assaults
# Seer's Common-tier castle. Forces are clusters: one per Commander plus the
# General. All formulas live in BattleTempModel — not here.
extends Control

# --- Tunables (edit this block) ---------------------------------------------
const TICK_RATE := 10.0            # sim ticks per second
const TICK_DT := 1.0 / TICK_RATE
const JOYSTICK_RADIUS := 130.0
const KNOB_RADIUS := 55.0
const UNIT_SPEED := 140.0          # base px/sec (scaled by march bonus)
const ENGAGE_RANGE := 120.0        # units this close fight
const AGGRO_RANGE := 500.0         # commanders auto-engage inside this
const COMMANDER_LEASH := 280.0     # commanders stay this close to their general
const COMMANDER_HOLD := 150.0      # idle commanders drift back inside this
const SEER_HOLD_RANGE := 350.0     # Seer commits only to threats this close to the platform
const GENERAL_RADIUS := 34.0
const COMMANDER_RADIUS := 24.0
const TERRAIN_SLOW := 0.5          # speed multiplier inside the terrain patch
const FLICKER_HZ := 6.0

# Seer's Common-tier castle (Outer = open field, castle = 2 walls / 2 gates)
const CASTLE_WALL := Rect2(816, 100, 900, 520)
const PLATFORM_WALL := Rect2(1066, 160, 400, 240)
const CASTLE_GATE_W := 200.0
const PLATFORM_GATE_W := 120.0
const RIVER_RECT := Rect2(0, 780, 2532, 70)
const FIELD_BRIDGES := [Rect2(1216, 765, 160, 100), Rect2(500, 765, 160, 100)]
const TERRAIN_CENTER := Vector2(1800.0, 950.0)
const TERRAIN_RADIUS := 150.0
const FIELD_OBSTACLES := [Rect2(700, 660, 120, 90), Rect2(1700, 680, 130, 80)]
const WALL_COLOR := Color(0.5, 0.5, 0.55)
const PLATFORM_COLOR := Color(0.35, 0.35, 0.4)
const WATER_COLOR := Color(0.13, 0.25, 0.42)
const BRIDGE_COLOR := Color(0.42, 0.3, 0.16)
const TERRAIN_COLOR := Color(0.33, 0.3, 0.17, 0.55)
const OBSTACLE_COLOR := Color(0.28, 0.28, 0.32)

# Locked button colors (Jaber 2026-07-19)
const HERO_COLOR := Color(1.0, 0.8, 0.25)
const GLYPH_COLOR := Color(0.62, 0.42, 1.0)
const WEAPON_COLOR := Color(1.0, 0.55, 0.15)
const BUFF_TRAP_COLOR := Color(0.45, 0.9, 0.3)
const BASIC_COLOR := Color(1.0, 0.3, 0.25)

const MELEE_COLOR := Color(1.0, 0.35, 0.3)
const MID_COLOR := Color(1.0, 0.8, 0.3)
const RANGED_COLOR := Color(0.35, 0.7, 1.0)

const MAP_ALLY_COLORS := [Color(0.3, 0.75, 1.0), Color(0.4, 1.0, 0.55)]
const MAP_ENEMY_COLOR := Color(1.0, 0.25, 0.2)
const STAGE_RING_RADII := [130.0, 80.0]

const ALLY_UNIT_COLORS := [Color(0.3, 0.75, 1.0), Color(0.5, 0.85, 1.0), Color(0.65, 0.92, 1.0)]
const ENEMY_UNIT_COLORS := [Color(1.0, 0.25, 0.2), Color(1.0, 0.45, 0.35), Color(1.0, 0.6, 0.45)]

const JOY_CENTER := Vector2(200.0, 200.0)

# --- Battle unit (cluster: the General or one Commander) ----------------------
class BattleUnit:
	var unit_name: String
	var side: String            # "matches" / "seer"
	var element: String
	var is_general := false
	var pos: Vector2
	var prev_pos: Vector2
	var hp: float
	var max_hp: float
	var power_share: float      # fraction of the army's power this cluster is
	var radius: float
	var color: Color
	var in_combat := false
	var alive := true

	func _init(n: String, s: String, e: String, general: bool, p: Vector2, pool: float, share: float, r: float, col: Color) -> void:
		unit_name = n
		side = s
		element = e
		is_general = general
		pos = p
		prev_pos = p
		power_share = share
		max_hp = pool * share
		hp = max_hp
		radius = r
		color = col

const COUNTERED_BY := {"melee": "ranged", "mid": "melee", "ranged": "mid"}  # inverse of the triangle

var _joy_active := false
var _joy_vector := Vector2.ZERO
var _commander_thresholds: Array = []
var _units: Array = []
var _profiles := {}
var _cat_hp := {}             # side -> per-category remaining pool
var _cat_max := {}            # side -> per-category starting pool
var _exhaust := {"matches": 1.0, "seer": 1.0}
var _army_pct := {"matches": 1.0, "seer": 1.0}
var _breached := 0            # 0 none, 1 outer cleared, 2 inner cleared, 3 leader down
var _battle_over := false
var _block_rects: Array = []
var _acc := 0.0
var _time := 0.0

func _ready() -> void:
	$SkillCluster/HeroSkillBtn.modulate = HERO_COLOR
	$SkillCluster/GlyphSkillBtn.modulate = GLYPH_COLOR
	$SkillCluster/WeaponSkillBtn.modulate = WEAPON_COLOR
	$SkillCluster/BuffTrapBtn.modulate = BUFF_TRAP_COLOR
	$SkillCluster/BasicAttackBtn.modulate = BASIC_COLOR
	$SkillCluster/HeroSkillBtn.pressed.connect(_on_hero)
	$SkillCluster/GlyphSkillBtn.pressed.connect(_on_glyph)
	$SkillCluster/WeaponSkillBtn.pressed.connect(_on_weapon)
	$SkillCluster/BuffTrapBtn.pressed.connect(_on_buff_trap)
	$SkillCluster/BasicAttackBtn.pressed.connect(_on_basic_attack)
	$TroopTray/MeleeIcon.modulate = MELEE_COLOR
	$TroopTray/MidIcon.modulate = MID_COLOR
	$TroopTray/RangedIcon.modulate = RANGED_COLOR
	$TroopTray/MeleePercentLabel.modulate = MELEE_COLOR
	$TroopTray/MidPercentLabel.modulate = MID_COLOR
	$TroopTray/RangedPercentLabel.modulate = RANGED_COLOR
	$SwitchViewBtn.pressed.connect(_on_switch_view)
	$SettingsBtn.pressed.connect(_on_settings)
	$JoystickArea.gui_input.connect(_on_joy_input)
	$JoystickArea.draw.connect(_on_joy_draw)
	$WorldBackground.draw.connect(_on_world_draw)
	$HeroPlate/ArmyPowerBar.draw.connect(_on_army_bar_draw)
	$HeroPlate/ExhaustBar.draw.connect(_on_exhaust_bar_draw)
	$BattleFrontBar.draw.connect(_on_front_bar_draw)
	$MinimapArea.draw.connect(_on_minimap_draw)
	_build_blockers()
	_bind_hero_data()
	_spawn_forces()

func _bind_hero_data() -> void:
	var hero: Dictionary = BattleTestData.HEROES["matches"]
	var foe: Dictionary = BattleTestData.HEROES["seer"]
	$HeroPlate/HeroNameLabel.text = "%s · %s · %s" % [
		str(hero["name"]).to_upper(), str(hero["element"]).to_upper(), str(hero["tier"]).to_upper()]
	$SkillCluster/HeroSkillBtn.text = str(hero["skills"]["hero"]).to_upper()
	$SkillCluster/WeaponSkillBtn.text = str(hero["skills"]["weapon"]).to_upper()
	$SkillCluster/BuffTrapBtn.text = str(hero["skills"]["buff_trap"]).to_upper()
	$SkillCluster/GlyphSkillBtn.text = str(hero["skills"]["glyph"]).to_upper()
	_commander_thresholds.clear()
	for i in range(1, BattleTestData.COMMANDER_SLOTS + 1):
		_commander_thresholds.append(float(i) / float(BattleTestData.COMMANDER_SLOTS + 1))
	$TroopTray/MeleeCompLabel.text = "%d%%" % int(hero["troops"]["melee"] * 100)
	$TroopTray/MidCompLabel.text = "%d%%" % int(hero["troops"]["mid"] * 100)
	$TroopTray/RangedCompLabel.text = "%d%%" % int(hero["troops"]["ranged"] * 100)
	_profiles["matches"] = BattleTempModel.side_profile("matches")
	_profiles["seer"] = BattleTempModel.side_profile("seer")
	print("[SERIOS] SIEGE: %s (%s) attacks %s (%s) — both %s, %.1f%% / %d power" % [
		hero["name"], hero["element"], foe["name"], foe["element"], hero["tier"],
		BattleTestData.total_power("matches"), roundi(BattleTestData.total_power("matches") * 100.0)])
	for line in BattleTempModel.describe_matchup("matches", "seer"):
		print(line)

func _spawn_forces() -> void:
	_units.clear()
	var gear_share := BattleTestData.COMMON_GEAR_TOTAL_PCT / BattleTestData.TOTAL_POWER_PCT
	var cmdr_share := BattleTestData.COMMANDER_PCT_EACH / BattleTestData.TOTAL_POWER_PCT
	var pool_m: float = _profiles["matches"]["hp_total"]
	var pool_s: float = _profiles["seer"]["hp_total"]
	var c0: Dictionary = BattleTestData.COMMANDERS[0]
	var c1: Dictionary = BattleTestData.COMMANDERS[1]
	# Matches: general + commanders start below the river
	_units.append(BattleUnit.new("Matches", "matches", "Fire", true, Vector2(1266, 1000), pool_m, gear_share, GENERAL_RADIUS, ALLY_UNIT_COLORS[0]))
	_units.append(BattleUnit.new(c0["name"], "matches", c0["element"], false, Vector2(1160, 1050), pool_m, cmdr_share, COMMANDER_RADIUS, ALLY_UNIT_COLORS[1]))
	_units.append(BattleUnit.new(c1["name"], "matches", c1["element"], false, Vector2(1372, 1050), pool_m, cmdr_share, COMMANDER_RADIUS, ALLY_UNIT_COLORS[2]))
	# Seer: general on the platform, commanders in the courtyard
	_units.append(BattleUnit.new("Seer", "seer", "Light", true, PLATFORM_WALL.get_center(), pool_s, gear_share, GENERAL_RADIUS, ENEMY_UNIT_COLORS[0]))
	_units.append(BattleUnit.new(c0["name"], "seer", c0["element"], false, Vector2(1150, 500), pool_s, cmdr_share, COMMANDER_RADIUS, ENEMY_UNIT_COLORS[1]))
	_units.append(BattleUnit.new(c1["name"], "seer", c1["element"], false, Vector2(1382, 500), pool_s, cmdr_share, COMMANDER_RADIUS, ENEMY_UNIT_COLORS[2]))
	# Per-category pools (a parallel view of the same army HP)
	for side in ["matches", "seer"]:
		var pool: float = _profiles[side]["hp_total"]
		var troops: Dictionary = _profiles[side]["troops"]
		_cat_hp[side] = {}
		_cat_max[side] = {}
		for cat in ["melee", "mid", "ranged"]:
			_cat_hp[side][cat] = pool * troops[cat]
			_cat_max[side][cat] = pool * troops[cat]

# --- Movement blocking (walls with gates, river with bridges, obstacles) ------
func _build_blockers() -> void:
	_block_rects.clear()
	for wall in [[CASTLE_WALL, CASTLE_GATE_W], [PLATFORM_WALL, PLATFORM_GATE_W]]:
		var r: Rect2 = wall[0]
		var gw: float = wall[1]
		var t := 26.0
		_block_rects.append(Rect2(r.position.x - 9, r.position.y - 9, r.size.x + 18, t))
		_block_rects.append(Rect2(r.position.x - 9, r.position.y - 9, t, r.size.y + 18))
		_block_rects.append(Rect2(r.end.x - t + 9, r.position.y - 9, t, r.size.y + 18))
		var cx := r.position.x + r.size.x * 0.5
		_block_rects.append(Rect2(r.position.x - 9, r.end.y - t + 9, (cx - gw * 0.5) - (r.position.x - 9), t))
		_block_rects.append(Rect2(cx + gw * 0.5, r.end.y - t + 9, (r.end.x + 9) - (cx + gw * 0.5), t))
	for o in FIELD_OBSTACLES:
		_block_rects.append(o.grow(10.0))

func _on_bridge(p: Vector2) -> bool:
	for b in FIELD_BRIDGES:
		if b.has_point(p):
			return true
	return false

func _world_blocked(p: Vector2) -> bool:
	if RIVER_RECT.grow(10.0).has_point(p) and not _on_bridge(p):
		return true
	for r in _block_rects:
		if r.has_point(p):
			return true
	return false

func _speed_mult(p: Vector2) -> float:
	return TERRAIN_SLOW if p.distance_to(TERRAIN_CENTER) <= TERRAIN_RADIUS else 1.0

func _step_unit(u: BattleUnit, toward: Vector2, step: float) -> void:
	var next := u.pos.move_toward(toward, step)
	if not _world_blocked(next):
		u.pos = next
		return
	var sx := Vector2(next.x, u.pos.y)
	if not _world_blocked(sx):
		u.pos = sx
		return
	var sy := Vector2(u.pos.x, next.y)
	if not _world_blocked(sy):
		u.pos = sy

# --- Simulation ----------------------------------------------------------------
func _process(delta: float) -> void:
	_time += delta
	_acc += delta
	while _acc >= TICK_DT:
		_acc -= TICK_DT
		if not _battle_over:
			_sim_tick()
	_update_hud()
	$JoystickArea.queue_redraw()
	$WorldBackground.queue_redraw()
	$HeroPlate/ArmyPowerBar.queue_redraw()
	$HeroPlate/ExhaustBar.queue_redraw()
	$BattleFrontBar.queue_redraw()
	$MinimapArea.queue_redraw()

func _general_of(side: String) -> BattleUnit:
	for u in _units:
		if u.side == side and u.is_general:
			return u
	return null

func _pick_target(u: BattleUnit) -> BattleUnit:
	# Closest-or-best-fit: distance shortened for counter-favorable targets
	var best: BattleUnit = null
	var best_score := INF
	for e in _units:
		if e.side == u.side or not e.alive:
			continue
		var score := u.pos.distance_to(e.pos)
		if BattleTestData.SUPERIOR_TO.get(u.element, "") == e.element:
			score *= 0.6
		if score < best_score:
			best_score = score
			best = e
	return best

func _sim_tick() -> void:
	# Movement
	for u in _units:
		u.prev_pos = u.pos
		if not u.alive:
			continue
		var speed: float = UNIT_SPEED * _profiles[u.side]["march_bonus"] * _speed_mult(u.pos)
		var step := speed * TICK_DT
		if u.side == "matches" and u.is_general:
			if _joy_vector != Vector2.ZERO:
				_step_unit(u, u.pos + _joy_vector * 100.0, minf(step, _joy_vector.length() * step))
		elif u.is_general:
			# Seer: hold the platform, commit only to threats near it
			var home := PLATFORM_WALL.get_center()
			var t := _pick_target(u)
			if t != null and t.pos.distance_to(home) <= SEER_HOLD_RANGE:
				if u.pos.distance_to(t.pos) > ENGAGE_RANGE * 0.8:
					_step_unit(u, t.pos, step)
			elif u.pos.distance_to(home) > 10.0:
				_step_unit(u, home, step)
		else:
			# Commander: leash to the general first, then closest/best-fit enemy
			var g := _general_of(u.side)
			if g != null and g.alive and u.pos.distance_to(g.pos) > COMMANDER_LEASH:
				_step_unit(u, g.pos, step)
			else:
				var t2 := _pick_target(u)
				if t2 != null and u.pos.distance_to(t2.pos) <= AGGRO_RANGE:
					if u.pos.distance_to(t2.pos) > ENGAGE_RANGE * 0.8:
						_step_unit(u, t2.pos, step)
				elif g != null and g.alive and u.pos.distance_to(g.pos) > COMMANDER_HOLD:
					_step_unit(u, g.pos, step)

	# Combat: each cluster strikes the nearest enemy in engage range.
	# Live composition (surviving category shares) feeds the damage math.
	var live := {}
	for side in ["matches", "seer"]:
		var p: Dictionary = _profiles[side].duplicate()
		p["troops"] = _eff_troops(side)
		live[side] = p
	for u in _units:
		u.in_combat = false
	for u in _units:
		if not u.alive:
			continue
		var nearest: BattleUnit = null
		var nd := INF
		for e in _units:
			if e.side == u.side or not e.alive:
				continue
			var d: float = u.pos.distance_to(e.pos)
			if d < nd:
				nd = d
				nearest = e
		if nearest != null and nd <= ENGAGE_RANGE:
			u.in_combat = true
			nearest.in_combat = true
			var foe_side := "seer" if u.side == "matches" else "matches"
			var dmg: float = BattleTempModel.army_dps(live[u.side], live[foe_side], _exhaust[u.side]) * u.power_share * TICK_DT
			nearest.hp = maxf(nearest.hp - dmg, 0.0)
			_apply_cat_damage(foe_side, dmg, live[u.side]["troops"])

	# Exhaust drains for any side with troops in combat
	for side in ["matches", "seer"]:
		for u in _units:
			if u.alive and u.side == side and u.in_combat:
				_exhaust[side] = maxf(_exhaust[side] - BattleTempModel.EXHAUST_DRAIN_RATE / 100.0 * TICK_DT, 0.0)
				break

	# Deaths
	for u in _units:
		if u.alive and u.hp <= 0.0:
			u.alive = false
			print("[SERIOS] FALLEN: %s (%s)" % [u.unit_name, u.side])
			if u.is_general:
				_battle_over = true
				if u.side == "seer":
					_breached = 3
					print("[SERIOS] SIEGE: the leader has fallen — VICTORY for Matches")
				else:
					print("[SERIOS] SIEGE: Matches has fallen — DEFEAT")

	# Army totals
	for side in ["matches", "seer"]:
		var hp_sum := 0.0
		var max_sum := 0.0
		for u in _units:
			if u.side == side:
				max_sum += u.max_hp
				hp_sum += u.hp
		_army_pct[side] = hp_sum / max_sum if max_sum > 0.0 else 0.0

	# Stage breaches (attacker progress through the castle)
	if _breached < 3:
		for u in _units:
			if u.side != "matches" or not u.alive:
				continue
			if PLATFORM_WALL.has_point(u.pos):
				_breached = maxi(_breached, 2)
			elif CASTLE_WALL.has_point(u.pos):
				_breached = maxi(_breached, 1)

func _eff_troops(side: String) -> Dictionary:
	# Surviving composition: category pools normalized to fractions
	var pool: Dictionary = _cat_hp[side]
	var total: float = pool["melee"] + pool["mid"] + pool["ranged"]
	if total <= 0.0:
		return _profiles[side]["troops"]
	return {"melee": pool["melee"] / total, "mid": pool["mid"] / total, "ranged": pool["ranged"] / total}

func _apply_cat_damage(side: String, dmg: float, att_troops: Dictionary) -> void:
	# Countered categories bleed faster: damage distributes by category share,
	# weighted up where the attacker fields the counter type
	var pool: Dictionary = _cat_hp[side]
	var troops_now := _eff_troops(side)
	var weights := {}
	var wsum := 0.0
	for cat in ["melee", "mid", "ranged"]:
		if pool[cat] <= 0.0:
			continue
		var counterer: String = COUNTERED_BY[cat]
		var w: float = troops_now[cat] * (1.0 + (BattleTempModel.RANGE_COUNTER_MULT - 1.0) * att_troops.get(counterer, 0.0))
		weights[cat] = w
		wsum += w
	if wsum <= 0.0:
		return
	for cat in weights:
		pool[cat] = maxf(pool[cat] - dmg * weights[cat] / wsum, 0.0)

func _update_hud() -> void:
	var mp: Dictionary = _cat_hp["matches"]
	var mm: Dictionary = _cat_max["matches"]
	$TroopTray/MeleePercentLabel.text = "%d%%" % int(mp["melee"] / mm["melee"] * 100.0)
	$TroopTray/MidPercentLabel.text = "%d%%" % int(mp["mid"] / mm["mid"] * 100.0)
	$TroopTray/RangedPercentLabel.text = "%d%%" % int(mp["ranged"] / mm["ranged"] * 100.0)
	$DebugLabel.text = "Matches %d%% · Seer %d%% · Stage %d/3 · Exhaust %d%%" % [
		int(_army_pct["matches"] * 100), int(_army_pct["seer"] * 100), _breached, int(_exhaust["matches"] * 100)]

# --- Joystick ------------------------------------------------------------------
func _on_joy_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_joy_active = true
			_update_joy(event.position)
		else:
			_joy_active = false
			_joy_vector = Vector2.ZERO
	elif event is InputEventMouseMotion and _joy_active:
		_update_joy(event.position)

func _update_joy(p: Vector2) -> void:
	var off := p - JOY_CENTER
	if off.length() > JOYSTICK_RADIUS:
		off = off.normalized() * JOYSTICK_RADIUS
	_joy_vector = off / JOYSTICK_RADIUS

func _on_joy_draw() -> void:
	var joy: Control = $JoystickArea
	joy.draw_circle(JOY_CENTER, JOYSTICK_RADIUS, Color(1, 1, 1, 0.08))
	joy.draw_arc(JOY_CENTER, JOYSTICK_RADIUS, 0.0, TAU, 48, Color(1, 1, 1, 0.35), 3.0)
	joy.draw_circle(JOY_CENTER + _joy_vector * JOYSTICK_RADIUS, KNOB_RADIUS, Color(1, 1, 1, 0.45))

# --- World drawing --------------------------------------------------------------
func _draw_wall(world: Control, r: Rect2, gate_w: float) -> void:
	var t := 8.0
	world.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, t), WALL_COLOR)
	world.draw_rect(Rect2(r.position.x, r.position.y, t, r.size.y), WALL_COLOR)
	world.draw_rect(Rect2(r.end.x - t, r.position.y, t, r.size.y), WALL_COLOR)
	var cx := r.position.x + r.size.x * 0.5
	world.draw_rect(Rect2(r.position.x, r.end.y - t, cx - gate_w * 0.5 - r.position.x, t), WALL_COLOR)
	world.draw_rect(Rect2(cx + gate_w * 0.5, r.end.y - t, r.end.x - (cx + gate_w * 0.5), t), WALL_COLOR)

func _on_world_draw() -> void:
	var world: Control = $WorldBackground
	var font := get_theme_default_font()
	world.draw_circle(TERRAIN_CENTER, TERRAIN_RADIUS, TERRAIN_COLOR)
	world.draw_rect(RIVER_RECT, WATER_COLOR)
	for b in FIELD_BRIDGES:
		world.draw_rect(b, BRIDGE_COLOR)
	for o in FIELD_OBSTACLES:
		world.draw_rect(o, OBSTACLE_COLOR)
	world.draw_rect(PLATFORM_WALL, PLATFORM_COLOR)
	_draw_wall(world, CASTLE_WALL, CASTLE_GATE_W)
	_draw_wall(world, PLATFORM_WALL, PLATFORM_GATE_W)
	var t := clampf(_acc / TICK_DT, 0.0, 1.0)
	for u in _units:
		if not u.alive:
			continue
		var draw_pos: Vector2 = u.prev_pos.lerp(u.pos, t)
		var col: Color = u.color
		if u.in_combat:
			col.a = 0.55 + 0.45 * sin(_time * FLICKER_HZ * TAU)
		# Cluster body: radius thins with remaining strength (density language)
		var r: float = u.radius * (0.55 + 0.45 * sqrt(u.hp / u.max_hp))
		world.draw_circle(draw_pos, r, col)
		# Health bar above the cluster (§8.4)
		var bw := 64.0
		world.draw_rect(Rect2(draw_pos.x - bw * 0.5, draw_pos.y - u.radius - 22, bw, 8), Color(0.1, 0.1, 0.1, 0.8))
		world.draw_rect(Rect2(draw_pos.x - bw * 0.5, draw_pos.y - u.radius - 22, bw * (u.hp / u.max_hp), 8), Color(0.35, 0.9, 0.35))
		world.draw_string(font, draw_pos + Vector2(-40, u.radius + 24), u.unit_name,
			HORIZONTAL_ALIGNMENT_CENTER, 80, 15, Color(1, 1, 1, 0.85))

# --- HUD drawing ----------------------------------------------------------------
func _on_army_bar_draw() -> void:
	var bar: Control = $HeroPlate/ArmyPowerBar
	var size := bar.size
	bar.draw_rect(Rect2(Vector2.ZERO, size), Color(0.1, 0.12, 0.1, 0.9))
	bar.draw_rect(Rect2(0, 0, size.x * _army_pct["matches"], size.y), Color(0.3, 0.85, 0.3))
	for th in _commander_thresholds:
		var x: float = size.x * th
		bar.draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.05, 0.05, 0.05), 3.0)
	bar.draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.4), false, 2.0)

func _on_exhaust_bar_draw() -> void:
	var bar: Control = $HeroPlate/ExhaustBar
	var size := bar.size
	bar.draw_rect(Rect2(Vector2.ZERO, size), Color(0.12, 0.1, 0.05, 0.9))
	bar.draw_rect(Rect2(0, 0, size.x * _exhaust["matches"], size.y), Color(1.0, 0.8, 0.25))
	bar.draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.4), false, 2.0)

func _on_front_bar_draw() -> void:
	# 1v1 instrument: both hero icons + live power bars. The attacker's bar is
	# continuous; the defender's is the same bar separated by the stage points,
	# cleared thirds graying out as they are breached.
	var bar: Control = $BattleFrontBar
	var font := get_theme_default_font()
	var mid_y := 62.0
	var slot_w := 350.0
	# Attacker (Matches)
	var acol: Color = MAP_ALLY_COLORS[0]
	bar.draw_rect(Rect2(90 + slot_w * 0.5 - 18, 4, 36, 36), acol)
	bar.draw_string(font, Vector2(94, 34), "MATCHES", HORIZONTAL_ALIGNMENT_LEFT, 160, 14, Color(1, 1, 1, 0.85))
	bar.draw_rect(Rect2(90, mid_y - 10, slot_w, 20), Color(0.15, 0.15, 0.18))
	bar.draw_rect(Rect2(90, mid_y - 10, slot_w * _army_pct["matches"], 20), acol)
	bar.draw_rect(Rect2(90, mid_y - 10, slot_w, 20), Color(1, 1, 1, 0.35), false, 2.0)
	# Center emblem
	bar.draw_circle(Vector2(450.0, mid_y), 26.0, Color(0.1, 0.1, 0.12))
	bar.draw_arc(Vector2(450.0, mid_y), 26.0, 0.0, TAU, 32, Color(1, 1, 1, 0.6), 3.0)
	# Defender (Seer): power bar with the stage points on it
	bar.draw_rect(Rect2(460 + slot_w * 0.5 - 18, 4, 36, 36), MAP_ENEMY_COLOR)
	bar.draw_string(font, Vector2(464, 34), "SEER", HORIZONTAL_ALIGNMENT_LEFT, 160, 14, Color(1, 1, 1, 0.85))
	bar.draw_rect(Rect2(460, mid_y - 10, slot_w, 20), Color(0.15, 0.15, 0.18))
	bar.draw_rect(Rect2(460, mid_y - 10, slot_w * _army_pct["seer"], 20), MAP_ENEMY_COLOR)
	for s in range(_breached):
		bar.draw_rect(Rect2(460 + slot_w * s / 3.0, mid_y - 10, slot_w / 3.0, 20), Color(0.3, 0.3, 0.32, 0.75))
	bar.draw_rect(Rect2(460, mid_y - 10, slot_w, 20), Color(1, 1, 1, 0.35), false, 2.0)
	for i in [1, 2]:
		var px: float = 460.0 + slot_w * i / 3.0
		var taken: bool = _breached >= i
		_draw_diamond(bar, Vector2(px, mid_y), 11.0, Color(0.55, 0.55, 0.55) if taken else Color(1, 1, 1, 0.9))
	bar.draw_rect(Rect2(830, 32, 60, 60), MAP_ENEMY_COLOR)

func _on_minimap_draw() -> void:
	var map: Control = $MinimapArea
	var center := Vector2(190.0, 190.0)
	map.draw_circle(center, 180.0, Color(0.09, 0.11, 0.09, 0.95))
	map.draw_arc(center, 180.0, 0.0, TAU, 64, Color(1, 1, 1, 0.5), 3.0)
	for i in STAGE_RING_RADII.size():
		var r: float = STAGE_RING_RADII[i]
		var cleared: bool = _breached > i
		map.draw_arc(center, r, 0.0, TAU, 48, Color(0.4, 0.4, 0.4, 0.5) if cleared else Color(1, 1, 1, 0.3), 2.0)
		_draw_diamond(map, center + Vector2(0, -r), 8.0, Color(0.5, 0.5, 0.5, 0.8) if cleared else Color(1, 1, 1, 0.8))
	map.draw_circle(center, 16.0, Color(0.4, 0.4, 0.4) if _breached >= 3 else MAP_ENEMY_COLOR)
	# Live unit blips (world -> minimap projection)
	for u in _units:
		if not u.alive:
			continue
		var rel: Vector2 = (u.pos - Vector2(1266.0, 585.0)) * 0.16
		if rel.length() > 165.0:
			rel = rel.normalized() * 165.0
		map.draw_circle(center + rel, 7.0, MAP_ENEMY_COLOR if u.side == "seer" else MAP_ALLY_COLORS[0])

func _draw_diamond(ci: CanvasItem, center: Vector2, r: float, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([
		center + Vector2(0, -r),
		center + Vector2(r, 0),
		center + Vector2(0, r),
		center + Vector2(-r, 0),
	]), col)

# --- Buttons --------------------------------------------------------------------
func _on_basic_attack() -> void:
	print("[SERIOS] HUD: BasicAttackBtn — basic attack (not built)")

func _on_hero() -> void:
	print("[SERIOS] HUD: HeroSkillBtn — hero skill (not built)")

func _on_glyph() -> void:
	print("[SERIOS] HUD: GlyphSkillBtn — glyph / ultimate (not built)")

func _on_weapon() -> void:
	print("[SERIOS] HUD: WeaponSkillBtn — weapon skill (not built)")

func _on_buff_trap() -> void:
	print("[SERIOS] HUD: BuffTrapBtn — buff/debuff/trap (not built)")

func _on_switch_view() -> void:
	print("[SERIOS] HUD: SwitchViewBtn — back to top-view map (not built)")

func _on_settings() -> void:
	print("[SERIOS] HUD: SettingsBtn — settings (not built)")
