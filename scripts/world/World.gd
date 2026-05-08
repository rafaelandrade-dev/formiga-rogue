extends Node2D

const TILE_SIZE  := 16
const SRC_SOLID  := 0
const SRC_ONEWAY := 1
const SRC_DECO   := 2
const COORD_ZERO := Vector2i(0, 0)

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")

@onready var tilemap      = $TileMap
@onready var player_spawn = $PlayerSpawn

var player: Node2D = null
var cam_limit_left   := -16
var cam_limit_right  := 400
var cam_limit_top    := -200
var cam_limit_bottom := 220


func _ready() -> void:
	_build_tileset()
	_place_tiles()
	_spawn_player()
	_spawn_enemies()


func _build_tileset() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	ts.add_physics_layer(0)
	ts.set_physics_layer_collision_layer(0, 4)
	ts.set_physics_layer_collision_mask(0, 0)

	# Source must be added to TileSet BEFORE accessing TileData physics
	var src_solid := TileSetAtlasSource.new()
	src_solid.texture = _make_tex(Color(0.35, 0.25, 0.15))
	src_solid.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	src_solid.create_tile(COORD_ZERO)
	ts.add_source(src_solid, SRC_SOLID)
	var td_solid := src_solid.get_tile_data(COORD_ZERO, 0)
	td_solid.add_collision_polygon(0)
	td_solid.set_collision_polygon_points(0, 0, _box())

	var src_oneway := TileSetAtlasSource.new()
	src_oneway.texture = _make_tex(Color(0.55, 0.42, 0.22))
	src_oneway.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	src_oneway.create_tile(COORD_ZERO)
	ts.add_source(src_oneway, SRC_ONEWAY)
	var td_oneway := src_oneway.get_tile_data(COORD_ZERO, 0)
	td_oneway.add_collision_polygon(0)
	td_oneway.set_collision_polygon_points(0, 0, _box())
	td_oneway.set_collision_polygon_one_way(0, 0, true)

	var src_deco := TileSetAtlasSource.new()
	src_deco.texture = _make_tex(Color(0.12, 0.09, 0.07))
	src_deco.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	src_deco.create_tile(COORD_ZERO)
	ts.add_source(src_deco, SRC_DECO)

	tilemap.tile_set = ts


func _make_tex(color: Color) -> ImageTexture:
	var img := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGB8)
	img.fill(color)
	return ImageTexture.create_from_image(img)


func _box() -> PackedVector2Array:
	var h := TILE_SIZE / 2.0
	return PackedVector2Array([
		Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)
	])


func _place_tiles() -> void:
	# Base world: flat ground + 2 platforms for testing
	for x in range(-1, 22):
		tilemap.set_cell(0, Vector2i(x, 10), SRC_SOLID, COORD_ZERO)
		tilemap.set_cell(0, Vector2i(x, 11), SRC_SOLID, COORD_ZERO)
	for x in range(-1, 22):
		for y in range(-3, 10):
			tilemap.set_cell(0, Vector2i(x, y), SRC_DECO, COORD_ZERO)
	for x in range(3, 8):
		tilemap.set_cell(0, Vector2i(x, 7), SRC_ONEWAY, COORD_ZERO)
	for x in range(12, 17):
		tilemap.set_cell(0, Vector2i(x, 5), SRC_ONEWAY, COORD_ZERO)


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.global_position = player_spawn.global_position
	add_child(player)
	var cam := Camera2D.new()
	cam.limit_left   = cam_limit_left
	cam.limit_right  = cam_limit_right
	cam.limit_top    = cam_limit_top
	cam.limit_bottom = cam_limit_bottom
	player.add_child(cam)


func _spawn_enemies() -> void:
	for marker in get_tree().get_nodes_in_group("enemy_spawn"):
		var scene_path: String = marker.get_meta("scene", "")
		if scene_path.is_empty():
			continue
		var packed = load(scene_path)
		if packed == null:
			push_error("World: could not load enemy scene: " + scene_path)
			continue
		var inst = packed.instantiate()
		inst.global_position = marker.global_position
		add_child(inst)
