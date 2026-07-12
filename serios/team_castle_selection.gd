# team_castle_selection.gd
extends Control

var mode: String = "Due"  # set from Nav payload

func _ready() -> void:
	# Read which mode opened this screen
	if Nav.payload.has("mode"):
		mode = Nav.payload.mode

	# Player count per castle card based on mode
	var player_count := "2" if mode == "Due" else "4"
	for card in $CastleGrid.get_children():
		if card.has_method("set_players"):
			card.set_players(player_count)
		if card.has_signal("castle_selected"):
			card.castle_selected.connect(_on_castle_selected)

	# Top bar
	$BackBtn.pressed.connect(_on_back)
	$TopRightBar/VigorSlot/VigorPlusBtn.pressed.connect(_on_vigor_plus)
	$TopRightBar/SettingBtn.pressed.connect(_on_settings)

	# Filters
	$FilterPanel/AllFilterBtn.pressed.connect(_on_filter.bind("All"))
	$FilterPanel/RareFilterBtn.pressed.connect(_on_filter.bind("Rare"))
	$FilterPanel/UncommonFilterBtn.pressed.connect(_on_filter.bind("Uncommon"))
	$FilterPanel/CommonFilterBtn.pressed.connect(_on_filter.bind("Common"))

	# Actions
	$RefreshBtn.pressed.connect(_on_refresh)
	$QueueBtn.pressed.connect(_on_queue)
	$InviteBtn.pressed.connect(_on_invite)

func _on_back() -> void:
	Nav.go_to("res://matchmaking.tscn")

func _on_castle_selected(card) -> void:
	print("[SERIOS] CASTLE SELECTED: ", card.name)
	Nav.payload["castle"] = card.name
	Nav.go_to("res://battle_overview.tscn")

func _on_filter(rarity: String) -> void:
	print("[SERIOS] FILTER: ", rarity)

func _on_refresh() -> void:
	print("[SERIOS] CLICK: RefreshBtn")

func _on_queue() -> void:
	print("[SERIOS] CLICK: QueueBtn (", mode, ")")

func _on_invite() -> void:
	print("[SERIOS] CLICK: InviteBtn (", mode, ")")

func _on_vigor_plus() -> void:
	print("[SERIOS] CLICK: VigorPlusBtn")

func _on_settings() -> void:
	print("[SERIOS] CLICK: SettingBtn")
