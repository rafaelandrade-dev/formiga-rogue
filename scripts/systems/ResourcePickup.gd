extends Area2D

@export var resource_type: String = "migalhas"
@export var amount: int = 1

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	var img := Image.create(5, 5, false, Image.FORMAT_RGB8)
	match resource_type:
		"migalhas": img.fill(Color(0.95, 0.80, 0.20))
		"nectar":   img.fill(Color(0.85, 0.35, 0.90))
		"quitina":  img.fill(Color(0.40, 0.80, 0.45))
		_:          img.fill(Color(1.0,  1.0,  1.0 ))
	sprite.texture = ImageTexture.create_from_image(img)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("get_weapon_system"):
		ResourceManager.add_resource(resource_type, amount)
		queue_free()
