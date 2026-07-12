extends Control

const PlayerRowScene := preload("res://player_row.tscn")

# Safe lookups
@onready var back_btn: Button = get_node_or_null("BackBtn")
@onready var vigor_label: Label = get_node_or_null("TopRightBar/VigorSlot/VigorLabel")
@onready var allied_list: VBoxContainer = get_node_or_null("PlayerStatusPanel/AlliedList")

# Placeholder data until Khalifa's battle sim feeds real values
const PLACEHOLDER_ALLIES := [
	{"slot": 1, "name": "Player One",   "power": 112, "commanders": 4},
	{"slot": 2, "name": "Player Two",   "power": 105, "commanders": 4},
	{"slot": 3, "name": "Player Three", "power": 98,  "commanders": 3},
	{"slot": 4, "name": "Player Four",  "power": 101, "commanders": 4},
]

func _ready() -> void:
	print("[SERIOS] BattleOverview ready")

	# Report any missing node so we know what to fix
	if back_btn == null:     print("[SERIOS] MISSING: BackBtn")
	if vigor_label == null:  print("[SERIOS] MISSING: TopRightBar/VigorSlot/VigorLabel")
	if allied_list == null:  print("[SERIOS] MISSING: PlayerStatusPanel/AlliedList")

	if back_btn:
		back_btn.pressed.connect(_on_back_btn_pressed)
	if vigor_label:
		vigor_label.text = "Vigor 120/120"
	if allied_list:
		_spawn_allies()

func _get_allied_count() -> int:
	match Nav.payload.get("mode", "Solo"):
		"Due":  return 2
		"Quad": return 4
		_:      return 1

func _spawn_allies() -> void:
	for child in allied_list.get_children():
		child.queue_free()
	var count := _get_allied_count()
	for i in count:
		var row := PlayerRowScene.instantiate()
		allied_list.add_child(row)
		row.set_player(PLACEHOLDER_ALLIES[i])
		row.row_pressed.connect(_on_row_pressed)

func _on_row_pressed(data: Dictionary) -> void:
	print("Row pressed: ", data)  # overlay later

func _on_back_btn_pressed() -> void:
	print("[SERIOS] BACK pressed")
	match Nav.payload.get("mode", ""):
		"Due", "Quad":
			Nav.go_to("res://team_castle_selection.tscn", Nav.payload)
		_:
			Nav.go_to("res://castle_selection.tscn", Nav.payload)
