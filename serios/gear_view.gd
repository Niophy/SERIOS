# gear_view.gd — reusable item viewer panel (item + stats only)
extends Panel

signal close_pressed

func _ready() -> void:
	$CloseBtn.pressed.connect(_on_close)
	$DisplayZone/PrevItemBtn.pressed.connect(_on_prev)
	$DisplayZone/NextItemBtn.pressed.connect(_on_next)
	$DisplayZone/ViewIn3DBtn.pressed.connect(_on_view_3d)
	$DisplayZone/StatStrip/StatInfoBtn.pressed.connect(_on_stat_info)

func set_item(data: Dictionary) -> void:
	var item_name: String = data.get("name", "Item Name")
	var tier: String = data.get("tier", "Common")
	$DisplayZone/NameLabel.text = item_name.to_upper()
	$DisplayZone/TierBadge.text = tier.to_upper()
	$DisplayZone/TypeLineLabel.text = "%s · %s · Water" % [data.get("slot", "Weapon"), tier]

func _on_close() -> void:
	close_pressed.emit()

func _on_prev() -> void:
	print("[SERIOS] CLICK: PrevItemBtn — previous item (not built)")

func _on_next() -> void:
	print("[SERIOS] CLICK: NextItemBtn — next item (not built)")

func _on_view_3d() -> void:
	print("[SERIOS] CLICK: ViewIn3DBtn — 3D view (not built)")

func _on_stat_info() -> void:
	print("[SERIOS] CLICK: StatInfoBtn — stat contribution info (not built)")
