# commander_view.gd — reusable commander detail panel (commander + stats only)
extends Panel

signal close_pressed

func _ready() -> void:
	$CloseBtn.pressed.connect(_on_close)

func set_commander(data: Dictionary) -> void:
	$DisplayZone/NameLabel.text = str(data.get("name", "Commander")).to_upper()
	$DisplayZone/LevelBadge.text = str(data.get("level", 1))

func _on_close() -> void:
	close_pressed.emit()
