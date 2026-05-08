extends "res://scripts/enemies/BaseEnemy.gd"

const JUMP_VEL      := -270.0
const JUMP_COOLDOWN := 1.0
const FLEE_SPEED    := 150.0
const FLEE_DURATION := 1.0

var _jump_timer := 0.0
var _flee_timer := 0.0
var _flee_dir   := 1.0
var _fleeing    := false


func _ready() -> void:
	move_speed       = 130.0
	detection_radius = 130.0
	attack_range     = 18.0
	attack_cooldown  = 1.0
	super._ready()
	var img := Image.create(10, 14, false, Image.FORMAT_RGB8)
	img.fill(Color(0.35, 0.75, 0.15))
	sprite.texture = ImageTexture.create_from_image(img)


func _physics_process(delta: float) -> void:
	_jump_timer = max(0.0, _jump_timer - delta)
	super._physics_process(delta)


func _move_toward_player(delta: float) -> void:
	if not player:
		return
	var dx := player.global_position.x - global_position.x
	if is_on_floor() and _jump_timer <= 0.0:
		velocity.y  = JUMP_VEL
		velocity.x  = sign(dx) * move_speed
		_jump_timer = JUMP_COOLDOWN
	elif not is_on_floor():
		velocity.x = move_toward(velocity.x, sign(dx) * move_speed, move_speed * 5.0 * delta)


func _do_attack(_delta: float) -> void:
	if player and absf(global_position.x - player.global_position.x) <= attack_range:
		_deal_damage_to_player(10, Vector2.ZERO)
	attack_timer = attack_cooldown
	fsm.change(State.CHASE if can_see_player else State.PATROL)


func _on_hurt_state(delta: float) -> void:
	if _fleeing:
		_flee_timer    -= delta
		velocity.x      = move_toward(velocity.x, _flee_dir * FLEE_SPEED, move_speed * 6.0 * delta)
		sprite.modulate = Color(1.5, 0.4, 0.4) if fmod(fsm.time, 0.1) < 0.05 else Color(1, 1, 1)
		if _flee_timer <= 0.0:
			_fleeing        = false
			sprite.modulate = Color(1, 1, 1)
			fsm.change(State.CHASE if can_see_player else State.PATROL)
	else:
		super._on_hurt_state(delta)


func _on_health_changed(_old: float, new_val: float) -> void:
	if new_val <= 0.0:
		return
	print("[Gafanhoto] HP: %.0f / %.0f" % [new_val, health_component.max_health])
	if randf() < 0.5 and player:
		_flee_dir   = sign(global_position.x - player.global_position.x)
		if _flee_dir == 0.0:
			_flee_dir = 1.0
		_flee_timer = FLEE_DURATION
		_fleeing    = true
		print("[Gafanhoto] Fugindo!")
	fsm.change(State.HURT)
