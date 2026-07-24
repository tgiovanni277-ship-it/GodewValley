extends CharacterBody2D
# ─────────────────────────────────────────────
#  NPC VENDEDOR — Solo café
#  • COMPRA (jugador vende): solo Item.COFFEE
#  • VENDE (jugador compra): solo Seed.COFFEE
#  Moneda usada: Item.WOOD (monedas del juego)
# ─────────────────────────────────────────────

signal shop_opened
signal shop_closed

@onready var detection_area : Area2D = $DetectionArea
@onready var dialog_panel   : Control = null

const INTERACT_KEY = "action"
var player_nearby  : bool = false
var shop_is_open   : bool = false

func _ready() -> void:
	add_to_group("npc_vendedor")

	if detection_area:
		detection_area.body_entered.connect(_on_body_entered)
		detection_area.body_exited.connect(_on_body_exited)
	else:
		push_warning("NPCVendedor: falta DetectionArea (Area2D). Agrégala como hijo.")

	await get_tree().process_frame
	if dialog_panel == null:
		dialog_panel = get_tree().get_first_node_in_group("dialog_panel")

	if dialog_panel == null:
		push_error("NPCVendedor: no se encontró ningún nodo con el grupo 'dialog_panel'.")

func _input(event: InputEvent) -> void:
	if not player_nearby:
		return
	if Input.is_action_just_pressed(INTERACT_KEY):
		if shop_is_open:
			_close_shop()
		else:
			_open_shop()
		get_viewport().set_input_as_handled()

# ─── DETECCIÓN ───────────────────────────────
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		_show_interact_hint(true)
		print("[NPC] Jugador cerca del vendedor de café")

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		_show_interact_hint(false)
		if shop_is_open:
			_close_shop()

# ─── TIENDA ──────────────────────────────────
func _open_shop() -> void:
	shop_is_open = true
	emit_signal("shop_opened")
	_show_interact_hint(false)
	if dialog_panel:
		dialog_panel.visible = true
		if dialog_panel.has_method("open_shop"):
			dialog_panel.open_shop(_get_shop_data())
	else:
		push_warning("[NPC] dialog_panel es null")
	print("[NPC] Tienda de café abierta")

func _close_shop() -> void:
	shop_is_open = false
	emit_signal("shop_closed")
	if dialog_panel:
		dialog_panel.visible = false
	_show_interact_hint(true)
	print("[NPC] Tienda de café cerrada")

func _get_shop_data() -> Dictionary:
	return {
		# El jugador puede COMPRAR solo semilla de café
		"seeds": {
			Enum.Seed.COFFEE: { "price": {Enum.Item.WOOD: 5}, "name": "Semilla de Café" },
		},
		# El NPC solo COMPRA café cosechado al jugador
		"buy_prices": {
			Enum.Item.COFFEE: 6,
		}
	}

func _show_interact_hint(p_show: bool) -> void:
	var hint = get_tree().get_first_node_in_group("interact_hint")
	if hint:
		hint.visible = p_show
