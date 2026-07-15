# commander_selection.gd
extends Control

# Placeholder data until commanders are data-driven (levels cap at 20)
const PLACEHOLDER_GRID := [
	{"name": "Lady Zhen", "level": 18},
	{"name": "Xiahou Dun", "level": 17},
	{"name": "Zhao Yun", "level": 16},
	{"name": "Huang Zhong", "level": 15},
	{"name": "Commander 5", "level": 14},
	{"name": "Commander 6", "level": 13},
	{"name": "Commander 7", "level": 12},
	{"name": "Xu Chu", "level": 12},
	{"name": "Commander 9", "level": 11},
	{"name": "Da Qiao", "level": 10},
	{"name": "Commander 11", "level": 10},
	{"name": "Commander 12", "level": 9},
	{"name": "Commander 13", "level": 9},
	{"name": "Commander 14", "level": 8},
]

var _highlighted_cell = null

const PLACEHOLDER_SELECTED := [
	{"name": "Lady Zhen", "level": 18},
	{"name": "Xiahou Dun", "level": 17},
	{"name": "Zhao Yun", "level": 16},
	{"name": "Huang Zhong", "level": 15},
]

func _ready() -> void:
	# TopBar
	$TopBar/BackBtn.pressed.connect(_on_back)
	$TopBar/HelpBtn.pressed.connect(_on_help)
	$TopBar/ResourceBar/DrillSlot/DrillPlusBtn.pressed.connect(_on_drill_plus)
	$TopBar/ResourceBar/GoldSlot/GoldPlusBtn.pressed.connect(_on_gold_plus)
	$TopBar/ResourceBar/GemSlot/GemPlusBtn.pressed.connect(_on_gem_plus)
	$TopBar/SettingsBtn.pressed.connect(_on_settings)

	# Tabs and filters
	$GridPanel/AllCommandersTabBtn.pressed.connect(_on_tab.bind("All Commanders"))
	$GridPanel/LockedTabBtn.pressed.connect(_on_tab.bind("Locked"))
	$GridPanel/ElementFilterBtn.pressed.connect(_on_element_filter)
	$GridPanel/SortBtn.pressed.connect(_on_sort)

	# Grid cells — tap once to lock (highlight), tap again to confirm, hold to view
	var cells := $GridPanel/CellScroll/CellGrid.get_children()
	for i in cells.size():
		var cell = cells[i]
		cell.set_commander(PLACEHOLDER_GRID[i % PLACEHOLDER_GRID.size()])
		cell.cell_tapped.connect(_on_cell_tapped)
		cell.cell_held.connect(_on_cell_held)

	# Detail viewer overlay (hidden until a cell is held)
	$CommanderView.close_pressed.connect(_on_viewer_close)

	# Selected commanders
	for i in PLACEHOLDER_SELECTED.size():
		var row = get_node("SelectedPanel/SelectedRow%d" % (i + 1))
		row.set_commander(PLACEHOLDER_SELECTED[i])
		row.commander_selected.connect(_on_selected_row)
		get_node("SelectedPanel/LockBtn%d" % (i + 1)).pressed.connect(_on_lock.bind(i + 1))

	$SelectedPanel/ConfirmSelectionBtn.pressed.connect(_on_confirm)
	$FooterBar/InfoBtn.pressed.connect(_on_bonus_info)

func _on_back() -> void:
	Nav.go_to("res://generals.tscn")

func _on_help() -> void:
	print("[SERIOS] CLICK: HelpBtn — help (not built)")

func _on_drill_plus() -> void:
	print("[SERIOS] CLICK: DrillPlusBtn — drill manual purchase (not built)")

func _on_gold_plus() -> void:
	print("[SERIOS] CLICK: GoldPlusBtn — gold purchase (not built)")

func _on_gem_plus() -> void:
	print("[SERIOS] CLICK: GemPlusBtn — gem purchase (not built)")

func _on_settings() -> void:
	print("[SERIOS] CLICK: SettingsBtn — settings (not built)")

func _on_tab(tab: String) -> void:
	print("[SERIOS] CLICK: ", tab, " tab — filter (not built)")

func _on_element_filter() -> void:
	print("[SERIOS] CLICK: ElementFilterBtn — element filter (not built)")

func _on_sort() -> void:
	print("[SERIOS] CLICK: SortBtn — sort (not built)")

func _on_cell_tapped(cell) -> void:
	if _highlighted_cell == cell:
		# Second tap on the highlighted cell = confirm pick
		print("[SERIOS] SELECT CONFIRMED: ", cell.commander_data.get("name", cell.name), " — swap into chosen (not built)")
		cell.set_highlighted(false)
		_highlighted_cell = null
	else:
		# First tap = lock onto the cell (highlight border)
		if _highlighted_cell != null:
			_highlighted_cell.set_highlighted(false)
		cell.set_highlighted(true)
		_highlighted_cell = cell
		print("[SERIOS] LOCKED ON: ", cell.commander_data.get("name", cell.name))

func _on_cell_held(cell) -> void:
	print("[SERIOS] HOLD: viewing ", cell.commander_data.get("name", cell.name))
	$CommanderView.set_commander(cell.commander_data)
	$DimBackdrop.visible = true
	$CommanderView.visible = true

func _on_viewer_close() -> void:
	$DimBackdrop.visible = false
	$CommanderView.visible = false

func _on_selected_row(row) -> void:
	print("[SERIOS] SELECTED ROW: ", row.commander_data.get("name", row.name))

func _on_lock(slot_index: int) -> void:
	print("[SERIOS] CLICK: LockBtn", slot_index, " — lock toggle (not built)")

func _on_confirm() -> void:
	print("[SERIOS] CLICK: ConfirmSelectionBtn")
	Nav.go_to("res://generals.tscn")

func _on_bonus_info() -> void:
	print("[SERIOS] CLICK: InfoBtn — commander bonus info (not built)")
