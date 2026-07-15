# generals.gd
extends Control

# Placeholder data until heroes are data-driven
const PLACEHOLDER_HEROES := [
	{"name": "Xu Huang", "tier": "Epic III"},
	{"name": "Hero Two", "tier": "Epic I"},
	{"name": "Hero Three", "tier": "Rare III"},
	{"name": "Hero Four", "tier": "Rare II"},
	{"name": "Hero Five", "tier": "Uncommon II"},
	{"name": "Hero Six", "tier": "Common I"},
]

const GEAR_SLOT_NAMES := ["Helmet", "Chest", "Gloves", "Legs", "Ring", "Necklace", "Weapon", "Glyph"]

# Four-skill kit per GDD §9.6 — Glyph is the ultimate
const SKILL_SLOT_NAMES := ["Hero", "Weapon", "Buff/Debuff", "Glyph"]

func _ready() -> void:
	# TopBar
	$TopBar/BackBtn.pressed.connect(_on_back)
	$TopBar/HelpBtn.pressed.connect(_on_help)
	$TopBar/ResourceBar/DrillSlot/DrillPlusBtn.pressed.connect(_on_drill_plus)
	$TopBar/ResourceBar/GoldSlot/GoldPlusBtn.pressed.connect(_on_gold_plus)
	$TopBar/ResourceBar/GemSlot/GemPlusBtn.pressed.connect(_on_gem_plus)
	$TopBar/SettingsBtn.pressed.connect(_on_settings)

	# HeroesList
	$HeroesList/FilterBtn.pressed.connect(_on_filter)
	var cards := $HeroesList/HeroScroll/HeroList.get_children()
	for i in cards.size():
		var card = cards[i]
		card.set_hero(PLACEHOLDER_HEROES[i % PLACEHOLDER_HEROES.size()])
		card.hero_selected.connect(_on_hero_selected)

	# HeroDisplay
	$HeroDisplay/FavoriteBtn.pressed.connect(_on_favorite)
	$HeroDisplay/ShareBtn.pressed.connect(_on_share)
	$HeroDisplay/AppearanceBtn.pressed.connect(_on_appearance)

	# RightPanel tabs
	$RightPanel/OverviewBtn.pressed.connect(_on_overview_tab)
	$RightPanel/AttributesBtn.pressed.connect(_on_attributes_tab)

	# Commanders section
	var commander_row := $RightPanel/OverviewPanel/CommandersSection/CommanderSlotsRow
	for i in commander_row.get_child_count():
		var slot = commander_row.get_child(i)
		if i < 4:
			slot.set_label("Commander %d" % (i + 1))
		else:
			slot.set_label("")
			slot.set_locked(true)
		slot.slot_selected.connect(_on_commander_slot)
	$RightPanel/OverviewPanel/CommandersSection/InfoBtn.pressed.connect(_on_commanders_info)
	$RightPanel/OverviewPanel/CommandersSection/ManageCommandersBtn.pressed.connect(_on_manage_commanders)

	# Gear section
	var gear_row := $RightPanel/OverviewPanel/GearSection/GearSlotsRow
	for i in gear_row.get_child_count():
		var slot = gear_row.get_child(i)
		slot.set_label(GEAR_SLOT_NAMES[i])
		slot.slot_selected.connect(_on_gear_slot)
	$RightPanel/OverviewPanel/GearSection/ManageGearBtn.pressed.connect(_on_manage_gear)

	# Skills section
	var skill_row := $RightPanel/OverviewPanel/SkillsSection/SkillSlotsRow
	for i in skill_row.get_child_count():
		var slot = skill_row.get_child(i)
		slot.set_label(SKILL_SLOT_NAMES[i])
		slot.slot_selected.connect(_on_skill_slot)
	$RightPanel/OverviewPanel/SkillsSection/ManageSkillsBtn.pressed.connect(_on_manage_skills)

func _on_back() -> void:
	Nav.go_to("res://main_menu.tscn")

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

func _on_filter() -> void:
	print("[SERIOS] CLICK: FilterBtn — hero filter (not built)")

func _on_hero_selected(card) -> void:
	print("[SERIOS] HERO SELECTED: ", card.hero_data.get("name", card.name))
	$HeroDisplay/NameLabel.text = card.hero_data.get("name", "Hero Name")
	$HeroDisplay/TierBadge.text = card.hero_data.get("tier", "Epic III")

func _on_favorite() -> void:
	print("[SERIOS] CLICK: FavoriteBtn — favorite (not built)")

func _on_share() -> void:
	print("[SERIOS] CLICK: ShareBtn — share (not built)")

func _on_appearance() -> void:
	print("[SERIOS] CLICK: AppearanceBtn — appearance (not built)")

func _on_overview_tab() -> void:
	$RightPanel/OverviewPanel.visible = true
	$RightPanel/AttributesPanel.visible = false

func _on_attributes_tab() -> void:
	$RightPanel/OverviewPanel.visible = false
	$RightPanel/AttributesPanel.visible = true

func _on_commander_slot(slot) -> void:
	Nav.go_to("res://commander_overview.tscn", {"slot": str(slot.name)})

func _on_commanders_info() -> void:
	print("[SERIOS] CLICK: InfoBtn — commanders info (not built)")

func _on_manage_commanders() -> void:
	Nav.go_to("res://commander_selection.tscn")

func _on_gear_slot(slot) -> void:
	Nav.go_to("res://gear_overview.tscn", {"slot": slot.get_label()})

func _on_manage_gear() -> void:
	Nav.go_to("res://gear_manage.tscn")

func _on_skill_slot(slot) -> void:
	Nav.go_to("res://generals_stub.tscn", {"section": "Skill — " + slot.get_label()})

func _on_manage_skills() -> void:
	Nav.go_to("res://generals_stub.tscn", {"section": "Manage Skills"})
