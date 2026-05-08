extends CharacterBody2D

const GRAVITY          := 900.0
const ATTACK_INTERVAL  := 2.0
const ATTACK_ACTIVE    := 0.5
const STAGGER_DURATION := 0.8

const RESOURCE_PICKUP_SCENE = preload("res://scenes/shared/ResourcePickup.tscn")

var attack_timer  := 1.0
var is_attacking  := false
var is_staggered  := false
var stagger_timer := 0.0

# Veneno
var poison_dps         := 0.0
var poison_timer       := 0.0
var poison_print_timer := 0.0

@onready var sprite           : Sprite2D         = $Sprite2D
@onready var attack_area      : Area2D           = $AttackArea
@onready var attack_shape     : CollisionShape2D = $AttackArea/CollisionShape2D
@onready var health_component = $HealthComponent


func _ready() -> void:
	var img := Image.create(12, 18, false, Image.FORMAT_RGB8)
	img.fill(Color(0.85, 0.2, 0.2))
	sprite.texture = ImageTexture.create_from_image(img)
	_set_attack(false)
	attack_area.body_entered.connect(_on_attack_body_entered)
	health_component.died.connect(_on_died)


func _on_died() -> void:
	var count := randi_range(1, 3)
	for i in count:
		var pickup = RESOURCE_PICKUP_SCENE.instantiate()
		pickup.resource_type = "migalhas"
		pickup.amount        = 1
		pickup.global_position = global_position + Vector2(randf_range(-8.0, 8.0), 0.0)
		get_parent().add_child(pickup)
	print("[DummyEnemy] Morreu — dropou %d migalha(s)" % count)
	queue_free()


func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	move_and_slide()

	_tick_poison(delta)

	if is_staggered:
		stagger_timer -= delta
		sprite.modulate = Color(1, 1, 1) if fmod(stagger_timer, 0.2) < 0.1 else Color(1, 0.3, 0.3)
		if stagger_timer <= 0.0:
			is_staggered    = false
			sprite.modulate = Color(1, 1, 1)
		return

	attack_timer -= delta
	if attack_timer <= 0.0:
		if not is_attacking:
			is_attacking = true
			_set_attack(true)
			attack_timer = ATTACK_ACTIVE
		else:
			is_attacking = false
			_set_attack(false)
			attack_timer = ATTACK_INTERVAL


func _tick_poison(delta: float) -> void:
	if poison_timer <= 0.0:
		return
	poison_timer       -= delta
	poison_print_timer -= delta
	health_component.take_damage(poison_dps * delta, global_position)
	if poison_print_timer <= 0.0:
		poison_print_timer = 1.0
		print("[DummyEnemy] Veneno — HP: %.1f (%.1fs restante)" % [
			health_component.current_health, max(poison_timer, 0.0)
		])


func _set_attack(active: bool) -> void:
	attack_shape.disabled = not active


func receive_hit(damage: int, _knockback: Vector2) -> void:
	if is_staggered:
		return
	health_component.take_damage(float(damage), global_position)
	print("[DummyEnemy] Recebeu %d de dano — HP: %.1f" % [damage, health_component.current_health])


func receive_stagger() -> void:
	is_staggered  = true
	stagger_timer = STAGGER_DURATION
	is_attacking  = false
	attack_timer  = ATTACK_INTERVAL
	_set_attack(false)
	print("[DummyEnemy] Parry! Stagger por %.1fs" % STAGGER_DURATION)


func apply_poison(dps: float, duration: float) -> void:
	poison_dps         = dps
	poison_timer       = duration
	poison_print_timer = 0.0
	print("[DummyEnemy] Envenenado: %.1f dmg/s por %.1fs" % [dps, duration])


func _on_attack_body_entered(body: Node2D) -> void:
	if body.has_method("receive_attack"):
		var dir      := -1.0 if body.position.x > position.x else 1.0
		var knockback := Vector2(dir * 150.0, -100.0)
		body.receive_attack(1, knockback, self)
