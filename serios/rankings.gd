# rankings.gd
extends Control

# Placeholder leaderboard data until rankings are server-driven
const PLACEHOLDER_PLAYERS := [
	{"rank": 1, "name": "Jaber", "power": "265,480", "alliance": "IRON OATH", "achievements": 512},
	{"rank": 2, "name": "Valkor", "power": "251,320", "alliance": "CRIMSON LEGION", "achievements": 443},
	{"rank": 3, "name": "Elysia", "power": "244,890", "alliance": "VERDANT GUARD", "achievements": 378},
	{"rank": 4, "name": "Noctis", "power": "238,410", "alliance": "SHADOW REALM", "achievements": 301},
	{"rank": 5, "name": "Grimnir", "power": "231,900", "alliance": "EMBER EMPIRE", "achievements": 267},
	{"rank": 6, "name": "Thalassa", "power": "225,340", "alliance": "TIDEBORN", "achievements": 211},
	{"rank": 7, "name": "Aurelius", "power": "219,870", "alliance": "LUMEN KNIGHTS", "achievements": 164},
	{"rank": 8, "name": "Ravenor", "power": "214,520", "alliance": "BLACK RAVENS", "achievements": 143},
]

const PLACEHOLDER_ALLIANCES := [
	{"rank": 1, "name": "IRON OATH", "power": "2,845,730,912", "members": "96/100"},
	{"rank": 2, "name": "CRIMSON LEGION", "power": "2,317,860,445", "members": "98/100"},
	{"rank": 3, "name": "VERDANT GUARD", "power": "1,987,456,231", "members": "94/100"},
	{"rank": 4, "name": "SHADOW REALM", "power": "1,745,338,664", "members": "92/100"},
	{"rank": 5, "name": "EMBER EMPIRE", "power": "1,512,889,907", "members": "90/100"},
	{"rank": 6, "name": "TIDEBORN", "power": "1,238,450,771", "members": "88/100"},
	{"rank": 7, "name": "LUMEN KNIGHTS", "power": "987,654,320", "members": "95/100"},
	{"rank": 8, "name": "BLACK RAVENS", "power": "853,229,118", "members": "86/100"},
]

func _ready() -> void:
	$TopBar/BackBtn.pressed.connect(_on_back)
	$MainPanel/PlayersTabBtn.pressed.connect(_on_players_tab)
	$MainPanel/AlliancesTabBtn.pressed.connect(_on_alliances_tab)

	var player_rows := $MainPanel/PlayersPanel/PlayerRowList.get_children()
	for i in player_rows.size():
		var row = player_rows[i]
		row.set_data(PLACEHOLDER_PLAYERS[i % PLACEHOLDER_PLAYERS.size()])
		row.player_pressed.connect(_on_player_pressed)
		row.alliance_pressed.connect(_on_alliance_pressed_from_player)

	var alliance_rows := $MainPanel/AlliancesPanel/AllianceRowList.get_children()
	for i in alliance_rows.size():
		var row = alliance_rows[i]
		row.set_data(PLACEHOLDER_ALLIANCES[i % PLACEHOLDER_ALLIANCES.size()])
		row.alliance_pressed.connect(_on_alliance_pressed)

func _on_back() -> void:
	Nav.go_to("res://user_profile.tscn")

func _on_players_tab() -> void:
	$MainPanel/PlayersPanel.visible = true
	$MainPanel/AlliancesPanel.visible = false

func _on_alliances_tab() -> void:
	$MainPanel/PlayersPanel.visible = false
	$MainPanel/AlliancesPanel.visible = true

func _on_player_pressed(row) -> void:
	print("[SERIOS] RANKINGS: view player card — ", row.rank_data.get("name", "?"))
	Nav.go_to("res://user_profile.tscn", {"player": row.rank_data.get("name", "Player"), "back": "res://rankings.tscn"})

func _on_alliance_pressed_from_player(row) -> void:
	_open_alliance_stats(str(row.rank_data.get("alliance", "Alliance")))

func _on_alliance_pressed(row) -> void:
	_open_alliance_stats(str(row.rank_data.get("name", "Alliance")))

func _open_alliance_stats(alliance_name: String) -> void:
	# Alliance stats scene comes next — stub until then
	print("[SERIOS] RANKINGS: view alliance stats — ", alliance_name)
	Nav.go_to("res://generals_stub.tscn", {"section": "Alliance — " + alliance_name, "back": "res://rankings.tscn"})
