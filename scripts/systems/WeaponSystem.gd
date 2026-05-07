extends Node
class_name WeaponSystem

# ── Slots ─────────────────────────────────────────────────────────────────────
var slots: Array = [null, null]   # [WeaponData | null, WeaponData | null]
var active: int  = 0              # 0-indexed

# ── Prompt state ──────────────────────────────────────────────────────────────
var prompt_active:  bool       = false
var pending_weapon = null

# ── Prompt UI (criado via código para evitar dependência de .tscn) ────────────
var _canvas: CanvasLayer
var _panel:  ColorRect
var _label:  Label


func _ready() -> void:
	_build_prompt_ui()


func _process(_delta: float) -> void:
	if prompt_active:
		_handle_prompt_input()
	elif Input.is_action_just_pressed("weapon_swap"):
		_swap()


# ── API pública ───────────────────────────────────────────────────────────────
func get_weapon():
	return slots[active]


func get_attack_speed() -> float:
	var w = get_weapon()
	return w.attack_speed if w else 1.0


func get_reach() -> float:
	var w = get_weapon()
	return w.reach if w else 10.0


func try_pickup(weapon) -> void:
	for i in 2:
		if slots[i] == null:
			_equip(i, weapon)
			return
	# Ambos os slots cheios → exibir prompt
	pending_weapon = weapon
	prompt_active  = true
	_show_prompt(weapon)


func clear_on_death() -> void:
	slots[0]    = null
	slots[1]    = null
	active      = 0
	prompt_active = false
	_panel.visible = false
	print("[Arma] Slots limpos ao morrer")


# ── Internos ──────────────────────────────────────────────────────────────────
func _equip(idx: int, weapon) -> void:
	slots[idx] = weapon
	print("[Arma] Slot %d → %s  (dmg L:%.0f H:%.0f  spd:%.1fx  alcance:%.0fpx  efeito:%s)" % [
		idx + 1, weapon.weapon_name,
		weapon.damage_light, weapon.damage_heavy,
		weapon.attack_speed, weapon.reach, weapon.special_effect
	])


func _swap() -> void:
	active = 1 - active
	var w = get_weapon()
	print("[Arma] Ativo: slot %d — %s" % [active + 1, w.weapon_name if w else "Vazio"])


func _handle_prompt_input() -> void:
	if Input.is_action_just_pressed("attack_light"):
		_equip(0, pending_weapon)
		_close_prompt()
	elif Input.is_action_just_pressed("attack_heavy"):
		_equip(1, pending_weapon)
		_close_prompt()
	elif Input.is_action_just_pressed("interact"):
		print("[Arma] Descartada: %s" % pending_weapon.weapon_name)
		_close_prompt()


func _close_prompt() -> void:
	pending_weapon = null
	prompt_active  = false
	_panel.visible = false


# ── Prompt UI ─────────────────────────────────────────────────────────────────
func _build_prompt_ui() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 10
	add_child(_canvas)

	_panel = ColorRect.new()
	_panel.color    = Color(0.0, 0.0, 0.0, 0.78)
	_panel.position = Vector2(16.0, 116.0)
	_panel.size     = Vector2(288.0, 58.0)
	_canvas.add_child(_panel)

	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 7)
	_panel.add_child(_label)

	_panel.visible = false


func _show_prompt(weapon) -> void:
	var s1: String = slots[0].weapon_name if slots[0] else "Vazio"
	var s2: String = slots[1].weapon_name if slots[1] else "Vazio"
	_label.text = "Nova arma: %s\n[Z] Slot 1: %s   [X] Slot 2: %s   [F] Descartar" % [
		weapon.weapon_name, s1, s2
	]
	_panel.visible = true
