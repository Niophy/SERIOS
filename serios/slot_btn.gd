# slot_btn.gd
extends Control

signal slot_selected(slot)

func _ready() -> void:
	$SlotBtn.pressed.connect(_on_pressed)

func _on_pressed() -> void:
	slot_selected.emit(self)

func set_label(text: String) -> void:
	$SlotLabel.text = text

func get_label() -> String:
	return $SlotLabel.text

func set_locked(is_locked: bool) -> void:
	$LockLabel.visible = is_locked
	$SlotBtn.disabled = is_locked
	if is_locked:
		modulate = Color(0.6, 0.6, 0.6)
	else:
		modulate = Color(1, 1, 1)
