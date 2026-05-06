extends CharacterBody2D

const GRAVITY          := 900.0
const ATTACK_INTERVAL  := 2.0
const ATTACK_ACTIVE    := 0.5
const STAGGER_DURATION := 0.8

var hp            := 5
var attack_timer  := 1.0
var is_attacking  := false
var is_staggered  := false
var stagger_timer := 0.0

@onready var sprite       : Sprite2D         = $Sprite2D
@onready var attack_area  : Area2D           = $AttackArea
@onready var attack_shape : CollisionShape2D = $AttackArea/CollisionShape2D


func _ready() -> void:
	var img := Image.create(12, 18, false, Image.FORMAT_RGB8)
	img.fill(Color(0.85, 0.2, 0.2))
	sprite.texture = ImageTexture.create_from_image(img)
	_set_attack(false)
	attack_area.body_entered.connect(_on_attack_body_entered)


func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	move_and_slide()

	if is_staggered:
		stagger_timer -= delta
		# Flash white/red to signal stagger
		sprite.modulate = Color(1, 1, 1) if fmod(stagger_timer, 0.2) < 0.1 else Color(1, 0.3, 0.3)
		if stagger_timer <= 0.0:
			is_staggered   = false
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


func _set_attack(active: bool) -> void:
	attack_shape.disabled = not active


func receive_hit(damage: int, _knockback: Vector2) -> void:
	if is_staggered:
		return
	hp -= damage
	if hp <= 0:
		queue_free()


func receive_stagger() -> void:
	is_staggered  = true
	stagger_timer = STAGGER_DURATION
	is_attacking  = false
	attack_timer  = ATTACK_INTERVAL
	_set_attack(false)


func _on_attack_body_entered(body: Node2D) -> void:
	if body.has_method("receive_attack"):
		var dir      := -1.0 if body.position.x > position.x else 1.0
		var knockback := Vector2(dir * 150.0, -100.0)
		body.receive_attack(1, knockback, self)
