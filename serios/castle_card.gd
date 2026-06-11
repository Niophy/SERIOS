# castle_card.gd
extends Control

signal castle_selected(card)

func _ready() -> void:
	$CastleBtn.pressed.connect(_on_pressed)

func _on_pressed() -> void:
	castle_selected.emit(self)

func set_players(text: String) -> void:
	$PlayersLabel.text = text
