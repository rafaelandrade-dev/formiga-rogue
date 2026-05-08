extends CharacterBody2D

# ── Constants ─────────────────────────────────────────────────────────────────
const SPEED            := 120.0
const ACCELERATION     := 800.0
const FRICTION         := 600.0
const JUMP_VELOCITY    := -300.0
const DOUBLE_JUMP_VEL  := -260.0
const GRAVITY          := 900.0
const COYOTE_TIME      := 0.1
const JUMP_BUFFER_TIME := 0.1

const DASH_SPEED       := 320.0
const DASH_DURATION    := 0.15
const DASH_COOLDOWN    := 0.8

const ATK_L_DURATION   := 0.30
const ATK_L_HIT_START  := 0.07
const ATK_L_HIT_END    := 0.18
const ATK_L_CANCEL_AT  := 0.14

const ATK_H_DURATION   := 0.60
const ATK_H_HIT_START  := 0.18
const ATK_H_HIT_END    := 0.40

const PARRY_DURATION   := 0.40
const PARRY_DEFLECT    := 0.15

const HURT_DURATION    := 0.35
const IFRAMES_DURATION := 0.80
const HURT_FLASH_TIME  := 0.20  # duração do flash vermelho

const SPRITE_SCALE     := 0.25  # 64px frame → ~16px na tela
const SPRITE_OFFSET_Y  := -1.0  # alinha os pés do sprite com o fundo da CollisionShape

const GAME_OVER_SCENE  := "res://scenes/ui/GameOverScreen.tscn"

# ── State machine ─────────────────────────────────────────────────────────────
enum State { IDLE, RUN, JUMP, ATTACK_LIGHT, ATTACK_HEAVY, PARRY, DASH, HURT, DEAD }

var state      : State = State.IDLE
var state_time : float = 0.0

# ── Combat ────────────────────────────────────────────────────────────────────
var combo_count  := 0
var combo_buffer := false
var is_invincible := false
var iframes_timer := 0.0

# ── Movement ──────────────────────────────────────────────────────────────────
var double_jump_used    := false
var facing_right        := true
var dash_cooldown_timer := 0.0
var dash_dir            := 1.0
var coyote_timer        := 0.0
var jump_buffer_timer   := 0.0
var was_on_floor        := false

@onready var anim_sprite     : AnimatedSprite2D  = $AnimatedSprite2D
@onready var hitbox          : Area2D            = $Hitbox
@onready var hb_shape        : CollisionShape2D  = $Hitbox/CollisionShape2D
@onready var weapon_system   = $WeaponSystem
@onready var health_component = $HealthComponent


func _ready() -> void:
	_build_sprite_frames()
	_set_hitbox(false)
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_health_died)


func _physics_process(delta: float) -> void:
	state_time += delta
	_tick_iframes(delta)
	_tick_dash_cooldown(delta)
	_run_state(delta)
	_update_animation()


# ── Sprite setup ──────────────────────────────────────────────────────────────
func _build_sprite_frames() -> void:
	var frames := SpriteFrames.new()
	var rat := "res://assets/sprites/rat.png"
	var fw   := 64; var fh := 64
	# rat.png: grid 64x64, 13 colunas x 54 linhas (LPC format)
	# Grupos de 4 linhas por animação: linha 0=cima 1=esq 2=baixo 3=dir
	# Ajuste os índices de linha abaixo conforme o visual real:
	frames.remove_animation("default")
	_add_strip_frames(frames, "idle",         rat, 2,  fw, fh, 0, 23*fh, true,  3.0)  # linha 23 – idle/respiração (dir)
	_add_strip_frames(frames, "run",          rat, 9,  fw, fh, 0, 11*fh, true,  10.0) # linha 11 – walk (dir)
	_add_strip_frames(frames, "jump",         rat, 8,  fw, fh, 0,  7*fh, false, 8.0)  # linha 7  – thrust (dir)
	_add_strip_frames(frames, "dash",         rat, 5,  fw, fh, 0, 29*fh, false, 14.0) # linha 29 – 5-frame anim (dir)
	_add_strip_frames(frames, "attack_light", rat, 6,  fw, fh, 0, 15*fh, false, 12.0) # linha 15 – slash (dir)
	_add_strip_frames(frames, "attack_heavy", rat, 8,  fw, fh, 0, 41*fh, false, 8.0)  # linha 41 – outro ataque (dir)
	_add_strip_frames(frames, "parry",        rat, 7,  fw, fh, 0,  3*fh, false, 10.0) # linha 3  – spellcast (dir)
	_add_strip_frames(frames, "hurt",         rat, 2,  fw, fh, 0, 45*fh, false, 10.0) # linha 45 – hurt (dir)
	_add_strip_frames(frames, "dead",         rat, 3,  fw, fh, 0, 37*fh, false, 6.0)  # linha 37 – morte (dir)
	anim_sprite.sprite_frames = frames
	anim_sprite.scale      = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	anim_sprite.position.y = SPRITE_OFFSET_Y
	anim_sprite.play("idle")


func _add_strip_frames(frames: SpriteFrames, anim: String, path: String, count: int, fw: int, fh: int, ox: int, oy: int, loop: bool, fps: float) -> void:
	frames.add_animation(anim)
	frames.set_animation_loop(anim, loop)
	frames.set_animation_speed(anim, fps)
	var tex: Texture2D = load(path)
	for i in count:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(ox + i * fw, oy, fw, fh)
		frames.add_frame(anim, at)


func _update_animation() -> void:
	var anim: String
	match state:
		State.RUN:          anim = "run"
		State.JUMP:         anim = "jump"
		State.DASH:         anim = "dash"
		State.ATTACK_LIGHT: anim = "attack_light"
		State.ATTACK_HEAVY: anim = "attack_heavy"
		State.PARRY:        anim = "parry"
		State.HURT:         anim = "hurt"
		State.DEAD:         anim = "dead"
		_:                  anim = "idle"
	if anim_sprite.animation != anim:
		anim_sprite.play(anim)
	anim_sprite.flip_h = not facing_right


# ── API pública ───────────────────────────────────────────────────────────────
func get_weapon_system():
	return weapon_system


# ── HealthComponent callbacks ─────────────────────────────────────────────────
func _on_health_changed(old_val: float, new_val: float) -> void:
	if new_val < old_val and new_val > 0.0:
		_enter(State.HURT)
	print("[Player] HP: %.0f / %.0f" % [new_val, health_component.max_health])


func _on_health_died() -> void:
	_enter(State.DEAD)


# ── State dispatcher ──────────────────────────────────────────────────────────
func _run_state(delta: float) -> void:
	match state:
		State.IDLE, State.RUN, State.JUMP:
			_apply_gravity(delta)
			_move(delta)
			_handle_jump(delta)
			if not weapon_system.prompt_active:
				if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0:
					_enter(State.DASH)
					return
				elif Input.is_action_just_pressed("attack_light"):
					combo_count  = 0
					combo_buffer = false
					_enter(State.ATTACK_LIGHT)
					return
				elif Input.is_action_just_pressed("attack_heavy"):
					combo_count = 0
					_enter(State.ATTACK_HEAVY)
					return
				elif Input.is_action_just_pressed("parry"):
					_enter(State.PARRY)
					return
			move_and_slide()
			was_on_floor = is_on_floor()
			_update_ground_state()

		State.DASH:
			velocity.x = dash_dir * DASH_SPEED
			velocity.y = 0.0
			if state_time >= DASH_DURATION:
				velocity.x = 0.0
				_enter(State.IDLE)
			move_and_slide()
			was_on_floor = is_on_floor()

		State.ATTACK_LIGHT:
			var spd: float = weapon_system.get_attack_speed()
			var t: float   = state_time * spd
			_apply_gravity(delta)
			velocity.x = move_toward(velocity.x, 0.0, FRICTION * 2.0 * delta)
			_set_hitbox(t >= ATK_L_HIT_START and t < ATK_L_HIT_END)
			if t >= ATK_L_CANCEL_AT and Input.is_action_just_pressed("attack_light"):
				combo_buffer = true
			if t >= ATK_L_DURATION:
				_set_hitbox(false)
				if combo_buffer and combo_count < 3:
					combo_buffer = false
					_enter(State.ATTACK_LIGHT)
				else:
					combo_count  = 0
					combo_buffer = false
					_enter(State.IDLE)
			move_and_slide()
			was_on_floor = is_on_floor()

		State.ATTACK_HEAVY:
			var spd: float = weapon_system.get_attack_speed()
			var t: float   = state_time * spd
			_apply_gravity(delta)
			velocity.x = move_toward(velocity.x, 0.0, FRICTION * 3.0 * delta)
			_set_hitbox(t >= ATK_H_HIT_START and t < ATK_H_HIT_END)
			if t >= ATK_H_DURATION:
				_set_hitbox(false)
				combo_count = 0
				_enter(State.IDLE)
			move_and_slide()
			was_on_floor = is_on_floor()

		State.PARRY:
			velocity.x = move_toward(velocity.x, 0.0, FRICTION * 3.0 * delta)
			_apply_gravity(delta)
			if state_time >= PARRY_DURATION:
				_enter(State.IDLE)
			move_and_slide()
			was_on_floor = is_on_floor()

		State.HURT:
			_apply_gravity(delta)
			velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
			if state_time >= HURT_DURATION:
				_enter(State.IDLE)
			move_and_slide()
			was_on_floor = is_on_floor()

		State.DEAD:
			_apply_gravity(delta)
			velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
			move_and_slide()


# ── State entry ───────────────────────────────────────────────────────────────
func _enter(new_state: State) -> void:
	if state in [State.ATTACK_LIGHT, State.ATTACK_HEAVY]:
		_set_hitbox(false)
	if state == State.DASH:
		is_invincible          = false
		anim_sprite.modulate   = Color(1, 1, 1, 1)

	state      = new_state
	state_time = 0.0

	match new_state:
		State.ATTACK_LIGHT:
			combo_count += 1
			_position_hitbox()
		State.ATTACK_HEAVY:
			_position_hitbox()
		State.DASH:
			is_invincible = true
			dash_dir      = 1.0 if facing_right else -1.0
			velocity.y    = 0.0
			dash_cooldown_timer = DASH_COOLDOWN
		State.HURT:
			is_invincible = true
			iframes_timer = IFRAMES_DURATION
		State.DEAD:
			weapon_system.clear_on_death()
			get_tree().create_timer(1.5).timeout.connect(_show_game_over)


# ── Movement helpers ──────────────────────────────────────────────────────────
func _move(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		velocity.x   = move_toward(velocity.x, dir * SPEED, ACCELERATION * delta)
		facing_right = dir > 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta


func _handle_jump(delta: float) -> void:
	var on_floor := is_on_floor()
	if was_on_floor and not on_floor:
		coyote_timer = COYOTE_TIME
	if on_floor:
		coyote_timer     = 0.0
		double_jump_used = false
	elif coyote_timer > 0.0:
		coyote_timer -= delta

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta

	var can_ground := on_floor or coyote_timer > 0.0
	if jump_buffer_timer > 0.0 and can_ground:
		velocity.y        = JUMP_VELOCITY
		jump_buffer_timer = 0.0
		coyote_timer      = 0.0
	elif Input.is_action_just_pressed("jump") and not can_ground and not double_jump_used:
		velocity.y        = DOUBLE_JUMP_VEL
		double_jump_used  = true
		jump_buffer_timer = 0.0

	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.4


func _tick_dash_cooldown(delta: float) -> void:
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta


func _tick_iframes(delta: float) -> void:
	if iframes_timer <= 0.0:
		return
	iframes_timer -= delta
	var elapsed: float = IFRAMES_DURATION - iframes_timer
	if elapsed < HURT_FLASH_TIME:
		anim_sprite.modulate = Color(1.5, 0.3, 0.3, 1.0)
	else:
		anim_sprite.modulate = Color(1.0, 1.0, 1.0, 0.0 if fmod(iframes_timer, 0.15) < 0.075 else 1.0)
	if iframes_timer <= 0.0 and state != State.DASH:
		is_invincible        = false
		anim_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _update_ground_state() -> void:
	if not is_on_floor():
		if state != State.JUMP:
			state = State.JUMP
	else:
		if state == State.JUMP:
			state = State.IDLE
		elif abs(velocity.x) > 4.0:
			state = State.RUN
		else:
			state = State.IDLE


func _set_hitbox(active: bool) -> void:
	hb_shape.disabled = not active


func _position_hitbox() -> void:
	var reach: float = weapon_system.get_reach()
	var shape := hb_shape.shape as RectangleShape2D
	if shape:
		shape.size.x = reach
	hitbox.position.x = (4.0 + reach * 0.5) if facing_right else -(4.0 + reach * 0.5)


func _show_game_over() -> void:
	var screen = load(GAME_OVER_SCENE).instantiate()
	get_tree().root.add_child(screen)


# ── Damage API ────────────────────────────────────────────────────────────────
func receive_attack(damage: int, knockback: Vector2, attacker: Node) -> void:
	if state == State.DEAD:
		return
	if state == State.PARRY and state_time <= PARRY_DEFLECT:
		if attacker.has_method("receive_stagger"):
			attacker.receive_stagger()
		return
	if is_invincible:
		return
	velocity = knockback
	health_component.take_damage(float(damage), attacker.global_position)


# ── Hitbox hit detection ──────────────────────────────────────────────────────
func _on_hitbox_body_entered(body: Node2D) -> void:
	if body == self or not body.has_method("receive_hit"):
		return

	var weapon         = weapon_system.get_weapon()
	var is_heavy: bool = state == State.ATTACK_HEAVY
	var dmg: float     = (weapon.damage_heavy if is_heavy else weapon.damage_light) \
	                     if weapon else (10.0 if is_heavy else 5.0)
	var kbf: float     = weapon.knockback_force if weapon else 1.0
	var dir: float     = 1.0 if facing_right else -1.0
	var kb: Vector2    = Vector2(dir * (200.0 if is_heavy else 80.0) * kbf,
	                             -100.0 if is_heavy else -40.0)

	if weapon and weapon.special_effect == "knockback_up" and is_heavy:
		kb.y = -220.0

	print("[Hit] %s → %s  dmg:%.0f  efeito:%s" % [
		name, body.name, dmg,
		weapon.special_effect if weapon else "none"
	])
	body.receive_hit(int(dmg), kb)

	if weapon and weapon.special_effect == "poison" and body.has_method("apply_poison"):
		body.apply_poison(2.0, 3.0)
