# commander_overview.gd
extends Control

# Placeholder data until commanders are data-driven (levels cap at 20)
const PLACEHOLDER_COMMANDERS := [
	{"name": "Lady Zhen", "level": 18},
	{"name": "Xiahou Dun", "level": 17},
	{"name": "Zhao Yun", "level": 16},
	{"name": "Huang Zhong", "level": 15},
	{"name": "Xu Chu", "level": 8},
	{"name": "Da Qiao", "level": 6},
]

func _ready() -> void:
	# TopBar
	$TopBar/BackBtn.pressed.connect(_on_back)
	$TopBar/HelpBtn.pressed.connect(_on_help)
	$TopBar/ResourceBar/DrillSlot/DrillPlusBtn.pressed.connect(_on_drill_plus)
	$TopBar/ResourceBar/GoldSlot/GoldPlusBtn.pressed.connect(_on_gold_plus)
	$TopBar/ResourceBar/GemSlot/GemPlusBtn.pressed.connect(_on_gem_plus)
	$TopBar/SettingsBtn.pressed.connect(_on_settings)

	# Commanders list
	var rows := $CommandersList/ListScroll/RowList.get_children()
	for i in rows.size():
		var row = rows[i]
		row.set_commander(PLACEHOLDER_COMMANDERS[i % PLACEHOLDER_COMMANDERS.size()])
		row.commander_selected.connect(_on_commander_selected)

func _on_back() -> void:
	Nav.go_to("res://generals.tscn")

func _on_help() -> void:
	print("[SERIOS] CLICK: HelpBtn — help (not built)")

func _on_drill_plus() -> void:
	print("[SERIOS] CLICK: DrillPlusBtn — drill manual purchase (not built)")

func _on_gold_plus() -> void:
	print("[SERIOS] CLICK: GoldPlusBtn — gold purchase (not built)")

func _on_gem_plus() -> void:
	print("[SERIOS] CLICK: GemPlusBtn — gem purchase (not built)")

func _on_settings() -> void:
	print("[SERIOS] CLICK: SettingsBtn — settings (not built)")

func _on_commander_selected(row) -> void:
	print("[SERIOS] COMMANDER SELECTED: ", row.commander_data.get("name", row.name))
	$CommanderDisplay/NameLabel.text = str(row.commander_data.get("name", "Commander")).to_upper()
	$CommanderDisplay/LevelBadge.text = str(row.commander_data.get("level", 1))
