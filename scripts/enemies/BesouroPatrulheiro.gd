extends "res://scripts/enemies/BaseEnemy.gd"

const CHARGE_WINDUP   := 0.80  # segundos de vento-up parado
const CHARGE_SPEED    := 380.0 # velocidade durante o avanço
const CHARGE_DURATION := 0.45  # duração do avanço

var _atk_timer := 0.0
var _charging  := false  # false = wind-up, true = avanço


func _ready() -> void:
	move_speed       = 60.0
	detection_radius = 120.0
	attack_range     = 28.0
	attack_cooldown  = 2.5
	super._ready()
	var img := Image.create(14, 10, false, Image.FORMAT_RGB8)
	img.fill(Color(0.2, 0.45, 0.85))
	sprite.texture = ImageTexture.create_from_image(img)


func _do_attack(delta: float) -> void:
	_atk_timer += delta

	if not _charging:
		# Wind-up: para e pisca laranja
		velocity.x      = move_toward(velocity.x, 0.0, 800.0 * delta)
		var blink        := fmod(_atk_timer, 0.15) < 0.075
		sprite.modulate  = Color(1.7, 0.85, 0.1) if blink else Color(1, 1, 1)
		if _atk_timer >= CHARGE_WINDUP:
			_charging = true
	else:
		# Avanço em linha reta
		sprite.modulate = Color(1, 1, 1)
		var dir         := 1.0 if facing_right else -1.0
		velocity.x       = dir * CHARGE_SPEED
		if player and absf(global_position.x - player.global_position.x) < 22.0:
			_deal_damage_to_player(25, Vector2(dir * 260.0, -130.0))
		if _atk_timer >= CHARGE_WINDUP + CHARGE_DURATION:
			_charging       = false
			_atk_timer      = 0.0
			sprite.modulate = Color(1, 1, 1)
			attack_timer    = attack_cooldown
			fsm.change(State.CHASE if can_see_player else State.PATROL)


func receive_stagger() -> void:
	if _charging:
		return  # invulnerável durante o avanço; apenas o wind-up pode ser parried
	sprite.modulate = Color(1, 1, 1)
	_charging       = false
	_atk_timer      = 0.0
	super.receive_stagger()
