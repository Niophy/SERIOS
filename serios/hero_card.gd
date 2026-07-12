# hero_card.gd
extends Control

signal hero_selected(card)

var hero_data := {}

func _ready() -> void:
	$HeroCardBtn.pressed.connect(_on_pressed)

func _on_pressed() -> void:
	hero_selected.emit(self)

func set_hero(data: Dictionary) -> void:
	hero_data = data
	$NameLabel.text = data.get("name", "Hero Name")
	$TierLabel.text = data.get("tier", "Epic III")
