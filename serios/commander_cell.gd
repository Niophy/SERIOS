# commander_cell.gd
extends Control

signal cell_tapped(cell)
signal cell_held(cell)

const HOLD_TIME := 0.5

var commander_data := {}
var _hold_timer: Timer

func _ready() -> void:
	_hold_timer = Timer.new()
	_hold_timer.one_shot = true
	_hold_timer.wait_time = HOLD_TIME
	_hold_timer.timeout.connect(_on_hold_timeout)
	add_child(_hold_timer)
	$CellBtn.button_down.connect(_on_button_down)
	$CellBtn.button_up.connect(_on_button_up)

func _on_button_down() -> void:
	_hold_timer.start()

func _on_button_up() -> void:
	if _hold_timer.time_left > 0:
		_hold_timer.stop()
		cell_tapped.emit(self)

func _on_hold_timeout() -> void:
	cell_held.emit(self)

func set_commander(data: Dictionary) -> void:
	commander_data = data
	$LevelLabel.text = "Lv. %d" % data.get("level", 1)

func set_highlighted(is_on: bool) -> void:
	$HighlightBorder.visible = is_on

func set_locked(is_locked: bool) -> void:
	$LockLabel.visible = is_locked
	if is_locked:
		modulate = Color(0.6, 0.6, 0.6)
	else:
		modulate = Color(1, 1, 1)
