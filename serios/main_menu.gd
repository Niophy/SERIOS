# main_menu.gd
extends Control

func _ready() -> void:
	_connect_all_buttons(self)
	# Mode button navigation
	$ModeButtons/CampaignBtn.pressed.connect(_on_campaign)
	$ModeButtons/BattleBtn.pressed.connect(_on_battle)
	$ModeButtons/MatchmakingBtn.pressed.connect(_on_matchmaking)
	$ModeButtons/WarBtn.pressed.connect(_on_war)

func _on_campaign() -> void:
	Nav.go_to("res://campaign.tscn")

func _on_battle() -> void:
	Nav.go_to("res://battle.tscn")

func _on_matchmaking() -> void:
	Nav.go_to("res://matchmaking.tscn")

func _on_war() -> void:
	Nav.go_to("res://war.tscn")

func _connect_all_buttons(node: Node) -> void:
	for child in node.get_children():
		if child is Button and child.name.ends_with("Btn"):
			child.pressed.connect(_on_btn_pressed.bind(child.name))
			child.mouse_entered.connect(_on_btn_hover.bind(child.name))
			print("[SERIOS] Registered: ", child.name, " (", child.get_path(), ")")
		_connect_all_buttons(child)

func _on_btn_pressed(btn_name: String) -> void:
	print("[SERIOS] CLICK: ", btn_name)

func _on_btn_hover(btn_name: String) -> void:
	print("[SERIOS] HOVER: ", btn_name)
