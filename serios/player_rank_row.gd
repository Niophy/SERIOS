# player_rank_row.gd
extends Control

signal player_pressed(row)
signal alliance_pressed(row)

var rank_data := {}

func _ready() -> void:
	$PlayerBtn.pressed.connect(_on_player)
	$AllianceBtn.pressed.connect(_on_alliance)

func _on_player() -> void:
	player_pressed.emit(self)

func _on_alliance() -> void:
	alliance_pressed.emit(self)

func set_data(data: Dictionary) -> void:
	rank_data = data
	$RankLabel.text = str(data.get("rank", 0))
	$NameLabel.text = data.get("name", "Player")
	$PowerLabel.text = data.get("power", "0")
	$AllianceLabel.text = data.get("alliance", "—")
	$AchievementsLabel.text = str(data.get("achievements", 0))
