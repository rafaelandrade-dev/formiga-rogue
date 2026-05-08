extends Node

var migalhas: int = 0
var nectar:   int = 0
var quitina:  int = 0

signal resources_changed()


func add_resource(type: String, amount: int) -> void:
	match type:
		"migalhas": migalhas += amount
		"nectar":   nectar   += amount
		"quitina":  quitina  += amount
	resources_changed.emit()
	print("[Recursos] %s +%d (total: %d)" % [type, amount, get_resource(type)])


func spend_resource(type: String, amount: int) -> bool:
	if get_resource(type) < amount:
		print("[Recursos] %s insuficiente (tem %d, precisa %d)" % [type, get_resource(type), amount])
		return false
	match type:
		"migalhas": migalhas -= amount
		"nectar":   nectar   -= amount
		"quitina":  quitina  -= amount
	resources_changed.emit()
	return true


func get_resource(type: String) -> int:
	match type:
		"migalhas": return migalhas
		"nectar":   return nectar
		"quitina":  return quitina
	return 0
