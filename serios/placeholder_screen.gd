# placeholder_screen.gd
extends Control

func _ready() -> void:
	$BackBtn.pressed.connect(_on_back)

func _on_back() -> void:
	Nav.go_to("res://main_menu.tscn")
