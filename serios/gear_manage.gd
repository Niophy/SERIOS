# gear_manage.gd
extends Control

# Placeholder items until gear is data-driven (tier-only labels — no sub-stages on items)
const PLACEHOLDER_ITEMS := [
	{"name": "Tidebreaker Spear", "tier": "Rare", "slot": "Weapon"},
	{"name": "Blazebound Axe", "tier": "Epic", "slot": "Weapon"},
	{"name": "Verdant Bow", "tier": "Uncommon", "slot": "Weapon"},
	{"name": "Voidpiercer Lance", "tier": "Epic", "slot": "Weapon"},
	{"name": "Solar Hammer", "tier": "Legendary", "slot": "Weapon"},
	{"name": "Frostshard Spear", "tier": "Rare", "slot": "Weapon"},
	{"name": "Shadow Reaver", "tier": "Epic", "slot": "Weapon"},
	{"name": "Crimson Saber", "tier": "Epic", "slot": "Weapon"},
	{"name": "Gear Item 9", "tier": "Rare", "slot": "Helmet"},
	{"name": "Gear Item 10", "tier": "Common", "slot": "Helmet"},
	{"name": "Gear Item 11", "tier": "Uncommon", "slot": "Chest"},
	{"name": "Gear Item 12", "tier": "Rare", "slot": "Chest"},
	{"name": "Gear Item 13", "tier": "Epic", "slot": "Gloves"},
	{"name": "Gear Item 14", "tier": "Common", "slot": "Gloves"},
	{"name": "Gear Item 15", "tier": "Rare", "slot": "Legs"},
	{"name": "Gear Item 16", "tier": "Uncommon", "slot": "Legs"},
	{"name": "Gear Item 17", "tier": "Epic", "slot": "Ring"},
	{"name": "Gear Item 18", "tier": "Rare", "slot": "Ring"},
	{"name": "Gear Item 19", "tier": "Common", "slot": "Necklace"},
	{"name": "Gear Item 20", "tier": "Legendary", "slot": "Necklace"},
	{"name": "Gear Item 21", "tier": "Rare", "slot": "Glyph"},
	{"name": "Gear Item 22", "tier": "Epic", "slot": "Glyph"},
]

var current_item: Dictionary = PLACEHOLDER_ITEMS[0]
var _highlighted_cell = null

func _ready() -> void:
	# TopBar
	$TopBar/BackBtn.pressed.connect(_on_back)
	$TopBar/HelpBtn.pressed.connect(_on_help)
	$TopBar/ResourceBar/GoldSlot/GoldPlusBtn.pressed.connect(_on_gold_plus)
	$TopBar/ResourceBar/GemSlot/GemPlusBtn.pressed.connect(_on_gem_plus)
	$TopBar/SettingsBtn.pressed.connect(_on_settings)

	# Overview strip
	$OverviewStrip/ViewItemBtn.pressed.connect(_on_view_item)

	# Grid controls
	$GridPanel/AllTabBtn.pressed.connect(_on_all_tab)
	$GridPanel/SlotFilterBtn.pressed.connect(_on_slot_filter)
	$GridPanel/SortBtn.pressed.connect(_on_sort)

	# Cells — tap once to lock (highlight), tap again to confirm, hold to view
	var cells := $GridPanel/CellScroll/CellGrid.get_children()
	for i in cells.size():
		var cell = cells[i]
		cell.set_item(PLACEHOLDER_ITEMS[i % PLACEHOLDER_ITEMS.size()])
		cell.cell_tapped.connect(_on_cell_tapped)
		cell.cell_held.connect(_on_cell_held)

	# Equipment panel
	$EquipmentPanel/ConfirmSelectionBtn.pressed.connect(_on_confirm_selection)

	# Viewer overlay (hidden until VIEW)
	$GearView.close_pressed.connect(_on_viewer_close)
	_update_strip()

func _update_strip() -> void:
	$OverviewStrip/SelectedItemNameLabel.text = current_item.get("name", "Item Name")
	$OverviewStrip/StripTierLabel.text = current_item.get("tier", "Common")
	$OverviewStrip/StripSlotLabel.text = current_item.get("slot", "Weapon")

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

func _on_all_tab() -> void:
	print("[SERIOS] CLICK: AllTabBtn — show all (not built)")

func _on_slot_filter() -> void:
	print("[SERIOS] CLICK: SlotFilterBtn — slot filter (not built)")

func _on_sort() -> void:
	print("[SERIOS] CLICK: SortBtn — sort (not built)")

func _on_cell_tapped(cell) -> void:
	if _highlighted_cell == cell:
		# Second tap on the highlighted cell = confirm pick into its slot
		_equip_item(cell.item_data)
		cell.set_highlighted(false)
		_highlighted_cell = null
	else:
		# First tap = lock onto the cell (highlight border) and show it in the strip
		if _highlighted_cell != null:
			_highlighted_cell.set_highlighted(false)
		cell.set_highlighted(true)
		_highlighted_cell = cell
		current_item = cell.item_data
		_update_strip()
		print("[SERIOS] LOCKED ON: ", current_item.get("name", cell.name))

func _on_cell_held(cell) -> void:
	print("[SERIOS] HOLD: viewing ", cell.item_data.get("name", cell.name))
	current_item = cell.item_data
	_update_strip()
	$GearView.set_item(current_item)
	$DimBackdrop.visible = true
	$GearView.visible = true

func _equip_item(item: Dictionary) -> void:
	# The picked item goes into its respected slot box (real stat move is runtime)
	var slot_name := str(item.get("slot", "Weapon"))
	var box = $EquipmentPanel.get_node_or_null(slot_name + "Box")
	if box:
		box.get_node("SlotTierLabel").text = str(item.get("tier", "Common")).to_upper()
	print("[SERIOS] EQUIPPED: ", item.get("name", "?"), " -> ", slot_name, " slot")

func _on_confirm_selection() -> void:
	print("[SERIOS] CLICK: ConfirmSelectionBtn — equipment confirmed")
	Nav.go_to("res://generals.tscn")

func _on_view_item() -> void:
	$GearView.set_item(current_item)
	$DimBackdrop.visible = true
	$GearView.visible = true

func _on_viewer_close() -> void:
	$DimBackdrop.visible = false
	$GearView.visible = false
