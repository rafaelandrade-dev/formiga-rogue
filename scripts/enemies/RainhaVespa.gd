extends "res://scripts/enemies/BaseEnemy.gd"

# ── Estado do boss (int além de State.DEAD = 6) ───────────────────────────────
const BS_HOVER          := 10
const BS_DIVE_TELEGRAPH := 11
const BS_DIVE           := 12
const BS_SWARM          := 13
const BS_BURST          := 14
const BS_TRANSITION     := 15
const BS_DOUBLE_PAUSE   := 16

# ── Timings ───────────────────────────────────────────────────────────────────
const HOVER_DURATION      := 1.5
const TELEGRAPH_DURATION  := 0.8
const DIVE_SPEED_P1       := 350.0
const DIVE_SPEED_P2       := 500.0
const SWARM_DURATION      := 0.5
const BURST_CHARGE        := 0.5
const TRANSITION_DURATION := 1.5
const HOVER_Y_OFFSET      := -80.0   # acima do chão da arena
const RISE_EXTRA          := -50.0   # subida extra antes do mergulho

# ── Fases ─────────────────────────────────────────────────────────────────────
var phase:        int  = 1
var transitioned: bool = false
var dives_done:   int  = 0

var dive_target: Vector2 = Vector2.ZERO
var dive_hit:    bool    = false

var arena_floor_y: float = 160.0   # tile y=10 × 16px

# ── Visual ────────────────────────────────────────────────────────────────────
var telegraph: Line2D = null

# ── Sinais para o HUD ─────────────────────────────────────────────────────────
signal boss_hp_changed(current: float, maximum: float)
signal boss_died

# ── Preloads ──────────────────────────────────────────────────────────────────
const DRONE_SCENE = preload("res://scenes/enemies/VespaDrone.tscn")
const PROJ_SCENE  = preload("res://scenes/enemies/BossProjectile.tscn")


func _ready() -> void:
	move_speed       = 80.0
	detection_radius = 600.0
	attack_range     = 9999.0
	attack_cooldown  = 0.0
	super._ready()
	fsm.change(State.IDLE)

	var img := Image.create(24, 18, false, Image.FORMAT_RGB8)
	img.fill(Color(0.55, 0.08, 0.65))
	sprite.texture = ImageTexture.create_from_image(img)
	sprite.scale   = Vector2(1.5, 1.5)

	telegraph                = Line2D.new()
	telegraph.width          = 1.5
	telegraph.default_color  = Color(1, 0.2, 0.2, 0.7)
	telegraph.visible        = false
	add_child(telegraph)


# ── Ativação pelo trigger da arena ────────────────────────────────────────────
func activate(player_ref: Node2D) -> void:
	player         = player_ref
	can_see_player = true
	fsm.change(BS_HOVER)


# ── Física sem gravidade ──────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	fsm.time    += delta
	attack_timer = max(0.0, attack_timer - delta)
	_tick_poison(delta)
	_run_state(delta)
	move_and_slide()
	_update_facing()


# ── Máquina de estado ─────────────────────────────────────────────────────────
func _run_state(delta: float) -> void:
	match fsm.current:
		State.IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)

		State.HURT:
			velocity        = velocity.move_toward(Vector2.ZERO, 600.0 * delta)
			sprite.modulate = Color(1.5, 0.4, 0.4) if fmod(fsm.time, 0.1) < 0.05 else Color(1, 1, 1)
			if fsm.time >= 0.25:
				sprite.modulate = _phase_color()
				if not transitioned and _hp_ratio() <= 0.5:
					transitioned = true
					fsm.change(BS_TRANSITION)
				else:
					fsm.change(BS_HOVER)

		State.STAGGERED:
			velocity        = velocity.move_toward(Vector2.ZERO, 600.0 * delta)
			sprite.modulate = Color(1, 1, 1) if fmod(fsm.time, 0.2) < 0.1 else Color(1, 0.3, 0.3)
			if fsm.time >= 0.8:
				sprite.modulate = _phase_color()
				fsm.change(BS_HOVER)

		State.DEAD:
			velocity = velocity.move_toward(Vector2.ZERO, 200.0 * delta)

		BS_HOVER:
			_tick_hover(delta)
		BS_DIVE_TELEGRAPH:
			_tick_telegraph(delta)
		BS_DIVE:
			_tick_dive(delta)
		BS_DOUBLE_PAUSE:
			velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
			if fsm.time >= 0.4:
				_begin_dive()
		BS_SWARM:
			_tick_swarm(delta)
		BS_BURST:
			_tick_burst(delta)
		BS_TRANSITION:
			_tick_transition(delta)


# ── Hover ─────────────────────────────────────────────────────────────────────
func _tick_hover(delta: float) -> void:
	if not player or not is_instance_valid(player):
		return
	var spd    := 80.0 if phase == 1 else 120.0
	var target := Vector2(player.global_position.x, arena_floor_y + HOVER_Y_OFFSET)
	velocity    = velocity.move_toward((target - global_position).normalized() * spd, 500.0 * delta)
	if fsm.time >= HOVER_DURATION:
		_pick_attack()


func _pick_attack() -> void:
	dives_done = 0
	if phase == 1:
		if randf() < 0.5:
			_begin_telegraph()
		else:
			fsm.change(BS_SWARM)
	else:
		var r := randf()
		if r < 0.4:
			_begin_telegraph()
		elif r < 0.7:
			fsm.change(BS_SWARM)
		else:
			fsm.change(BS_BURST)


# ── Telegraf do mergulho ──────────────────────────────────────────────────────
func _begin_telegraph() -> void:
	if not player or not is_instance_valid(player):
		fsm.change(BS_HOVER)
		return
	telegraph.visible = true
	telegraph.clear_points()
	telegraph.add_point(Vector2.ZERO)
	telegraph.add_point(Vector2(0.0, 60.0))
	fsm.change(BS_DIVE_TELEGRAPH)


func _tick_telegraph(delta: float) -> void:
	# Sobe para a posição de disparo
	var rise_y := arena_floor_y + HOVER_Y_OFFSET + RISE_EXTRA
	var diff_y := rise_y - global_position.y
	velocity    = velocity.move_toward(Vector2(0.0, signf(diff_y) * 100.0), 400.0 * delta)
	if absf(diff_y) < 3.0:
		velocity.y = 0.0

	# Atualiza a linha telegráfica
	if player and is_instance_valid(player) and telegraph.get_point_count() >= 2:
		var target := Vector2(player.global_position.x, arena_floor_y - 16.0)
		telegraph.set_point_position(1, target - global_position)
		var blink               := fmod(fsm.time, 0.15) < 0.075
		telegraph.default_color  = Color(1, 0.2, 0.2, 0.8 if blink else 0.3)

	if fsm.time >= TELEGRAPH_DURATION:
		telegraph.visible = false
		_begin_dive()


func _begin_dive() -> void:
	if not player or not is_instance_valid(player):
		fsm.change(BS_HOVER)
		return
	dive_target    = Vector2(player.global_position.x, arena_floor_y - 16.0)
	dive_hit       = false
	telegraph.visible = false
	fsm.change(BS_DIVE)


# ── Mergulho ──────────────────────────────────────────────────────────────────
func _tick_dive(_delta: float) -> void:
	var spd := DIVE_SPEED_P1 if phase == 1 else DIVE_SPEED_P2
	var dir := (dive_target - global_position).normalized()
	velocity  = dir * spd

	if not dive_hit and player and is_instance_valid(player):
		if global_position.distance_to(player.global_position) < 22.0:
			_deal_damage_to_player(15, Vector2(dir.x * 200.0, -130.0))
			dive_hit = true

	var to_target := dive_target - global_position
	if to_target.dot(dir) <= 0.0 or global_position.distance_to(dive_target) < 12.0:
		dives_done += 1
		if phase == 2 and dives_done < 2:
			fsm.change(BS_DOUBLE_PAUSE)
		else:
			dives_done   = 0
			attack_timer = 0.5
			fsm.change(BS_HOVER)


# ── Enxame ────────────────────────────────────────────────────────────────────
func _tick_swarm(delta: float) -> void:
	velocity        = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
	var blink        := fmod(fsm.time, 0.2) < 0.1
	sprite.modulate  = Color(1.4, 1.0, 0.2) if blink else _phase_color()
	if fsm.time >= SWARM_DURATION:
		sprite.modulate = _phase_color()
		_spawn_drones(2 if phase == 1 else 3)
		attack_timer = 1.0
		fsm.change(BS_HOVER)


func _spawn_drones(count: int) -> void:
	for i in count:
		var drone             = DRONE_SCENE.instantiate()
		var t: float           = float(i) / float(maxi(count - 1, 1))
		var angle: float       = -PI * 0.35 + PI * 0.7 * t
		drone.global_position  = global_position + Vector2(cos(angle) * 28.0, sin(angle) * 18.0)
		drone.player           = player
		get_parent().add_child(drone)


# ── Rajada (Fase 2) ───────────────────────────────────────────────────────────
func _tick_burst(delta: float) -> void:
	velocity        = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
	sprite.modulate  = Color(1.5, 0.5, 1.0) if fmod(fsm.time, 0.1) < 0.05 else Color(1, 0.2, 0.8)
	if fsm.time >= BURST_CHARGE:
		sprite.modulate = Color(1, 0.2, 0.8)
		_fire_burst()
		attack_timer = 0.8
		fsm.change(BS_HOVER)


func _fire_burst() -> void:
	if not player or not is_instance_valid(player):
		return
	var base_dir := (player.global_position - global_position).normalized()
	for a: float in [-0.35, 0.0, 0.35]:
		var proj             = PROJ_SCENE.instantiate()
		proj.direction       = base_dir.rotated(a)
		proj.global_position = global_position
		get_parent().add_child(proj)


# ── Transição de fase ─────────────────────────────────────────────────────────
func _tick_transition(delta: float) -> void:
	velocity        = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
	var pulse        := sin(fsm.time / TRANSITION_DURATION * PI * 6.0) * 0.5 + 0.5
	sprite.modulate  = Color(1.0 + pulse * 0.6, 0.1, 0.6 + pulse * 0.4)
	if fsm.time >= TRANSITION_DURATION:
		phase        = 2
		move_speed   = 120.0
		sprite.modulate = Color(1, 0.2, 0.8)
		fsm.change(BS_HOVER)


# ── Helpers ───────────────────────────────────────────────────────────────────
func _hp_ratio() -> float:
	if health_component.max_health <= 0.0:
		return 0.0
	return health_component.current_health / health_component.max_health


func _phase_color() -> Color:
	return Color(1, 1, 1) if phase == 1 else Color(1, 0.2, 0.8)


# ── Overrides de BaseEnemy ────────────────────────────────────────────────────
func receive_hit(damage: int, _knockback: Vector2) -> void:
	if fsm.current == State.DEAD:
		return
	health_component.take_damage(float(damage), global_position)


func receive_stagger() -> void:
	if fsm.current == State.DEAD:
		return
	velocity        = Vector2.ZERO
	sprite.modulate = Color(1, 1, 1)
	fsm.change(State.STAGGERED)


func _on_detection_entered(body: Node2D) -> void:
	if body.has_method("get_weapon_system"):
		player         = body
		can_see_player = true


func _on_detection_exited(body: Node2D) -> void:
	if body == player:
		can_see_player = false


func _on_health_changed(_old: float, new_val: float) -> void:
	boss_hp_changed.emit(new_val, health_component.max_health)
	if new_val > 0.0 and fsm.current != State.DEAD:
		if fsm.current != BS_TRANSITION:
			fsm.change(State.HURT)
	print("[RainhaVespa] HP %.0f/%.0f  Fase %d" % [new_val, health_component.max_health, phase])


func _on_died() -> void:
	fsm.change(State.DEAD)
	telegraph.visible = false
	sprite.modulate   = Color(0.4, 0.1, 0.4)
	_drop_boss_resources()
	boss_died.emit()
	get_tree().create_timer(1.2).timeout.connect(queue_free)


func _drop_boss_resources() -> void:
	var drop_y := arena_floor_y - 10.0
	var drop_x := global_position.x

	var nectar             = RESOURCE_PICKUP.instantiate()
	nectar.resource_type   = "nectar"
	nectar.amount          = 1
	nectar.global_position = Vector2(drop_x - 20.0, drop_y)
	get_parent().add_child(nectar)

	for i in 2:
		var q             = RESOURCE_PICKUP.instantiate()
		q.resource_type   = "quitina"
		q.amount          = 1
		q.global_position = Vector2(drop_x + randf_range(-16.0, 16.0), drop_y)
		get_parent().add_child(q)

	print("[RainhaVespa] Drop: 1 nectar + 2 quitina")
