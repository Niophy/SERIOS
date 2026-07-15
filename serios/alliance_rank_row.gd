# alliance_rank_row.gd
extends Control

signal alliance_pressed(row)

var rank_data := {}

func _ready() -> void:
	$RowBtn.pressed.connect(_on_pressed)

func _on_pressed() -> void:
	alliance_pressed.emit(self)

func set_data(data: Dictionary) -> void:
	rank_data = data
	$RankLabel.text = str(data.get("rank", 0))
	$NameLabel.text = data.get("name", "Alliance")
	$PowerLabel.text = data.get("power", "0")
	$MembersLabel.text = data.get("members", "0/100")
