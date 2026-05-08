extends "res://scripts/world/World.gd"

func _ready() -> void:
	cam_limit_left   = -16
	cam_limit_right  = 1360
	cam_limit_top    = -200
	cam_limit_bottom = 220
	_register_enemy_spawns()
	super._ready()


func _register_enemy_spawns() -> void:
	var spawns := get_node_or_null("EnemySpawns")
	if spawns == null:
		return
	for child in spawns.get_children():
		child.add_to_group("enemy_spawn")


func _place_tiles() -> void:
	# ── Decorative background (full level) ──────────────────────────────────
	for x in range(-1, 85):
		for y in range(-3, 10):
			tilemap.set_cell(0, Vector2i(x, y), SRC_DECO, COORD_ZERO)

	# ── Ground (full level) ──────────────────────────────────────────────────
	for x in range(-1, 85):
		tilemap.set_cell(0, Vector2i(x, 10), SRC_SOLID, COORD_ZERO)
		tilemap.set_cell(0, Vector2i(x, 11), SRC_SOLID, COORD_ZERO)

	# ── Room 1: Tutorial de combate (x 0-29) ────────────────────────────────
	for x in range(4, 10):   # Platform A — y=112 top
		tilemap.set_cell(0, Vector2i(x, 7), SRC_ONEWAY, COORD_ZERO)
	for x in range(14, 20):  # Platform B — y=80 top
		tilemap.set_cell(0, Vector2i(x, 5), SRC_ONEWAY, COORD_ZERO)

	# ── Room 2: Plataformas verticais (x 30-61) ─────────────────────────────
	for x in range(32, 38):  # Platform C — y=112 top (Aranha 1)
		tilemap.set_cell(0, Vector2i(x, 7), SRC_ONEWAY, COORD_ZERO)
	for x in range(41, 48):  # Platform D — y=64 top (Aranha 2, mais alta)
		tilemap.set_cell(0, Vector2i(x, 4), SRC_ONEWAY, COORD_ZERO)
	for x in range(50, 57):  # Platform E — y=112 top (rota alternativa)
		tilemap.set_cell(0, Vector2i(x, 7), SRC_ONEWAY, COORD_ZERO)

	# ── Room 3: Antecâmara do boss (x 62-84) ────────────────────────────────
	# Portão bloqueado — parede sólida em x=82-83
	for y in range(-3, 11):
		tilemap.set_cell(0, Vector2i(82, y), SRC_SOLID, COORD_ZERO)
		tilemap.set_cell(0, Vector2i(83, y), SRC_SOLID, COORD_ZERO)
