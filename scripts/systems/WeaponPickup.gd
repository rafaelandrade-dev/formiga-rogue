extends Area2D

@export var weapon_data: Resource

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if weapon_data == null:
		return
	if weapon_data.sprite_path != "":
		sprite.texture = load(weapon_data.sprite_path)
		sprite.scale   = Vector2(0.03, 0.03)
	else:
		var img := Image.create(8, 8, false, Image.FORMAT_RGB8)
		img.fill(weapon_data.pickup_color)
		sprite.texture = ImageTexture.create_from_image(img)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("get_weapon_system"):
		body.get_weapon_system().try_pickup(weapon_data)
		queue_free()
