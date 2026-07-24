extends Node2D
# FIX: preload reemplazado por load() para evitar crash si plant.tscn no existe al iniciar
# NUEVO: on_plant_harvested() para limpiar tile_data cuando una planta muere o se cosecha

@onready var soil_layer   : TileMapLayer    = $Layers/Soil
@onready var ground_layer : TileMapLayer    = $Layers/Ground
@onready var objects_node : Node2D          = $Objects
@onready var player       : CharacterBody2D = $Objects/Player

const SOIL_SOURCE_ID    = 1
const SOIL_ATLAS_COORD  = Vector2i(0, 0)
const WATER_ATLAS_COORD = Vector2i(1, 0)

var tile_data : Dictionary = {}

func _ready() -> void:
	add_to_group("level")
	if player:
		player.tool_used.connect(_on_tool_used)
		_update_player_limits()
	else:
		push_error("level.gd: no se encontró el Player bajo Objects/")

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
		Enum.Tool.AXE:   _use_axe(tile_pos)
		Enum.Tool.SWORD: _use_sword()
		Enum.Tool.FISH:  _use_fish()

func _use_hoe(tile_pos: Vector2i) -> void:
	if tile_data.has(tile_pos):
		return
	soil_layer.set_cell(tile_pos, SOIL_SOURCE_ID, SOIL_ATLAS_COORD)
	tile_data[tile_pos] = { "watered": false, "plant": null }
	print("[HOE] Tile arado: ", tile_pos)

func _use_water(tile_pos: Vector2i) -> void:
	if not tile_data.has(tile_pos):
		return
	if tile_data[tile_pos]["watered"]:
		return
	soil_layer.set_cell(tile_pos, SOIL_SOURCE_ID, WATER_ATLAS_COORD)
	tile_data[tile_pos]["watered"] = true
	print("[WATER] Tile regado: ", tile_pos)

func _use_seed(tile_pos: Vector2i) -> void:
	if not tile_data.has(tile_pos):
		print("[SEED] Primero hay que arar con HOE.")
		return
	if not tile_data[tile_pos]["watered"]:
		print("[SEED] El tile debe estar regado.")
		return
	if tile_data[tile_pos]["plant"] != null:
		print("[SEED] Ya hay una planta aquí.")
		return

	var seed_type = _get_active_seed()

	var inv = get_tree().get_first_node_in_group("inventory")
	if not inv or not inv.consume_seed(seed_type):
		print("[SEED] No hay semillas de ese tipo en el inventario.")
		return

	# FIX: load() en lugar de preload() para no crashear al inicio
	var PlantScene = load("res://scenes/plant.tscn")
	if PlantScene == null:
		push_error("Plant: falta res://scenes/plant.tscn — créala en Godot con Node2D + Sprite2D + Timer")
		return

	var plant = PlantScene.instantiate()
	objects_node.add_child(plant)
	plant.position = soil_layer.map_to_local(tile_pos)
	if plant.has_method("setup"):
		plant.setup(seed_type)

	tile_data[tile_pos]["plant"] = plant
	print("[SEED] Plantado ", Enum.Seed.keys()[seed_type], " en: ", tile_pos)

func _use_axe(tile_pos: Vector2i) -> void:
	if tile_data.has(tile_pos) and tile_data[tile_pos]["plant"] != null:
		var p = tile_data[tile_pos]["plant"]
		if p.has_method("harvest"):
			p.harvest()
		# tile_data se limpia en on_plant_harvested()
		print("[AXE] Cosechando en: ", tile_pos)
	else:
		print("[AXE] No hay planta aquí.")

func _use_sword() -> void:
	print("[SWORD] (combate pendiente)")

func _use_fish() -> void:
	print("[FISH] (pesca pendiente)")

# Llamado desde plant.gd cuando la planta se cosecha o muere
func on_plant_harvested(plant_node: Node) -> void:
	for tile_pos in tile_data:
		if tile_data[tile_pos]["plant"] == plant_node:
			tile_data[tile_pos]["plant"] = null
			tile_data[tile_pos]["watered"] = false
			soil_layer.set_cell(tile_pos, SOIL_SOURCE_ID, SOIL_ATLAS_COORD)
			print("[LEVEL] Tile limpiado: ", tile_pos)
			return

func _world_to_tile(world_pos: Vector2) -> Vector2i:
	return soil_layer.local_to_map(soil_layer.to_local(world_pos))

func _get_active_seed() -> int:
	var inv = get_tree().get_first_node_in_group("inventory")
	if inv and inv.has_method("get_active_seed"):
		return inv.get_active_seed()
	return Enum.Seed.CORN

const SOIL_DIRECTIONS = [
	Vector2i(-1,-1), Vector2i(0,-1), Vector2i(1,-1),
	Vector2i(-1, 0),                 Vector2i(1, 0),
	Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]

func water_adjacent(center: Vector2i) -> void:
	for dir in SOIL_DIRECTIONS:
		_use_water(center + dir)
