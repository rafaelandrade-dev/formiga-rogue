extends CharacterBody2D

const SPEED         := 100.0
const DAMAGE        := 8
const CONTACT_RANGE := 14.0
const CONTACT_CD    := 0.8

@onready var health_component = $HealthComponent
@onready var sprite: Sprite2D = $Sprite2D

var player:        Node2D = null
var contact_timer: float  = 0.0
var is_dead:       bool   = false


func _ready() -> void:
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(_on_hurt)
	var img := Image.create(8, 6, false, Image.FORMAT_RGB8)
	img.fill(Color(0.9, 0.75, 0.1))
	sprite.texture = ImageTexture.create_from_image(img)


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	contact_timer = max(0.0, contact_timer - delta)
	if player and is_instance_valid(player):
		var dir := (player.global_position - global_position).normalized()
		velocity = dir * SPEED
		sprite.flip_h = velocity.x < 0.0
		if contact_timer <= 0.0 and global_position.distance_to(player.global_position) < CONTACT_RANGE:
			if player.has_method("receive_attack"):
				player.receive_attack(DAMAGE, dir * 100.0, self)
				contact_timer = CONTACT_CD
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 200.0 * delta)
	move_and_slide()


func receive_hit(damage: int, _knockback: Vector2) -> void:
	if is_dead:
		return
	health_component.take_damage(float(damage), global_position)


func receive_stagger() -> void:
	receive_hit(15, Vector2.ZERO)


func _on_hurt(_old: float, new_val: float) -> void:
	if new_val > 0.0:
		sprite.modulate = Color(1.5, 0.5, 0.5)
		get_tree().create_timer(0.1).timeout.connect(func():
			if not is_dead: sprite.modulate = Color(1, 1, 1))


func _on_died() -> void:
	is_dead = true
	sprite.modulate = Color(0.5, 0.5, 0.5)
	set_physics_process(false)
	get_tree().create_timer(0.3).timeout.connect(queue_free)
