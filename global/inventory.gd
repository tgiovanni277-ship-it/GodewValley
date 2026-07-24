extends Node
# ─────────────────────────────────────────────
#  INVENTORY — Solo café
#  La semilla activa por defecto es COFFEE.
#  Los demás cultivos se mantienen en el enum
#  pero el jugador solo empieza con semillas de café.
# ─────────────────────────────────────────────

signal inventory_changed

# ─── SEMILLAS ────────────────────────────────
var seed_amount: Dictionary = {
	Enum.Seed.CORN:    0,
	Enum.Seed.TOMATO:  0,
	Enum.Seed.PUMPKIN: 0,
	Enum.Seed.WHEAT:   0,
	Enum.Seed.COFFEE:  5,   # Jugador comienza con 5 semillas de café
}

# Semilla activa = Café (único que se planta)
var active_seed: int = Enum.Seed.COFFEE

# ─── ITEMS ───────────────────────────────────
var items: Dictionary = {
	Enum.Item.WOOD:    10,   # Monedas iniciales para poder comprar semillas
	Enum.Item.APPLE:   0,
	Enum.Item.FISH:    0,
	Enum.Item.CORN:    0,
	Enum.Item.WHEAT:   0,
	Enum.Item.PUMPKIN: 0,
	Enum.Item.TOMATO:  0,
	Enum.Item.COFFEE:  0,   # Café cosechado (se vende al NPC)
}

func _ready() -> void:
	add_to_group("inventory")

# ─── SEMILLAS ────────────────────────────────
func get_active_seed() -> int:
	return active_seed

func set_active_seed(seed_type: int) -> void:
	active_seed = seed_type
	emit_signal("inventory_changed")

func has_seed(seed_type: int) -> bool:
	return seed_amount.get(seed_type, 0) > 0

func consume_seed(seed_type: int) -> bool:
	if not has_seed(seed_type):
		return false
	seed_amount[seed_type] -= 1
	emit_signal("inventory_changed")
	return true

func add_seed(seed_type: int, amount: int = 1) -> void:
	seed_amount[seed_type] = seed_amount.get(seed_type, 0) + amount
	emit_signal("inventory_changed")

# ─── ITEMS ───────────────────────────────────
func get_item(item_type: int) -> int:
	return items.get(item_type, 0)

func add_item(item_type: int, amount: int = 1) -> void:
	items[item_type] = items.get(item_type, 0) + amount
	emit_signal("inventory_changed")
	print("[INVENTORY] +", amount, " ", Enum.Item.keys()[item_type])

func consume_item(item_type: int, amount: int = 1) -> bool:
	if get_item(item_type) < amount:
		return false
	items[item_type] -= amount
	emit_signal("inventory_changed")
	return true

func can_afford(cost: Dictionary) -> bool:
	for item_type in cost:
		if get_item(item_type) < cost[item_type]:
			return false
	return true

func spend(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for item_type in cost:
		items[item_type] -= cost[item_type]
	emit_signal("inventory_changed")
	return true

# ─── DEBUG ───────────────────────────────────
func print_inventory() -> void:
	print("=== INVENTARIO ===")
	print("Semilla activa: ", Enum.Seed.keys()[active_seed])
	print("  Semillas de Café: ", seed_amount.get(Enum.Seed.COFFEE, 0))
	print("  Café cosechado: ",  items.get(Enum.Item.COFFEE, 0))
	print("  Monedas (Wood): ",  items.get(Enum.Item.WOOD, 0))
