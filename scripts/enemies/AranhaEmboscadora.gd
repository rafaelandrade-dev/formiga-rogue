extends "res://scripts/enemies/BaseEnemy.gd"

const BITE_RANGE     := 50.0
const RETREAT_SPEED  := 100.0
const RETREAT_TIME   := 0.8  # 80px / 100px·s⁻¹

var _atk_timer    := 0.0
var _retreat_dir  := 1.0


func _ready() -> void:
	move_speed       = 0.0   # estática
	detection_radius = 55.0
	attack_range     = BITE_RANGE
	attack_cooldown  = 1.5
	super._ready()
	var img := Image.create(10, 8, false, Image.FORMAT_RGB8)
	img.fill(Color(0.1, 0.1, 0.15))
	sprite.texture = ImageTexture.create_from_image(img)


# Fica parada; verifica range para atacar direto do PATROL
func _do_patrol(_delta: float) -> void:
	velocity.x = 0.0
	if can_see_player and player and \
			absf(global_position.x - player.global_position.x) <= BITE_RANGE and \
			attack_timer <= 0.0:
		fsm.change(State.ATTACK)


# Não persegue — se player sair do bite range, volta a esperar
func _move_toward_player(_delta: float) -> void:
	velocity.x = 0.0


func _do_attack(delta: float) -> void:
	_atk_timer += delta
	velocity.x   = 0.0
	if _atk_timer < 0.2:
		sprite.modulate = Color(1.5, 0.3, 0.3)  # bote
	else:
		sprite.modulate = Color(1, 1, 1)
		if player and absf(global_position.x - player.global_position.x) <= BITE_RANGE:
			_deal_damage_to_player(15, Vector2.ZERO)
		_atk_timer   = 0.0
		attack_timer = attack_cooldown
		fsm.change(State.PATROL)


func _on_hurt_state(delta: float) -> void:
	# Recua na direção oposta ao player
	velocity.x      = move_toward(velocity.x, _retreat_dir * RETREAT_SPEED, 600.0 * delta)
	sprite.modulate = Color(1.5, 0.4, 0.4) if fmod(fsm.time, 0.1) < 0.05 else Color(1, 1, 1)
	if fsm.time >= RETREAT_TIME:
		velocity.x      = 0.0
		sprite.modulate = Color(1, 1, 1)
		fsm.change(State.PATROL)


func _on_health_changed(_old: float, new_val: float) -> void:
	if new_val <= 0.0:
		return
	print("[Aranha] HP: %.0f / %.0f" % [new_val, health_component.max_health])
	_retreat_dir = sign(global_position.x - player.global_position.x) if player else \
	               (1.0 if facing_right else -1.0)
	if _retreat_dir == 0.0:
		_retreat_dir = 1.0
	fsm.change(State.HURT)
