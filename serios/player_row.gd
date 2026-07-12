extends Panel

@onready var slot_badge: Label = $SlotBadge
@onready var name_label: Label = $NameLabel
@onready var power_label: Label = $PowerLabel
@onready var commanders_label: Label = $CommandersLabel
@onready var row_btn: Button = $RowBtn

var player_data := {}

signal row_pressed(data)

func _ready() -> void:
	row_btn.pressed.connect(_on_row_btn_pressed)

func set_player(data: Dictionary) -> void:
	player_data = data
	slot_badge.text = str(data.get("slot", ""))
	name_label.text = data.get("name", "Player name")
	power_label.text = str(data.get("power", 100)) + "%"
	commanders_label.text = "C" + str(data.get("commanders", 0))

func set_gated(is_gated: bool) -> void:
	row_btn.disabled = is_gated
	if is_gated:
		name_label.text = "Locked — scout to reveal"
		power_label.text = ""
		commanders_label.text = ""
		modulate = Color(0.6, 0.6, 0.6)
	else:
		modulate = Color(1, 1, 1)

func _on_row_btn_pressed() -> void:
	row_pressed.emit(player_data)
