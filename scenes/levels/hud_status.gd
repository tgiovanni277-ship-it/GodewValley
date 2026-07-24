extends CanvasLayer
# ─────────────────────────────────────────────
#  HUD_STATUS.GD — Versión mejorada
#  • Notificación flash "+N monedas" al cosechar
#  • Semillas en rojo cuando quedan pocas (< 3)
# ─────────────────────────────────────────────

var lbl_monedas    : Label
var lbl_cafe       : Label
var lbl_semillas   : Label
var lbl_herramienta: Label
var lbl_estado     : Label
var lbl_flash      : Label   # notificación flotante temporal

func _ready() -> void:
	layer = 10

	var panel = PanelContainer.new()
	panel.position = Vector2(8, 8)
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	lbl_monedas     = _make_label("🪙 Monedas: 0")
	lbl_cafe        = _make_label("☕ Café: 0")
	lbl_semillas    = _make_label("🌱 Semillas: 0")
	lbl_herramienta = _make_label("🔧 Hoe")
	lbl_estado      = _make_label("")

	for lbl in [lbl_monedas, lbl_cafe, lbl_semillas, lbl_herramienta, lbl_estado]:
		vbox.add_child(lbl)

	# Label flotante de notificación (esquina superior derecha)
	lbl_flash = Label.new()
	lbl_flash.add_theme_font_size_override("font_size", 18)
	lbl_flash.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	lbl_flash.add_theme_color_override("font_shadow_color", Color.BLACK)
	lbl_flash.add_theme_constant_override("shadow_offset_x", 2)
	lbl_flash.add_theme_constant_override("shadow_offset_y", 2)
	lbl_flash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_flash.position = Vector2(200, 20)
	lbl_flash.visible  = false
	add_child(lbl_flash)

	await get_tree().process_frame
	var inv = get_tree().get_first_node_in_group("inventory")
	if inv:
		inv.inventory_changed.connect(_refresh)
		_refresh()
	else:
		push_warning("HudStatus: no encontró el nodo 'inventory'")

func _make_label(text: String) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	return lbl

var _monedas_prev : int = -1

func _refresh() -> void:
	var inv = get_tree().get_first_node_in_group("inventory")
	if not inv:
		return
	var monedas  = inv.get_item(Enum.Item.WOOD)
	var cafe     = inv.get_item(Enum.Item.COFFEE)
	var semillas = inv.seed_amount.get(Enum.Seed.COFFEE, 0)

	# Flash si ganamos monedas
	if _monedas_prev >= 0 and monedas > _monedas_prev:
		_show_flash("+%d 🪙" % (monedas - _monedas_prev))
	_monedas_prev = monedas

	lbl_monedas.text = "🪙 Monedas: %d" % monedas
	lbl_cafe.text    = "☕ Café cosechado: %d" % cafe

	# Semillas en rojo si quedan pocas
	if semillas <= 2:
		lbl_semillas.add_theme_color_override("font_color", Color(1.0, 0.35, 0.3))
		lbl_semillas.text = "🌱 Semillas: %d  ⚠️ ¡Compra más!" % semillas
	else:
		lbl_semillas.add_theme_color_override("font_color", Color.WHITE)
		lbl_semillas.text = "🌱 Semillas de café: %d" % semillas

func _show_flash(msg: String) -> void:
	lbl_flash.text    = msg
	lbl_flash.visible = true
	lbl_flash.modulate = Color(1, 1, 1, 1)
	# Desvanece en 1.5s
	var tween = create_tween()
	tween.tween_property(lbl_flash, "modulate:a", 0.0, 1.5)
	tween.tween_callback(func(): lbl_flash.visible = false)

func set_tool(tool_enum: int) -> void:
	var nombres = {
		Enum.Tool.HOE:   "🪣 HOE — ara + riega + siembra en 1 paso",
		Enum.Tool.WATER: "💧 Regadera — riega tiles arados",
		Enum.Tool.SEED:  "🌱 Semilla — planta en tile regado",
		Enum.Tool.AXE:   "🪓 Hoz — cosecha cuando esté maduro",
		Enum.Tool.SWORD: "⚔️ Espada",
		Enum.Tool.FISH:  "🎣 Caña",
	}
	lbl_herramienta.text = nombres.get(tool_enum, "Herramienta")

func set_tile_estado(estado: String) -> void:
	lbl_estado.text = estado
