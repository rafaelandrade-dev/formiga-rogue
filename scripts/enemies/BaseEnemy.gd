extends CharacterBody2D
class_name BaseEnemy

enum State { IDLE, PATROL, CHASE, ATTACK, STAGGERED, HURT, DEAD }

const GRAVITY          := 900.0
const STAGGER_DURATION := 0.8
const HURT_DURATION    := 0.30
const LOSE_SIGHT_TIME  := 3.0

@export var move_speed       : float          = 80.0
@export var detection_radius : float          = 100.0
@export var attack_range     : float          = 24.0
@export var attack_cooldown  : float          = 2.0
@export var patrol_points    : Array[Vector2] = []

@onready var sprite           : Sprite2D         = $Sprite2D
@onready var health_component                    = $HealthComponent
@onready var fsm                                 = $EnemyStateMachine
@onready var detection_area   : Area2D           = $DetectionArea

const RESOURCE_PICKUP = preload("res://scenes/shared/ResourcePickup.tscn")

var player           : Node2D  = null
var can_see_player   : bool    = false
var patrol_origin    : Vector2 = Vector2.ZERO
var patrol_index     : int     = 0
var facing_right     : bool    = true
var attack_timer     : float   = 0.0
var lose_sight_timer : float   = 0.0

var poison_dps   := 0.0
var poison_timer := 0.0


func _ready() -> void:
	patrol_origin = global_position
	_resize_detection(detection_radius)
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(_on_health_changed)
	detection_area.body_entered.connect(_on_detection_entered)
	detection_area.body_exited.connect(_on_detection_exited)
	fsm.change(State.PATROL)


func _physics_process(delta: float) -> void:
	fsm.time    += delta
	attack_timer = max(0.0, attack_timer - delta)
	velocity.y  += GRAVITY * delta
	_tick_poison(delta)
	_run_state(delta)
	move_and_slide()
	_update_facing()


# ── State machine ─────────────────────────────────────────────────────────────
func _run_state(delta: float) -> void:
	match fsm.current:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, move_speed * 6.0 * delta)
			if fsm.time > 1.5:
				fsm.change(State.PATROL)

		State.PATROL:
			_do_patrol(delta)
			if can_see_player and fsm.current == State.PATROL:
				fsm.change(State.CHASE)

		State.CHASE:
			if not can_see_player:
				lose_sight_timer += delta
				if lose_sight_timer >= LOSE_SIGHT_TIME:
					player           = null
					lose_sight_timer = 0.0
					fsm.change(State.PATROL)
			else:
				lose_sight_timer = 0.0
				if player:
					var dist := absf(global_position.x - player.global_position.x)
					if dist <= attack_range and attack_timer <= 0.0:
						fsm.change(State.ATTACK)
					else:
						_move_toward_player(delta)

		State.ATTACK:
			_do_attack(delta)

		State.STAGGERED:
			velocity.x      = move_toward(velocity.x, 0.0, move_speed * 6.0 * delta)
			sprite.modulate = Color(1, 1, 1) if fmod(fsm.time, 0.2) < 0.1 else Color(1, 0.3, 0.3)
			if fsm.time >= STAGGER_DURATION:
				sprite.modulate = Color(1, 1, 1)
				fsm.change(State.CHASE if can_see_player else State.PATROL)

		State.HURT:
			_on_hurt_state(delta)

		State.DEAD:
			velocity.x = move_toward(velocity.x, 0.0, move_speed * 4.0 * delta)


# ── Virtual methods ───────────────────────────────────────────────────────────
func _do_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		if is_on_wall():
			facing_right = not facing_right
		var dir := 1.0 if facing_right else -1.0
		velocity.x = move_toward(velocity.x, dir * move_speed, move_speed * 8.0 * delta)
	else:
		var target := patrol_origin + patrol_points[patrol_index]
		var dx     := target.x - global_position.x
		if absf(dx) < 4.0:
			patrol_index = (patrol_index + 1) % patrol_points.size()
		else:
			velocity.x = move_toward(velocity.x, sign(dx) * move_speed, move_speed * 8.0 * delta)


func _move_toward_player(delta: float) -> void:
	if not player:
		return
	var dx := player.global_position.x - global_position.x
	velocity.x = move_toward(velocity.x, sign(dx) * move_speed, move_speed * 8.0 * delta)


func _do_attack(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, move_speed * 6.0 * delta)
	if player and absf(global_position.x - player.global_position.x) <= attack_range:
		_deal_damage_to_player(10, Vector2.ZERO)
	attack_timer = attack_cooldown
	fsm.change(State.CHASE if can_see_player else State.PATROL)


func _on_hurt_state(delta: float) -> void:
	velocity.x      = move_toward(velocity.x, 0.0, move_speed * 4.0 * delta)
	sprite.modulate = Color(1.5, 0.4, 0.4) if fmod(fsm.time, 0.1) < 0.05 else Color(1, 1, 1)
	if fsm.time >= HURT_DURATION:
		sprite.modulate = Color(1, 1, 1)
		fsm.change(State.CHASE if can_see_player else State.PATROL)


# ── Helpers ───────────────────────────────────────────────────────────────────
func _deal_damage_to_player(damage: int, knockback: Vector2) -> void:
	if not player or not player.has_method("receive_attack"):
		return
	if knockback == Vector2.ZERO:
		var dir: float = signf(player.global_position.x - global_position.x)
		knockback = Vector2(dir * 150.0, -80.0)
	player.receive_attack(damage, knockback, self)


func _update_facing() -> void:
	if absf(velocity.x) > 4.0:
		facing_right  = velocity.x > 0.0
		sprite.flip_h = not facing_right


func _resize_detection(radius: float) -> void:
	var shape_node := detection_area.get_node_or_null("CollisionShape2D")
	if shape_node and shape_node.shape is CircleShape2D:
		(shape_node.shape as CircleShape2D).radius = radius


func _tick_poison(delta: float) -> void:
	if poison_timer <= 0.0:
		return
	poison_timer -= delta
	health_component.take_damage(poison_dps * delta, global_position)


# ── Detection callbacks ───────────────────────────────────────────────────────
func _on_detection_entered(body: Node2D) -> void:
	if body.has_method("get_weapon_system"):
		player         = body
		can_see_player = true
		if fsm.current not in [State.ATTACK, State.STAGGERED, State.HURT, State.DEAD]:
			fsm.change(State.CHASE)


func _on_detection_exited(body: Node2D) -> void:
	if body == player:
		can_see_player = false
		lose_sight_timer = 0.0


# ── Public API (called by Player) ─────────────────────────────────────────────
func receive_hit(damage: int, knockback: Vector2) -> void:
	if fsm.current == State.DEAD:
		return
	velocity = knockback
	health_component.take_damage(float(damage), global_position)


func receive_stagger() -> void:
	if fsm.current == State.DEAD:
		return
	velocity.x      = 0.0
	sprite.modulate = Color(1, 1, 1)
	fsm.change(State.STAGGERED)
	print("[%s] Parry! Stagger" % name)


func apply_poison(dps: float, duration: float) -> void:
	poison_dps   = maxf(poison_dps, dps)
	poison_timer = maxf(poison_timer, duration)
	print("[%s] Envenenado: %.1f dmg/s por %.1fs" % [name, dps, duration])


# ── HealthComponent callbacks ─────────────────────────────────────────────────
func _on_health_changed(_old: float, new_val: float) -> void:
	if new_val > 0.0 and fsm.current != State.DEAD:
		fsm.change(State.HURT)
	print("[%s] HP: %.0f / %.0f" % [name, new_val, health_component.max_health])


func _on_died() -> void:
	fsm.change(State.DEAD)
	sprite.modulate = Color(0.5, 0.5, 0.5)
	_drop_resources()
	get_tree().create_timer(0.6).timeout.connect(queue_free)


func _drop_resources() -> void:
	var count := randi_range(1, 3)
	for i in count:
		var pickup = RESOURCE_PICKUP.instantiate()
		pickup.resource_type   = "migalhas"
		pickup.amount          = 1
		pickup.global_position = global_position + Vector2(randf_range(-8.0, 8.0), 0.0)
		get_parent().add_child(pickup)
	print("[%s] Dropou %d migalha(s)" % [name, count])
