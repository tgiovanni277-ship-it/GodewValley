extends Node2D

@onready var sprite : Sprite2D        = $Sprite2D
@onready var timer  : Timer           = $Timer
@onready var anim   : AnimationPlayer = $AnimationPlayer

enum PlantState { SEED, GROWING, READY, DEAD }
var state      : int = PlantState.SEED
var seed_type  : int = -1
var grow_ticks : int = 0
var death_ticks: int = 0

var max_grow_ticks : int = 5
var death_max      : int = 15
var reward_item    : int = -1
var h_frames       : int = 4

const MONEDAS_POR_COSECHA = 8

func setup(p_seed_type: int) -> void:
	seed_type = p_seed_type
	var data = Data.PLANT_DATA.get(seed_type, null)
	if data == null:
		push_error("Plant: seed_type %d no encontrado" % seed_type)
		return

	var tex = load(data["texture"])
	if tex == null:
		push_error("Plant: textura no encontrada: " + data["texture"])
		return

	sprite.texture = tex
	h_frames       = data.get("h_frames", 4)
	sprite.hframes = h_frames
	sprite.vframes = 1
	sprite.frame   = 0

	var grow_speed : float = data.get("grow_speed", 1.0)
	max_grow_ticks = max(2, int(5.0 / grow_speed))
	death_max      = 15
	reward_item    = data.get("reward", -1)

	timer.wait_time = 2.0
	timer.one_shot  = false
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

	_update_sprite()
	print("[PLANT] Café plantado | crece en %d ticks (cada 2s) | tienes %d ticks para cosechar" \
		  % [max_grow_ticks, death_max])

func _on_timer_timeout() -> void:
	match state:
		PlantState.SEED, PlantState.GROWING:
			grow_ticks += 1
			if grow_ticks >= max_grow_ticks:
				state = PlantState.READY
				_start_pulse()
				print("[PLANT] ✅ ¡CAFÉ LISTO! Usa la Hoz (AXE) para cosechar (+%d monedas)" % MONEDAS_POR_COSECHA)
			else:
				state = PlantState.GROWING
				print("[PLANT] Creciendo... %d ticks restantes" % (max_grow_ticks - grow_ticks))
			_update_sprite()

		PlantState.READY:
			death_ticks += 1
			var restantes = death_max - death_ticks
			if restantes > 0:
				print("[PLANT] ⚠️ Listo para cosechar — muere en %d ticks" % restantes)
			if death_ticks >= death_max:
				_die()

func _update_sprite() -> void:
	match state:
		PlantState.SEED:
			sprite.frame = 0
		PlantState.GROWING:
			var progress = float(grow_ticks) / float(max_grow_ticks)
			sprite.frame = clamp(int(progress * (h_frames - 1)), 0, h_frames - 2)
		PlantState.READY:
			sprite.frame = h_frames - 1
		PlantState.DEAD:
			sprite.frame = 0
			sprite.modulate = Color(0.4, 0.4, 0.4, 0.7)

# ── ANIMACIONES ──────────────────────────────

func _start_pulse() -> void:
	if anim and anim.has_animation("pulse"):
		anim.play("pulse")

func _stop_pulse() -> void:
	if anim and anim.is_playing():
		anim.stop()
		sprite.scale = Vector2.ONE

func _play_coins_popup() -> void:
	if anim and anim.has_animation("coins_popup"):
		anim.play("coins_popup")

# ─────────────────────────────────────────────

func harvest() -> void:
	if state != PlantState.READY:
		print("[PLANT] Aún no está lista.")
		return

	_stop_pulse()
	_play_coins_popup()  # ← mostrar +8 🪙 flotando

	Inventory.add_item(Enum.Item.WOOD, MONEDAS_POR_COSECHA)
	print("[PLANT] 🪙 +%d monedas" % MONEDAS_POR_COSECHA)
	if reward_item >= 0:
		Inventory.add_item(reward_item, 1)
		print("[PLANT] ☕ +1 café en inventario")

	var level = get_tree().get_first_node_in_group("level")
	if level and level.has_method("on_plant_harvested"):
		level.on_plant_harvested(self)

	# Esperar a que termine la animación antes de eliminar el nodo
	await anim.animation_finished
	queue_free()

func _die() -> void:
	state = PlantState.DEAD
	timer.stop()
	_stop_pulse()
	_update_sprite()
	print("[PLANT] 💀 La planta murió sin cosechar")

	await get_tree().create_timer(3.0).timeout

	if is_queued_for_deletion():
		return

	var level = get_tree().get_first_node_in_group("level")
	if level and level.has_method("on_plant_harvested"):
		level.on_plant_harvested(self)

	queue_free()

func is_ready_to_harvest() -> bool:
	return state == PlantState.READY
