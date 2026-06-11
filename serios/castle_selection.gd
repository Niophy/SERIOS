# castle_selection.gd
extends Control

func _ready() -> void:
	$BackBtn.pressed.connect(_on_back)
	$TopRightBar/VigorSlot/VigorPlusBtn.pressed.connect(_on_vigor_plus)
	$TopRightBar/SettingBtn.pressed.connect(_on_settings)

	# Filter buttons
	$FilterPanel/AllFilterBtn.pressed.connect(_on_filter.bind("All"))
	$FilterPanel/RareFilterBtn.pressed.connect(_on_filter.bind("Rare"))
	$FilterPanel/UncommonFilterBtn.pressed.connect(_on_filter.bind("Uncommon"))
	$FilterPanel/CommonFilterBtn.pressed.connect(_on_filter.bind("Common"))

	$RefreshBtn.pressed.connect(_on_refresh)

	# Connect every castle card's signal
	for card in $CastleGrid.get_children():
		if card.has_signal("castle_selected"):
			card.castle_selected.connect(_on_castle_selected)

func _on_back() -> void:
	Nav.go_to("res://matchmaking.tscn")

func _on_castle_selected(card) -> void:
	print("[SERIOS] CASTLE SELECTED: ", card.name)

func _on_filter(rarity: String) -> void:
	print("[SERIOS] FILTER: ", rarity)

func _on_refresh() -> void:
	print("[SERIOS] CLICK: RefreshBtn")

func _on_vigor_plus() -> void:
	print("[SERIOS] CLICK: VigorPlusBtn")

func _on_settings() -> void:
	print("[SERIOS] CLICK: SettingBtn")
