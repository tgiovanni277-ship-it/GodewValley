extends CharacterBody2D
# ─────────────────────────────────────────────
#  ANIMAL.GD — Deambula SOLO dentro del corral
#  Versión corregida: confinamiento estricto
# ─────────────────────────────────────────────

@export var corral_min  : Vector2 = Vector2(0, 0)
@export var corral_max  : Vector2 = Vector2(160, 160)
@export var speed       : float   = 20.0
@export var texture_path: String  = "res://graphics/characters/cat.png"

@onready var sprite : Sprite2D = $Sprite2D

var _dir          : Vector2 = Vector2.ZERO
var _move_timer   : float   = 0.0
var _pause_timer  : float   = 0.0
var _is_paused    : bool    = true

func _ready() -> void:
	var tex = load(texture_path)
	if tex:
		sprite.texture = tex
	_pause_timer = randf_range(0.5, 2.0)
	_is_paused   = true

func _physics_process(delta: float) -> void:
	# ── Guardia: si el gato está fuera del corral, regresarlo al centro ──
	var pos = global_position
	if pos.x < corral_min.x or pos.x > corral_max.x or \
	   pos.y < corral_min.y or pos.y > corral_max.y:
		global_position = global_position.clamp(corral_min, corral_max)
		_elegir_direccion_al_centro()
		return

	if _is_paused:
		_pause_timer -= delta
		if _pause_timer <= 0.0:
			_elegir_direccion()
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Frenar antes de llegar al borde (margen de 8 px)
	var margen := 8.0
	var next_pos = global_position + _dir * speed * delta
	if next_pos.x < corral_min.x + margen or next_pos.x > corral_max.x - margen or \
	   next_pos.y < corral_min.y + margen or next_pos.y > corral_max.y - margen:
		# Rebotar hacia el centro
		_elegir_direccion_al_centro()

	_move_timer -= delta
	if _move_timer <= 0.0:
		_is_paused   = true
		_pause_timer = randf_range(1.0, 3.0)
		velocity     = Vector2.ZERO
		move_and_slide()
		return

	velocity = _dir * speed
	move_and_slide()

	# Voltear sprite según dirección horizontal
	if _dir.x != 0:
		sprite.flip_h = _dir.x < 0

func _elegir_direccion() -> void:
	var angulo = randf_range(0, TAU)
	_dir        = Vector2(cos(angulo), sin(angulo)).normalized()
	_move_timer = randf_range(1.0, 3.0)
	_is_paused  = false

func _elegir_direccion_al_centro() -> void:
	var centro = (corral_min + corral_max) / 2.0
	_dir        = (centro - global_position).normalized()
	_move_timer = randf_range(0.8, 1.5)
	_is_paused  = false
