# commander_row.gd
extends Control

signal commander_selected(row)

var commander_data := {}

func _ready() -> void:
	$RowBtn.pressed.connect(_on_pressed)

func _on_pressed() -> void:
	commander_selected.emit(self)

func set_commander(data: Dictionary) -> void:
	commander_data = data
	$NameLabel.text = data.get("name", "Commander")
	$LevelLabel.text = "Lv. %d" % data.get("level", 1)
