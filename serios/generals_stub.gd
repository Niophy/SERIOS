# generals_stub.gd
extends Control

func _ready() -> void:
	$BackBtn.pressed.connect(_on_back)
	$TitleLabel.text = str(Nav.payload.get("section", "Generals — Stub"))

func _on_back() -> void:
	Nav.go_to(str(Nav.payload.get("back", "res://generals.tscn")))
