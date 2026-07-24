extends Node2D
# ─────────────────────────────────────────────
#  PLANT.GD
#  Adjunta este script al nodo raíz de plant.tscn
#
#  Estructura de plant.tscn:
#    Plant  (Node2D)  ← este script aquí
#    └── Sprite2D
#    └── Timer
# ─────────────────────────────────────────────

@onready var sprite : Sprite2D = $Sprite2D
@onready var timer  : Timer    = $Timer

# Estado de la planta
enum PlantState { SEED, GROWING, READY, DEAD }
var state      : int = PlantState.SEED
var seed_type  : int = -1
var grow_ticks : int = 0      # cuántas veces ha avanzado el timer
var death_ticks: int = 0      # cuántas veces lleva en estado READY sin cosechar

# Datos del cultivo (se llenan en setup)
var max_grow_ticks : int   = 5
var death_max      : int   = 3
var reward_item    : int   = -1
var h_frames       : int   = 4

func setup(p_seed_type: int) -> void:
	seed_type = p_seed_type
	var data = Data.PLANT_DATA.get(seed_type, null)
	if data == null:
		push_error("Plant: seed_type %d no encontrado en Data.PLANT_DATA" % seed_type)
		return

	# Cargar textura del sprite sheet
	var tex = load(data["texture"])
	if tex == null:
		push_error("Plant: no se encontró la textura: " + data["texture"])
		return

	sprite.texture   = tex
	h_frames         = data.get("h_frames", 4)
	sprite.hframes   = h_frames
	sprite.vframes   = 1
	sprite.frame     = 0

	# Calcular ticks de crecimiento desde grow_speed
	# grow_speed alto = crece rápido = pocos ticks necesarios
	var grow_speed : float = data.get("grow_speed", 1.0)
	max_grow_ticks = max(2, int(5.0 / grow_speed))
	death_max      = data.get("death_max", 3)
	reward_item    = data.get("reward", -1)

	# Iniciar timer (cada 5 segundos avanza un tick de crecimiento)
	timer.wait_time = 5.0
	timer.one_shot  = false
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

	_update_sprite()
	print("[PLANT] Plantado: ", Enum.Seed.keys()[seed_type],
		  " | ticks para crecer: ", max_grow_ticks)

func _on_timer_timeout() -> void:
	match state:
		PlantState.SEED, PlantState.GROWING:
			grow_ticks += 1
			if grow_ticks >= max_grow_ticks:
				state = PlantState.READY
				print("[PLANT] Lista para cosechar: ", Enum.Seed.keys()[seed_type])
			else:
				state = PlantState.GROWING
			_update_sprite()

		PlantState.READY:
			# Si lleva mucho tiempo sin cosechar, muere
			death_ticks += 1
			if death_ticks >= death_max:
				_die()

func _update_sprite() -> void:
	match state:
		PlantState.SEED:
			sprite.frame = 0
		PlantState.GROWING:
			# Interpolar entre frame 0 y h_frames-2 según progreso
			var progress = float(grow_ticks) / float(max_grow_ticks)
			sprite.frame = clamp(int(progress * (h_frames - 1)), 0, h_frames - 2)
		PlantState.READY:
			sprite.frame = h_frames - 1   # último frame = maduro
		PlantState.DEAD:
			sprite.frame = 0
			sprite.modulate = Color(0.4, 0.4, 0.4, 0.7)   # gris apagado

func harvest() -> void:
	if state != PlantState.READY:
		print("[PLANT] Aún no está lista para cosechar.")
		return

	# Dar item al inventario
	if reward_item >= 0:
		var inv = get_tree().get_first_node_in_group("inventory")
		if inv:
			inv.add_item(reward_item, 1)
			print("[PLANT] Cosechado: ", Enum.Item.keys()[reward_item])

	# Notificar al level para limpiar tile_data
	var level = get_tree().get_first_node_in_group("level")
	if level and level.has_method("on_plant_harvested"):
		level.on_plant_harvested(self)

	queue_free()

func _die() -> void:
	state = PlantState.DEAD
	timer.stop()
	_update_sprite()
	print("[PLANT] La planta murió: ", Enum.Seed.keys()[seed_type])

	# Esperar 3 segundos y eliminarse
	await get_tree().create_timer(3.0).timeout

	var level = get_tree().get_first_node_in_group("level")
	if level and level.has_method("on_plant_harvested"):
		level.on_plant_harvested(self)

	queue_free()

func is_ready_to_harvest() -> bool:
	return state == PlantState.READY
