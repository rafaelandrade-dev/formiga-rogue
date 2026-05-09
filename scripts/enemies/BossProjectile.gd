extends Area2D

const SPEED   := 180.0
const DAMAGE  := 12
const LIFETIME := 1.8

var direction: Vector2 = Vector2.RIGHT
var _time: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_hit)
	var img := Image.create(6, 6, false, Image.FORMAT_RGB8)
	img.fill(Color(1.0, 0.45, 0.1))
	$Sprite2D.texture = ImageTexture.create_from_image(img)


func _physics_process(delta: float) -> void:
	_time += delta
	if _time >= LIFETIME:
		queue_free()
		return
	position += direction * SPEED * delta


func _on_hit(body: Node2D) -> void:
	if body.has_method("receive_attack"):
		body.receive_attack(DAMAGE, direction * 150.0, self)
		queue_free()
