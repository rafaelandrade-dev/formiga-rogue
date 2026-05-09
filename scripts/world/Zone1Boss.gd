extends Node2D

const BOSS_SCENE = preload("res://scenes/enemies/RainhaVespa.tscn")

var boss:         Node2D = null
var fight_started: bool  = false
var fight_won:     bool  = false

var _canvas:    CanvasLayer = null
var _bar_bg:    ColorRect   = null
var _bar_fill:  ColorRect   = null
var _bar_label: Label       = null

@onready var entry_trigger: Area2D = $EntryTrigger
@onready var boss_spawn: Marker2D  = $BossSpawn


func _ready() -> void:
	entry_trigger.body_entered.connect(_on_player_entered)
	_build_hp_bar()


func _on_player_entered(body: Node2D) -> void:
	if fight_started or fight_won:
		return
	if not body.has_method("get_weapon_system"):
		return
	_start_fight(body)


func _start_fight(player: Node2D) -> void:
	fight_started = true

	var zone := get_parent()
	if zone.has_method("lock_entry_gate"):
		zone.call("lock_entry_gate")

	boss = BOSS_SCENE.instantiate()
	boss.global_position = boss_spawn.global_position
	get_parent().add_child(boss)
	boss.boss_hp_changed.connect(_on_boss_hp)
	boss.boss_died.connect(_on_boss_died)
	boss.activate(player)

	_canvas.visible = true
	_set_bar(300.0, 300.0)
	print("[Zone1Boss] Luta iniciada!")


func _on_boss_hp(current: float, maximum: float) -> void:
	_set_bar(current, maximum)


func _on_boss_died() -> void:
	fight_won = true
	print("[Zone1Boss] Boss derrotado! Abrindo saída.")
	get_tree().create_timer(0.8).timeout.connect(func():
		_canvas.visible = false)

	var zone := get_parent()
	if zone.has_method("open_exit_gate"):
		zone.call("open_exit_gate")


# ── Barra de HP ───────────────────────────────────────────────────────────────
func _build_hp_bar() -> void:
	_canvas         = CanvasLayer.new()
	_canvas.layer   = 10
	_canvas.visible = false
	add_child(_canvas)

	# Container escuro
	_bar_bg          = ColorRect.new()
	_bar_bg.color    = Color(0.08, 0.04, 0.12, 0.88)
	_bar_bg.size     = Vector2(204.0, 14.0)
	_bar_bg.position = Vector2(58.0, 6.0)
	_canvas.add_child(_bar_bg)

	# Borda interna para highlight
	var border         := ColorRect.new()
	border.color        = Color(0.55, 0.1, 0.65, 0.6)
	border.size         = Vector2(204.0, 14.0)
	border.position     = Vector2(0.0, 0.0)
	_bar_bg.add_child(border)

	# Preenchimento da vida
	_bar_fill          = ColorRect.new()
	_bar_fill.color    = Color(0.78, 0.12, 0.88)
	_bar_fill.size     = Vector2(200.0, 10.0)
	_bar_fill.position = Vector2(2.0, 2.0)
	_bar_bg.add_child(_bar_fill)

	# Nome do boss
	_bar_label          = Label.new()
	_bar_label.text     = "Rainha Vespa"
	_bar_label.position = Vector2(58.0, 22.0)
	_bar_label.add_theme_color_override("font_color", Color(0.95, 0.85, 1.0))
	_bar_label.add_theme_font_size_override("font_size", 7)
	_canvas.add_child(_bar_label)


func _set_bar(current: float, maximum: float) -> void:
	if _bar_fill == null or maximum <= 0.0:
		return
	_bar_fill.size.x = 200.0 * clamp(current / maximum, 0.0, 1.0)
