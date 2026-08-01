# cluster_sim.gd — standalone top-view cluster simulation sandbox (run with F6)
# Not wired into NavigationManager — prototype only.
extends Control

# --- Tunables (edit this block) ---------------------------------------------
const TICK_RATE := 10.0            # sim ticks per second
const TICK_DT := 1.0 / TICK_RATE
const CLUSTER_RADIUS := 90.0       # footprint at rest — density changes, not size
const DOTS_MAX := 40               # dots at 100% power
const DOT_RADIUS := 9.0
const DOT_SPEED := 150.0           # px/sec each dot moves toward its formation slot
const MAX_POWER := 100.0
const ENEMY_START_POWER := 80.0    # enemy starts at 80%
const ALLY_START_POWER := 50.0     # each ally starts at 50%
const MARCH_SPEED := 90.0          # ally speed, px/sec along its path
const ENEMY_SPEED := 50.0          # enemy px/sec while defending/engaging (0 = frozen)
const ENEMY_AGGRO_RANGE := 450.0   # enemy defends: engages only allies inside this range
const ALLY_AGGRO_RANGE := 450.0    # idle allies auto-engage an enemy inside this range
const DRAIN_RATE := 8.0            # placeholder: power lost per second while engaged
const ENGAGE_DIST := 26.0          # dots this close to enemy dots are in melee contact
const FLICKER_HZ := 6.0            # combat flicker speed
const PING_TTL := 2.0              # seconds a ping marker lives
const SELECT_PADDING := 20.0       # extra px around a cluster for select clicks
const ALLY_COLORS := [Color(0.3, 0.75, 1.0), Color(0.4, 1.0, 0.55)]
const ENEMY_COLOR := Color(1.0, 0.25, 0.2)  # red — reserved for THE enemy cluster

# Pathfinding
const MAP_SIZE := Vector2(2092.0, 1170.0)  # MapArea size
const GRID_CELL := 40.0            # A* grid cell size, px
const REPATH_DIST := 60.0          # enemy re-paths when its target moved this far
const WAYPOINT_EPS := 6.0          # waypoint considered reached inside this distance

# Obstacles (castle approach, local to MapArea):
# castle courtyard top-right (keep + west wall + south wall with a gate),
# river across the lower map with a west bridge and an east bridge under the gate.
const OBSTACLE_MARGIN := 20.0      # keeps cluster centers this far out of blockers
const RIVER_RECTS := [
	Rect2(0, 620, 420, 80),
	Rect2(580, 620, 1000, 80),
	Rect2(1740, 620, 352, 80),
]
const BRIDGE_RECTS := [
	Rect2(420, 605, 160, 110),
	Rect2(1580, 605, 160, 110),
]
const WALL_RECTS := [
	Rect2(1700, 0, 260, 120),      # castle keep (top-right corner)
	Rect2(1360, 0, 36, 300),       # courtyard wall, west
	Rect2(1360, 300, 300, 36),     # courtyard wall, south-west of the gate
	Rect2(1800, 300, 292, 36),     # courtyard wall, south-east of the gate
]
const WATER_COLOR := Color(0.13, 0.25, 0.42, 1.0)
const BRIDGE_COLOR := Color(0.42, 0.3, 0.16, 1.0)
const WALL_COLOR := Color(0.5, 0.5, 0.55, 1.0)

enum Mode { NONE, MARCH, PING }

# --- Sim state (authoritative, updated only in _sim_tick) --------------------
class Cluster:
	var pos: Vector2
	var prev_pos: Vector2
	var power: float
	var max_power: float
	var in_combat := false
	var color: Color
	var target: Vector2
	var path: Array = []          # waypoints toward target (world positions)
	var is_enemy := false
	var player_order := false     # ally is executing an explicit march order
	var home: Vector2             # guard post — defenders return here
	var dot_offsets: Array = []   # packed, pre-shuffled — first N are the visible dots
	var dot_pos: Array = []       # per-dot simulated world positions
	var dot_prev: Array = []      # previous tick, for render interpolation
	var dot_paths: Array = []     # per-dot escape route when stranded behind an obstacle
	var dot_alive: Array = []     # per-dot life — casualties fall at the frontline
	var last_foe_pos: Vector2     # where the opposing force last made contact

	func _init(p: Vector2, col: Color, enemy: bool, start_power: float, power_cap: float, offsets: Array) -> void:
		pos = p
		prev_pos = p
		target = p
		home = p
		last_foe_pos = p
		power = start_power
		max_power = power_cap
		color = col
		is_enemy = enemy
		dot_offsets = offsets
		for off in offsets:
			dot_pos.append(p + off)
			dot_prev.append(p + off)
			dot_paths.append([])
			dot_alive.append(true)

	func alive() -> bool:
		return power > 0.0

	func alive_count() -> int:
		var n := 0
		for a in dot_alive:
			if a:
				n += 1
		return n

	func target_dots() -> int:
		return int(ceil(clampf(power / max_power, 0.0, 1.0) * dot_offsets.size()))

var _clusters: Array = []
var _pings: Array = []           # [{ "pos": Vector2, "ttl": float }]
var _selected = null             # Cluster or null
var _mode: int = Mode.NONE
var _acc := 0.0                  # tick accumulator
var _time := 0.0                 # wall time for flicker
var _result_logged := false
var _astar: AStarGrid2D

func _ready() -> void:
	$LeftControls/CallHelpBtn.pressed.connect(_on_call_help)
	$LeftControls/MarchBtn.pressed.connect(_on_march)
	$LeftControls/PingBtn.pressed.connect(_on_ping)
	$RightControls/SwitchViewBtn.pressed.connect(_on_switch_view)
	$RightControls/RestartBtn.pressed.connect(_on_restart)
	$MapArea.gui_input.connect(_on_map_input)
	$MapArea.draw.connect(_on_map_draw)
	_setup_astar()
	_setup_sim()

# --- Pathfinding ---------------------------------------------------------------
func _setup_astar() -> void:
	_astar = AStarGrid2D.new()
	_astar.region = Rect2i(0, 0, int(ceil(MAP_SIZE.x / GRID_CELL)), int(ceil(MAP_SIZE.y / GRID_CELL)))
	_astar.cell_size = Vector2(GRID_CELL, GRID_CELL)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.update()
	for x in _astar.region.size.x:
		for y in _astar.region.size.y:
			var center := Vector2((x + 0.5) * GRID_CELL, (y + 0.5) * GRID_CELL)
			if _blocked(center):
				_astar.set_point_solid(Vector2i(x, y), true)

func _cell_of(p: Vector2) -> Vector2i:
	return Vector2i(
		clampi(int(p.x / GRID_CELL), 0, _astar.region.size.x - 1),
		clampi(int(p.y / GRID_CELL), 0, _astar.region.size.y - 1)
	)

func _nearest_free_cell(cell: Vector2i) -> Variant:
	if not _astar.is_point_solid(cell):
		return cell
	for radius in range(1, 6):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				if absi(dx) != radius and absi(dy) != radius:
					continue
				var c := cell + Vector2i(dx, dy)
				if _astar.region.has_point(c) and not _astar.is_point_solid(c):
					return c
	return null

func _compute_path(from: Vector2, to: Vector2) -> Array:
	var a = _nearest_free_cell(_cell_of(from))
	var b = _nearest_free_cell(_cell_of(to))
	if a == null or b == null:
		return []
	var path: Array = []
	for p in _astar.get_point_path(a, b):
		path.append(p)
	if path.size() > 0:
		path.remove_at(0)  # skip the cell we're already standing in
	if not _blocked(to):
		path.append(to)    # finish exactly on the requested point when it's free
	return path

# --- Setup ----------------------------------------------------------------------
func _make_dot_offsets() -> Array:
	# Sunflower packing inside the footprint, then shuffled so dots vanish
	# randomly across the blob (density thins, footprint stays)
	var offsets: Array = []
	for i in DOTS_MAX:
		var r := CLUSTER_RADIUS * 0.92 * sqrt((i + 0.5) / DOTS_MAX)
		var theta := i * 2.39996
		offsets.append(Vector2(cos(theta), sin(theta)) * r)
	offsets.shuffle()
	return offsets

func _setup_sim() -> void:
	_clusters.clear()
	_pings.clear()
	_selected = null
	_mode = Mode.NONE
	_result_logged = false
	# 2 allies at 50% bottom-left, THE one enemy at 80% inside the courtyard
	_clusters.append(Cluster.new(Vector2(300, 900), ALLY_COLORS[0], false, ALLY_START_POWER, MAX_POWER, _make_dot_offsets()))
	_clusters.append(Cluster.new(Vector2(550, 1000), ALLY_COLORS[1], false, ALLY_START_POWER, MAX_POWER, _make_dot_offsets()))
	_clusters.append(Cluster.new(Vector2(1810, 200), ENEMY_COLOR, true, ENEMY_START_POWER, MAX_POWER, _make_dot_offsets()))

func _process(delta: float) -> void:
	_time += delta
	_acc += delta
	while _acc >= TICK_DT:
		_acc -= TICK_DT
		_sim_tick()
	$MapArea.queue_redraw()

# --- Simulation --------------------------------------------------------------
func _sim_tick() -> void:
	for c in _clusters:
		c.prev_pos = c.pos
		if not c.alive():
			continue
		var speed := ENEMY_SPEED if c.is_enemy else MARCH_SPEED
		if c.is_enemy:
			# Defender: engage only allies inside aggro range, otherwise return to post
			var nearest = _nearest_living_ally(c.pos)
			var want: Vector2 = c.home
			if nearest != null and c.pos.distance_to(nearest.pos) <= ENEMY_AGGRO_RANGE:
				want = _engage_point(c, nearest)
			if c.target.distance_to(want) > REPATH_DIST or (c.path.is_empty() and c.pos.distance_to(want) > WAYPOINT_EPS):
				c.target = want
				c.path = _compute_path(c.pos, want)
		else:
			# Ally: an explicit march order runs to completion; otherwise
			# auto-engage an enemy inside aggro range, hold when it leaves
			if c.player_order and c.path.is_empty():
				c.player_order = false
			if not c.player_order:
				var foe = _nearest_living_enemy(c.pos)
				if foe != null and c.pos.distance_to(foe.pos) <= ALLY_AGGRO_RANGE:
					var want_ally := _engage_point(c, foe)
					if c.target.distance_to(want_ally) > REPATH_DIST or (c.path.is_empty() and c.pos.distance_to(want_ally) > WAYPOINT_EPS):
						c.target = want_ally
						c.path = _compute_path(c.pos, want_ally)
				elif not c.path.is_empty():
					c.path = []
					c.target = c.pos
		_move_cluster(c, speed * TICK_DT)
		_update_dots(c)

	# Combat: engagement happens between actual dots, not cluster centers —
	# clusters whose troops are elsewhere neither deal nor take damage
	for c in _clusters:
		c.in_combat = false
	for ally in _clusters:
		if ally.is_enemy or not ally.alive():
			continue
		for enemy in _clusters:
			if not enemy.is_enemy or not enemy.alive():
				continue
			var pair := _nearest_dot_pair(ally, enemy)
			if pair[0] <= ENGAGE_DIST:
				ally.in_combat = true
				enemy.in_combat = true
				ally.last_foe_pos = pair[2]
				enemy.last_foe_pos = pair[1]
				ally.power = maxf(ally.power - DRAIN_RATE * TICK_DT, 0.0)
				enemy.power = maxf(enemy.power - DRAIN_RATE * TICK_DT, 0.0)

	# Casualties fall nearest the point of contact — troops away from the
	# fight are never the ones removed
	for c in _clusters:
		_sync_casualties(c)

	# Ping decay
	for p in _pings:
		p["ttl"] -= TICK_DT
	_pings = _pings.filter(func(p): return p["ttl"] > 0.0)

	# Drop selection on death
	if _selected != null and not _selected.alive():
		_selected = null

	# Result (log-only this pass)
	if not _result_logged:
		var allies_alive := false
		var enemy_alive := false
		for c in _clusters:
			if c.alive():
				if c.is_enemy:
					enemy_alive = true
				else:
					allies_alive = true
		if not enemy_alive:
			print("[SERIOS] SIM: enemy cluster destroyed — victory")
			_result_logged = true
		elif not allies_alive:
			print("[SERIOS] SIM: all ally clusters destroyed — defeat")
			_result_logged = true

func _engage_point(c: Cluster, foe: Cluster) -> Vector2:
	# Where must MY center stand so that my nearest surviving dot lands on the
	# foe's nearest surviving dot? Chasing centers stalls when frontline
	# casualties leave both sides' survivors on opposite outer edges.
	var pair := _nearest_dot_pair(c, foe)
	var own_offset: Vector2 = pair[1] - c.pos
	return pair[2] - own_offset

func _nearest_dot_pair(a: Cluster, b: Cluster) -> Array:
	# Returns [distance, a_dot_pos, b_dot_pos] for the closest living dot pair
	var best_d := INF
	var best_a: Vector2 = a.pos
	var best_b: Vector2 = b.pos
	for i in a.dot_pos.size():
		if not a.dot_alive[i]:
			continue
		for j in b.dot_pos.size():
			if not b.dot_alive[j]:
				continue
			var d: float = a.dot_pos[i].distance_to(b.dot_pos[j])
			if d < best_d:
				best_d = d
				best_a = a.dot_pos[i]
				best_b = b.dot_pos[j]
	return [best_d, best_a, best_b]

func _sync_casualties(c: Cluster) -> void:
	# Bring living dot count down to what power allows, killing the dots
	# closest to the last enemy contact point (the frontline) first
	var target := c.target_dots()
	while c.alive_count() > target:
		var kill_i := -1
		var best := INF
		for i in c.dot_alive.size():
			if not c.dot_alive[i]:
				continue
			var d: float = c.dot_pos[i].distance_squared_to(c.last_foe_pos)
			if d < best:
				best = d
				kill_i = i
		if kill_i == -1:
			break
		c.dot_alive[kill_i] = false

func _move_cluster(c: Cluster, step: float) -> void:
	# Follow the computed waypoint path
	while step > 0.0 and c.path.size() > 0:
		var wp: Vector2 = c.path[0]
		var d := c.pos.distance_to(wp)
		if d <= maxf(step, WAYPOINT_EPS):
			c.pos = wp
			c.path.remove_at(0)
			step -= d
		else:
			c.pos = c.pos.move_toward(wp, step)
			step = 0.0

func _update_dots(c: Cluster) -> void:
	# Each dot moves individually toward its formation slot (squeezed by
	# obstacles like water); when the cluster stops, dots walk back into
	# formation — never teleport
	var dir := Vector2.RIGHT
	if c.path.size() > 0:
		dir = (c.path[0] - c.pos).normalized()
	elif c.pos != c.prev_pos:
		dir = (c.pos - c.prev_pos).normalized()
	for i in c.dot_offsets.size():
		c.dot_prev[i] = c.dot_pos[i]
		if not c.dot_alive[i]:
			continue
		var desired := _dot_target(c.pos, dir, c.dot_offsets[i])
		# A dot with a clear straight line to its slot walks it directly; drop
		# any detour route the moment line-of-sight comes back
		if _dot_los_clear(c.dot_pos[i], desired):
			c.dot_paths[i] = []
			var next: Vector2 = c.dot_pos[i].move_toward(desired, DOT_SPEED * TICK_DT)
			if _dot_blocked(next):
				var slide_x := Vector2(next.x, c.dot_pos[i].y)
				var slide_y := Vector2(c.dot_pos[i].x, next.y)
				if not _dot_blocked(slide_x):
					next = slide_x
				elif not _dot_blocked(slide_y):
					next = slide_y
				else:
					next = c.dot_pos[i]
			c.dot_pos[i] = next
			continue
		# No line of sight — navigate an own route around the obstacle
		var escape: Array = c.dot_paths[i]
		if escape.is_empty():
			escape = _compute_path(c.dot_pos[i], desired)
			c.dot_paths[i] = escape
		if escape.size() > 0:
			var wp: Vector2 = escape[0]
			c.dot_pos[i] = c.dot_pos[i].move_toward(wp, DOT_SPEED * TICK_DT)
			if c.dot_pos[i].distance_to(wp) <= WAYPOINT_EPS:
				escape.remove_at(0)

func _blocked(p: Vector2) -> bool:
	for r in RIVER_RECTS:
		if r.grow(OBSTACLE_MARGIN).has_point(p) and not _on_bridge(p):
			return true
	for r in WALL_RECTS:
		if r.grow(OBSTACLE_MARGIN).has_point(p):
			return true
	return false

func _on_bridge(p: Vector2) -> bool:
	for r in BRIDGE_RECTS:
		if r.has_point(p):
			return true
	return false

func _nearest_living_enemy(from: Vector2):
	var best = null
	var best_d := INF
	for c in _clusters:
		if not c.is_enemy or not c.alive():
			continue
		var d := from.distance_squared_to(c.pos)
		if d < best_d:
			best_d = d
			best = c
	return best

func _nearest_living_ally(from: Vector2):
	var best = null
	var best_d := INF
	for c in _clusters:
		if c.is_enemy or not c.alive():
			continue
		var d := from.distance_squared_to(c.pos)
		if d < best_d:
			best_d = d
			best = c
	return best

func _first_living_ally():
	for c in _clusters:
		if not c.is_enemy and c.alive():
			return c
	return null

# --- Input --------------------------------------------------------------------
func _on_map_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = event.position
		match _mode:
			Mode.MARCH:
				var c = _selected if _selected != null else _first_living_ally()
				if c != null:
					c.target = p
					c.path = _compute_path(c.pos, p)
					c.player_order = true
					print("[SERIOS] SIM: march order -> ", p, " (", c.path.size(), " waypoints)")
				_mode = Mode.NONE
			Mode.PING:
				_pings.append({"pos": p, "ttl": PING_TTL})
				print("[SERIOS] SIM: ping @ ", p)
				_mode = Mode.NONE
			_:
				_try_select(p)

func _try_select(p: Vector2) -> void:
	for c in _clusters:
		if c.is_enemy or not c.alive():
			continue
		if p.distance_to(c.pos) <= CLUSTER_RADIUS + SELECT_PADDING:
			_selected = c
			print("[SERIOS] SIM: ally cluster selected")
			return
	_selected = null

# --- Drawing (reads sim state only) --------------------------------------------
func _dot_los_clear(from: Vector2, to: Vector2) -> bool:
	# Sampled line-of-sight check against obstacles (half-cell steps)
	var dist := from.distance_to(to)
	if dist < 1.0:
		return true
	var steps := int(ceil(dist / (GRID_CELL * 0.5)))
	for s in range(1, steps + 1):
		if _dot_blocked(from.lerp(to, float(s) / float(steps))):
			return false
	return true

func _dot_blocked(p: Vector2) -> bool:
	for r in RIVER_RECTS:
		if r.grow(DOT_RADIUS).has_point(p) and not _on_bridge(p):
			return true
	for r in WALL_RECTS:
		if r.grow(DOT_RADIUS).has_point(p):
			return true
	return false

func _dot_target(center: Vector2, dir: Vector2, offset: Vector2) -> Vector2:
	# Water behavior: a dot whose formation slot overlaps an obstacle first
	# collapses its sideways spread (forming a column along the travel
	# direction, e.g. on a narrow bridge), then shrinks toward the center.
	var p := center + offset
	if not _dot_blocked(p):
		return p
	var para := dir * offset.dot(dir)
	var perp := offset - para
	for k in [0.6, 0.3, 0.0]:
		p = center + para + perp * k
		if not _dot_blocked(p):
			return p
	for k in [0.6, 0.3, 0.0]:
		p = center + para * k
		if not _dot_blocked(p):
			return p
	return center

func _on_map_draw() -> void:
	var map: Control = $MapArea
	var t := clampf(_acc / TICK_DT, 0.0, 1.0)

	# Obstacles under everything: water, then bridges over it, then walls
	for r in RIVER_RECTS:
		map.draw_rect(r, WATER_COLOR)
	for r in BRIDGE_RECTS:
		map.draw_rect(r, BRIDGE_COLOR)
	for r in WALL_RECTS:
		map.draw_rect(r, WALL_COLOR)

	for c in _clusters:
		if not c.alive():
			continue
		var col: Color = c.color
		if c.in_combat:
			col.a = 0.55 + 0.45 * sin(_time * FLICKER_HZ * TAU)
		for i in c.dot_pos.size():
			if c.dot_alive[i]:
				map.draw_circle(c.dot_prev[i].lerp(c.dot_pos[i], t), DOT_RADIUS, col)
		if c == _selected:
			map.draw_arc(c.prev_pos.lerp(c.pos, t), CLUSTER_RADIUS + 8.0, 0.0, TAU, 48, Color(1, 1, 1, 0.9), 3.0)

	for p in _pings:
		var a: float = p["ttl"] / PING_TTL
		map.draw_arc(p["pos"], 30.0 + (1.0 - a) * 30.0, 0.0, TAU, 32, Color(1, 1, 1, a), 4.0)

# --- Buttons --------------------------------------------------------------------
func _on_call_help() -> void:
	print("[SERIOS] SIM: CallHelpBtn — call for help (not built)")

func _on_march() -> void:
	_mode = Mode.MARCH
	print("[SERIOS] SIM: march mode armed — click the map to set target")

func _on_ping() -> void:
	_mode = Mode.PING
	print("[SERIOS] SIM: ping mode armed — click the map to ping")

func _on_switch_view() -> void:
	print("[SERIOS] SIM: SwitchViewBtn — third-person view (not built)")

func _on_restart() -> void:
	_setup_sim()
	print("[SERIOS] SIM: restarted")
