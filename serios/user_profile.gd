# user_profile.gd
extends Control

# Unlocked heroes only — same placeholder set as the Generals screen
const PLACEHOLDER_HEROES := [
	{"name": "Xu Huang", "tier": "Epic III"},
	{"name": "Hero Two", "tier": "Epic I"},
	{"name": "Hero Three", "tier": "Rare III"},
	{"name": "Hero Four", "tier": "Rare II"},
	{"name": "Hero Five", "tier": "Uncommon II"},
	{"name": "Hero Six", "tier": "Common I"},
]

var _is_visitor := false

func _ready() -> void:
	$TopBar/BackBtn.pressed.connect(_on_back)
	$TopBar/SettingsBtn.pressed.connect(_on_settings)
	$IdentityInfoPanel/EditNameBtn.pressed.connect(_on_edit_name)
	$IdentityInfoPanel/AlliancePanel/AllianceBtn.pressed.connect(_on_alliance)
	$IdentityInfoPanel/RankingPanel/RankingBtn.pressed.connect(_on_ranking)
	$AchievementsPanel/ViewAllBtn.pressed.connect(_on_achievements)
	$TabBar/ProfileTabBtn.pressed.connect(_on_profile_tab)
	$TabBar/HeroesTabBtn.pressed.connect(_on_heroes_tab)
	$TabBar/TitlesTabBtn.pressed.connect(_on_tab.bind("Titles"))
	$TabBar/StatisticsTabBtn.pressed.connect(_on_tab.bind("Statistics"))

	# Heroes tab grid — unlocked heroes only
	var cells := $HeroesPanel/HeroCellScroll/HeroCellGrid.get_children()
	for i in cells.size():
		var cell = cells[i]
		cell.set_hero(PLACEHOLDER_HEROES[i % PLACEHOLDER_HEROES.size()])
		cell.cell_tapped.connect(_on_hero_cell_tapped)
		cell.cell_held.connect(_on_hero_cell_held)

	# When opened from Rankings, show the clicked player's card in visitor view
	if Nav.payload.has("player"):
		$IdentityInfoPanel/PlayerNameLabel.text = str(Nav.payload.get("player"))
		_apply_visitor_view()

func _apply_visitor_view() -> void:
	# Only statistics are private to the profile owner — visitors see the rest
	# (view-only: the edit control is hidden too)
	_is_visitor = true
	$IdentityInfoPanel/EditNameBtn.visible = false
	$StatsPanel.visible = false
	$TabBar/StatisticsTabBtn.disabled = true

func _show_profile(show_profile: bool) -> void:
	$IdentityPanel.visible = show_profile
	$IdentityInfoPanel.visible = show_profile
	$MostPlayedPanel.visible = show_profile
	$AchievementsPanel.visible = show_profile
	$BattleRecordPanel.visible = show_profile
	$StatsPanel.visible = show_profile and not _is_visitor
	$HeroesPanel.visible = not show_profile

func _on_profile_tab() -> void:
	_show_profile(true)

func _on_heroes_tab() -> void:
	_show_profile(false)

func _on_hero_cell_tapped(cell) -> void:
	print("[SERIOS] HERO CELL: ", cell.hero_data.get("name", cell.name), " — (not built)")

func _on_hero_cell_held(cell) -> void:
	print("[SERIOS] HOLD: hero view — ", cell.hero_data.get("name", cell.name), " (not built)")

func _on_alliance() -> void:
	var alliance_name: String = $IdentityInfoPanel/AlliancePanel/AllianceNameLabel.text
	print("[SERIOS] CLICK: AllianceBtn — view alliance overview: ", alliance_name)
	Nav.go_to("res://generals_stub.tscn", {"section": "Alliance — " + alliance_name, "back": "res://user_profile.tscn"})

func _on_back() -> void:
	Nav.go_to(str(Nav.payload.get("back", "res://main_menu.tscn")))

func _on_settings() -> void:
	print("[SERIOS] CLICK: SettingsBtn — settings (not built)")

func _on_edit_name() -> void:
	print("[SERIOS] CLICK: EditNameBtn — name edit (not built)")

func _on_ranking() -> void:
	Nav.go_to("res://rankings.tscn")

func _on_achievements() -> void:
	Nav.go_to("res://generals_stub.tscn", {"section": "Achievements", "back": "res://user_profile.tscn"})

func _on_tab(tab: String) -> void:
	print("[SERIOS] CLICK: ", tab, " tab — (not built)")
