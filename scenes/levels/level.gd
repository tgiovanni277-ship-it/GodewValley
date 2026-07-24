extends Node2D
# ─────────────────────────────────────────────
#  LEVEL.GD — Parcela inicial más grande
#  CAMBIOS:
#  • Parcela inicial 8x4 (32 plantas)
#  • Mitad izquierda (4x4): ya LISTAS para cosechar
#  • Mitad derecha (4x4): en distintas etapas de crecimiento
#  • HOE ara + riega + siembra en un solo paso
#  • AXE busca por nodos (no tile_data) — siempre funciona
# ─────────────────────────────────────────────

@onready var soil_layer   : TileMapLayer    = $Layers/Soil
@onready var ground_layer : TileMapLayer    = $Layers/Ground
@onready var objects_node : Node2D          = $Objects
@onready var player       : CharacterBody2D = $Objects/Player

const SOIL_SOURCE_ID    = 1
const SOIL_ATLAS_COORD  = Vector2i(0, 0)
const WATER_ATLAS_COORD = Vector2i(1, 0)

const PlantScene = preload("res://plant.tscn")
const CatScene   = preload("res://scenes/levels/animal.tscn")

var tile_data : Dictionary = {}
var hud       : Node       = null

func _ready() -> void:
	add_to_group("level")
	if player:
		player.tool_used.connect(_on_tool_used)
		_update_player_limits()
	else:
		push_error("level.gd: no se encontró el Player bajo Objects/")
	await get_tree().process_frame
	hud = get_tree().get_first_node_in_group("hud_status")
	await get_tree().process_frame
	_sembrar_parcela_inicial()
	_spawear_gatos()

func _process(_delta: float) -> void:
	if not player or not hud:
		return
	var tile_pos = _world_to_tile(player.position)
	if tile_data.has(tile_pos):
		var td = tile_data[tile_pos]
		if td["plant"] != null:
			var p = td["plant"]
			if p.is_ready_to_harvest():
				hud.set_tile_estado("🟡 LISTO — presiona AXE para cosechar (+8 monedas)")
			else:
				hud.set_tile_estado("🟢 Creciendo... espera")
		elif td["watered"]:
			hud.set_tile_estado("💧 Regado — usa Semilla para plantar")
		else:
			hud.set_tile_estado("🟫 Arado — usa HOE para sembrar")
	else:
		var p_cerca = _planta_lista_cercana(48.0)
		if p_cerca:
			hud.set_tile_estado("🟡 LISTO — presiona AXE para cosechar (+8 monedas)")
		else:
			hud.set_tile_estado("")

func _update_player_limits() -> void:
	var rect = ground_layer.get_used_rect()
	if rect.size == Vector2i.ZERO:
		return
	var tile_size = ground_layer.tile_set.tile_size if ground_layer.tile_set else Vector2i(16, 16)
	var world_min = Vector2(rect.position) * Vector2(tile_size)
	var world_max = Vector2(rect.position + rect.size) * Vector2(tile_size)
	player.set_farm_bounds(world_min, world_max)

func _on_tool_used() -> void:
	if not player:
		return
	var tile_pos : Vector2i = _world_to_tile(player.position)
	match player.current_tool:
		Enum.Tool.HOE:   _use_hoe(tile_pos)
		Enum.Tool.WATER: _use_water(tile_pos)
		Enum.Tool.SEED:  _use_seed(tile_pos)
		Enum.Tool.AXE:   _use_axe()
		Enum.Tool.SWORD: _use_sword()
		Enum.Tool.FISH:  _use_fish()

# ── HOE: ara + riega + siembra en un solo paso ──
func _use_hoe(center: Vector2i) -> void:
	var nuevos : Array = []
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var t = center + Vector2i(dx, dy)
			if not tile_data.has(t):
				soil_layer.set_cell(t, SOIL_SOURCE_ID, SOIL_ATLAS_COORD)
				tile_data[t] = { "watered": false, "plant": null }
				nuevos.append(t)
	if nuevos.size() > 0:
		print("[HOE] Arados %d tiles" % nuevos.size())
	for t in nuevos:
		soil_layer.set_cell(t, SOIL_SOURCE_ID, WATER_ATLAS_COORD)
		tile_data[t]["watered"] = true
	var sembrados = 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var t = center + Vector2i(dx, dy)
			if tile_data.has(t) and tile_data[t]["watered"] \
			   and tile_data[t]["plant"] == null:
				var inv = get_tree().get_first_node_in_group("inventory")
				if not inv or not inv.consume_seed(Enum.Seed.COFFEE):
					if sembrados == 0:
						print("[HOE] Sin semillas — compra más al NPC.")
					break
				_plantar_en(t)
				sembrados += 1
	if sembrados > 0:
		print("[HOE] Sembradas %d plantas" % sembrados)

# ── WATER ──
func _use_water(center: Vector2i) -> void:
	var regados = 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var t = center + Vector2i(dx, dy)
			if tile_data.has(t) and not tile_data[t]["watered"]:
				soil_layer.set_cell(t, SOIL_SOURCE_ID, WATER_ATLAS_COORD)
				tile_data[t]["watered"] = true
				regados += 1
	if regados > 0:
		print("[WATER] Regados %d tiles" % regados)
	else:
		print("[WATER] No hay tiles arados sin regar cerca")

# ── SEED ──
func _use_seed(tile_pos: Vector2i) -> void:
	var target = tile_pos
	var found  = false
	if tile_data.has(tile_pos) and tile_data[tile_pos]["watered"] \
	   and tile_data[tile_pos]["plant"] == null:
		found = true
	else:
		for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1),
					Vector2i(1,1), Vector2i(-1,1), Vector2i(1,-1), Vector2i(-1,-1)]:
			var check = tile_pos + dir
			if tile_data.has(check) and tile_data[check]["watered"] \
			   and tile_data[check]["plant"] == null:
				target = check
				found  = true
				break
	if not found:
		print("[SEED] Usa HOE — ara, riega y siembra en un solo paso")
		return
	var inv = get_tree().get_first_node_in_group("inventory")
	if not inv or not inv.consume_seed(Enum.Seed.COFFEE):
		print("[SEED] Sin semillas. Compra más al NPC.")
		return
	_plantar_en(target)
	print("[SEED] Café plantado en: ", target)

# ── AXE: busca por nodos en escena, no por tile_data ──
func _use_axe() -> void:
	var todas : Array = []
	for child in objects_node.get_children():
		if child.has_method("harvest") and child.has_method("is_ready_to_harvest"):
			todas.append(child)

	if todas.is_empty():
		print("[AXE] No hay plantas en el campo")
		return

	var player_pos = player.global_position
	var lista_cercana  : Node  = null
	var dist_lista     : float = INF
	var cualquier_cerca: Node  = null
	var dist_cualquier : float = INF

	for p in todas:
		var d = player_pos.distance_to(p.global_position)
		if d < dist_cualquier:
			dist_cualquier  = d
			cualquier_cerca = p
		if p.is_ready_to_harvest() and d < dist_lista:
			dist_lista    = d
			lista_cercana = p

	if lista_cercana == null:
		if cualquier_cerca != null:
			print("[AXE] La planta más cercana aún está creciendo — espera ✅ CAFÉ LISTO")
		else:
			print("[AXE] No hay plantas cerca")
		return

	print("[AXE] ☕ Cosechando planta a %.0f px" % dist_lista)
	lista_cercana.harvest()

func on_plant_harvested(plant_node: Node) -> void:
	for tile_pos in tile_data:
		if tile_data[tile_pos]["plant"] == plant_node:
			tile_data[tile_pos]["plant"]   = null
			tile_data[tile_pos]["watered"] = false
			soil_layer.set_cell(tile_pos, SOIL_SOURCE_ID, SOIL_ATLAS_COORD)
			print("[LEVEL] Tile liberado: ", tile_pos)
			# Re-siembra automática
			var inv = get_tree().get_first_node_in_group("inventory")
			if inv and inv.has_seed(Enum.Seed.COFFEE):
				soil_layer.set_cell(tile_pos, SOIL_SOURCE_ID, WATER_ATLAS_COORD)
				tile_data[tile_pos]["watered"] = true
				if inv.consume_seed(Enum.Seed.COFFEE):
					_plantar_en(tile_pos)
					print("[LEVEL] ♻️ Re-sembrado automático")
			return
	print("[LEVEL] Planta cosechada (fuera de tile_data)")

func _use_sword() -> void:
	print("[SWORD] (pendiente)")

func _use_fish() -> void:
	print("[FISH] (pendiente)")

func _world_to_tile(world_pos: Vector2) -> Vector2i:
	return soil_layer.local_to_map(soil_layer.to_local(world_pos))

func water_adjacent(center: Vector2i) -> void:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			_use_water(center + Vector2i(dx, dy))

func _plantar_en(tile_pos: Vector2i) -> void:
	var plant = PlantScene.instantiate()
	objects_node.add_child(plant)
	plant.position = soil_layer.map_to_local(tile_pos)
	if plant.has_method("setup"):
		plant.setup(Enum.Seed.COFFEE)
	tile_data[tile_pos]["plant"] = plant

func _planta_lista_cercana(radio_px: float) -> Node:
	var player_pos = player.global_position
	var result : Node  = null
	var best   : float = radio_px
	for child in objects_node.get_children():
		if child.has_method("is_ready_to_harvest") and child.is_ready_to_harvest():
			var d = player_pos.distance_to(child.global_position)
			if d < best:
				best   = d
				result = child
	return result

# ────────────────────────────────────────────────────────────
#  PARCELA INICIAL 8x4 = 32 plantas
#
#  La parcela del juego es 50x50 tiles hacia abajo-izquierda
#  desde la coordenada (0,0) del mundo. Su centro está en
#  tile (-25, 25). Sembramos un bloque 8x4 centrado ahí.
#
#  Ajusta ORIGEN_PARCELA si la parcela está en otra posición.
#
#  Distribución:
#   Mitad IZQUIERDA (4 cols): ya LISTAS para cosechar
#   Mitad DERECHA   (4 cols): en crecimiento progresivo
# ────────────────────────────────────────────────────────────
func _spawear_gatos() -> void:
	# ── Primero eliminamos cualquier gato que pudiera existir ya ──
	for child in objects_node.get_children():
		if child.has_method("_elegir_direccion"):
			child.queue_free()

	# Corral: tiles (1,34)-(11,39) → world (16,544)-(176,624)
	# Ajusta estos valores si tu corral está en otra posición
	var CORRAL_MIN := Vector2(16,  544)
	var CORRAL_MAX := Vector2(176, 624)

	const NUM_GATOS := 2   # ← cambia este número si quieres más o menos

	for i in range(NUM_GATOS):
		var gato = CatScene.instantiate()
		objects_node.add_child(gato)
		# Posición aleatoria DENTRO del corral
		gato.global_position = Vector2(
			randf_range(CORRAL_MIN.x + 12, CORRAL_MAX.x - 12),
			randf_range(CORRAL_MIN.y + 12, CORRAL_MAX.y - 12)
		)
		gato.corral_min   = CORRAL_MIN
		gato.corral_max   = CORRAL_MAX
		gato.texture_path = "res://graphics/characters/cat.png"
		gato.speed        = randf_range(15.0, 25.0)

	print("[LEVEL] %d gatos spawneados en el corral" % NUM_GATOS)

func _sembrar_parcela_inicial() -> void:
	# Centro de la parcela 50x50 (tiles x:-50..0, y:0..50)
	# Cambia estos valores si tu parcela está en otra posición
	var ORIGEN_PARCELA := Vector2i(-25, 25)

	var sembrados = 0

	for dy in range(-2, 2):      # 4 filas
		for dx in range(-4, 4):  # 8 columnas → 32 tiles
			var t = ORIGEN_PARCELA + Vector2i(dx, dy)
			if tile_data.has(t):
				continue

			soil_layer.set_cell(t, SOIL_SOURCE_ID, WATER_ATLAS_COORD)
			tile_data[t] = { "watered": true, "plant": null }

			var plant = PlantScene.instantiate()
			objects_node.add_child(plant)
			plant.position = soil_layer.map_to_local(t)
			plant.setup(Enum.Seed.COFFEE)
			tile_data[t]["plant"] = plant
			sembrados += 1

			if dx < 0:
				# Mitad izquierda: forzar READY (10 ticks > max_grow_ticks)
				for _i in range(10):
					plant._on_timer_timeout()
			else:
				# Mitad derecha: etapa progresiva según columna (0..3 ticks)
				for _i in range(dx):
					plant._on_timer_timeout()

	print("[LEVEL] Parcela inicial: %d plantas en tile %s (mitad lista, mitad creciendo)" \
		% [sembrados, ORIGEN_PARCELA])
