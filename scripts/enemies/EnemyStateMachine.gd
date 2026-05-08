extends Node
class_name EnemyStateMachine

signal state_changed(from_state: int, to_state: int)

var current: int = 0
var time:    float = 0.0


func change(new_state: int) -> void:
	if new_state == current:
		return
	state_changed.emit(current, new_state)
	current = new_state
	time    = 0.0
