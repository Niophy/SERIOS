# force_selection.gd
extends Control

func _ready() -> void:
	$BackBtn.pressed.connect(_on_back)
	$SoloBtn.pressed.connect(_on_solo)
	$DueBtn.pressed.connect(_on_due)
	$QuadBtn.pressed.connect(_on_quad)
	$TopRightBar/VigorSlot/VigorPlusBtn.pressed.connect(_on_vigor_plus)
	$TopRightBar/SettingBtn.pressed.connect(_on_settings)

func _on_back() -> void:
	Nav.go_to("res://main_menu.tscn")

func _on_solo() -> void:
	Nav.go_to("res://castle_selection.tscn")

func _on_due() -> void:
	Nav.go_to("res://team_castle_selection.tscn", {"mode": "Due"})

func _on_quad() -> void:
	Nav.go_to("res://team_castle_selection.tscn", {"mode": "Quad"})

func _on_vigor_plus() -> void:
	print("[SERIOS] CLICK: VigorPlusBtn — vigor purchase (not built)")

func _on_settings() -> void:
	print("[SERIOS] CLICK: SettingBtn — settings (not built)")
