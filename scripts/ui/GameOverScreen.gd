extends CanvasLayer


func _ready() -> void:
	layer = 100
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.80)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.position = Vector2(-70.0, -20.0)
	vbox.size     = Vector2(140.0, 40.0)
	bg.add_child(vbox)

	var title := Label.new()
	title.text                 = "Você morreu"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 12)
	vbox.add_child(title)

	var btn := Button.new()
	btn.text = "Reiniciar"
	btn.add_theme_font_size_override("font_size", 8)
	btn.pressed.connect(_on_restart)
	vbox.add_child(btn)


func _on_restart() -> void:
	get_tree().reload_current_scene()
