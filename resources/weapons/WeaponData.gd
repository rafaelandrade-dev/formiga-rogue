extends Resource
class_name WeaponData

@export var weapon_name: String = ""
@export var damage_light: float = 5.0
@export var damage_heavy: float = 10.0
@export var attack_speed: float = 1.0    # multiplicador (1.0 = normal)
@export var knockback_force: float = 1.0
@export var reach: float = 16.0          # alcance da hitbox em pixels
@export var special_effect: String = "none"  # "none", "poison", "slow", "knockback_up"
@export var pickup_color: Color = Color.WHITE
