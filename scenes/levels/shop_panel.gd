extends PanelContainer
# ─────────────────────────────────────────────
#  SHOP PANEL — Solo café
#  Sección VENDER : muestra solo Item.COFFEE
#  Sección COMPRAR: muestra solo Seed.COFFEE
#  Moneda: Item.WOOD
# ─────────────────────────────────────────────

signal closed

@onready var sell_list  : HBoxContainer = $VBoxContainer/SellList
@onready var buy_list   : HBoxContainer = $VBoxContainer/BuyList
@onready var btn_cerrar : Button        = $VBoxContainer/BtnCerrar

var shop_data : Dictionary = {}

func _ready() -> void:
	add_to_group("dialog_panel")
	btn_cerrar.pressed.connect(_on_cerrar)
	visible = false

func open_shop(data: Dictionary) -> void:
	shop_data = data
	_build_sell_list()
	_build_buy_list()
	visible = true

# ─── SECCIÓN: EL JUGADOR VENDE CAFÉ ─────────
func _build_sell_list() -> void:
	for c in sell_list.get_children():
		c.queue_free()

	var buy_prices = shop_data.get("buy_prices", {})

	# Solo mostrar café cosechado
	if not buy_prices.has(Enum.Item.COFFEE):
		var lbl = Label.new()
		lbl.text = "Nada que vender"
		sell_list.add_child(lbl)
		return

	var amount = Inventory.get_item(Enum.Item.COFFEE)
	var price  = buy_prices[Enum.Item.COFFEE]

	if amount <= 0:
		var lbl = Label.new()
		lbl.text = "No tienes café para vender"
		sell_list.add_child(lbl)
		return

	var btn = Button.new()
	btn.text = "Vender Café x%d  →  %d 🪙" % [amount, amount * price]
	btn.pressed.connect(_on_sell.bind(Enum.Item.COFFEE, price))
	sell_list.add_child(btn)

# ─── SECCIÓN: EL JUGADOR COMPRA SEMILLA ─────
func _build_buy_list() -> void:
	for c in buy_list.get_children():
		c.queue_free()

	var seeds = shop_data.get("seeds", {})

	if not seeds.has(Enum.Seed.COFFEE):
		var lbl = Label.new()
		lbl.text = "Sin stock de semillas"
		buy_list.add_child(lbl)
		return

	var info      = seeds[Enum.Seed.COFFEE]
	var cost_wood = info["price"].get(Enum.Item.WOOD, 0)
	var coins     = Inventory.get_item(Enum.Item.WOOD)

	var btn = Button.new()
	btn.text = "Comprar Semilla de Café (x5)  —  %d 🪙  (tienes: %d)" % [cost_wood, coins]
	btn.disabled = coins < cost_wood
	btn.pressed.connect(_on_buy_seed.bind(Enum.Seed.COFFEE, info["price"]))
	buy_list.add_child(btn)

# ─── CALLBACKS ───────────────────────────────
func _on_sell(item_type: int, price_per_unit: int) -> void:
	var amount = Inventory.get_item(item_type)
	if amount <= 0:
		return
	Inventory.consume_item(item_type, amount)
	Inventory.add_item(Enum.Item.WOOD, amount * price_per_unit)
	print("[SHOP] Vendido %d café por %d monedas" % [amount, amount * price_per_unit])
	_build_sell_list()
	_build_buy_list()

func _on_buy_seed(seed_type: int, cost: Dictionary) -> void:
	if not Inventory.spend(cost):
		print("[SHOP] No tienes suficientes monedas.")
		return
	Inventory.add_seed(seed_type, 5)
	print("[SHOP] Comprado 5x Semilla de Café")
	_build_buy_list()
	_build_sell_list()

func _on_cerrar() -> void:
	visible = false
	emit_signal("closed")
