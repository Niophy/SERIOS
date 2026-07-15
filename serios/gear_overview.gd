# gear_overview.gd
extends Control

# Placeholder items until gear is data-driven (tier-only labels — no sub-stages on items)
const PLACEHOLDER_ITEMS := [
	{"name": "Tidebreaker Spear", "tier": "Rare"},
	{"name": "Blazebound Axe", "tier": "Epic"},
	{"name": "Verdant Bow", "tier": "Uncommon"},
	{"name": "Voidpiercer Lance", "tier": "Epic"},
	{"name": "Solar Hammer", "tier": "Legendary"},
	{"name": "Frostshard Spear", "tier": "Rare"},
	{"name": "Shadow Reaver", "tier": "Epic"},
	{"name": "Crimson Saber", "tier": "Epic"},
]

var slot_type := "Weapon"
var _highlighted_row = null

func _ready() -> void:
	slot_type = str(Nav.payload.get("slot", "Weapon"))

	# TopBar
	$TopBar/BackBtn.pressed.connect(_on_back)
	$TopBar/HelpBtn.pressed.connect(_on_help)
	$TopBar/ResourceBar/GoldSlot/GoldPlusBtn.pressed.connect(_on_gold_plus)
	$TopBar/ResourceBar/GemSlot/GemPlusBtn.pressed.connect(_on_gem_plus)
	$TopBar/SettingsBtn.pressed.connect(_on_settings)
	$TopBar/TitleLabel.text = "GENERALS > " + slot_type.to_upper()

	# Items list (this slot type only)
	$ItemsList/SlotHeaderBtn.text = "ALL " + slot_type.to_upper() + "S"
	$ItemsList/SlotHeaderBtn.pressed.connect(_on_slot_header)
	# Rows — tap once to lock (highlight), tap again to confirm, hold to view
	var rows := $ItemsList/ItemScroll/ItemList.get_children()
	for i in rows.size():
		var row = rows[i]
		row.set_item(PLACEHOLDER_ITEMS[i % PLACEHOLDER_ITEMS.size()])
		row.item_tapped.connect(_on_item_tapped)
		row.item_held.connect(_on_item_held)

	# Viewer overlay — open by default on the placeholder item
	$GearView.close_pressed.connect(_on_viewer_close)
	$GearView.set_item({"name": "Tidebreaker Spear", "tier": "Rare", "slot": slot_type})

func _on_back() -> void:
	Nav.go_to("res://generals.tscn")

func _on_help() -> void:
	print("[SERIOS] CLICK: HelpBtn — help (not built)")

func _on_gold_plus() -> void:
	print("[SERIOS] CLICK: GoldPlusBtn — gold purchase (not built)")

func _on_gem_plus() -> void:
	print("[SERIOS] CLICK: GemPlusBtn — gem purchase (not built)")

func _on_settings() -> void:
	print("[SERIOS] CLICK: SettingsBtn — settings (not built)")

func _on_slot_header() -> void:
	print("[SERIOS] CLICK: SlotHeaderBtn — slot dropdown (not built)")

func _on_item_tapped(row) -> void:
	if _highlighted_row == row:
		# Second tap on the highlighted row = confirm pick
		print("[SERIOS] SELECT CONFIRMED: ", row.item_data.get("name", row.name), " — equip/assign (not built)")
		row.set_highlighted(false)
		_highlighted_row = null
	else:
		# First tap = lock onto the row (highlight border)
		if _highlighted_row != null:
			_highlighted_row.set_highlighted(false)
		row.set_highlighted(true)
		_highlighted_row = row
		print("[SERIOS] LOCKED ON: ", row.item_data.get("name", row.name))

func _on_item_held(row) -> void:
	print("[SERIOS] HOLD: viewing ", row.item_data.get("name", row.name))
	$GearView.set_item({
		"name": row.item_data.get("name", "Item Name"),
		"tier": row.item_data.get("tier", "Common"),
		"slot": slot_type,
	})
	$DimBackdrop.visible = true
	$GearView.visible = true

func _on_viewer_close() -> void:
	$DimBackdrop.visible = false
	$GearView.visible = false
