extends Node
class_name HealthComponent

signal health_changed(old_val: float, new_val: float)
signal died()

@export var max_health: float = 100.0
var current_health: float


func _ready() -> void:
	current_health = max_health


func take_damage(amount: float, _source_position: Vector2) -> void:
	if current_health <= 0.0:
		return
	var old_val := current_health
	current_health = max(0.0, current_health - amount)
	health_changed.emit(old_val, current_health)
	if current_health <= 0.0:
		died.emit()


func heal(amount: float) -> void:
	if current_health <= 0.0:
		return
	var old_val := current_health
	current_health = min(max_health, current_health + amount)
	health_changed.emit(old_val, current_health)
