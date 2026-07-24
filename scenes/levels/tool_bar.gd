extends HBoxContainer
# ─────────────────────────────────────────────
#  TOOLBAR — CORREGIDO
#  Fix: player se obtiene de forma lazy en _on_tool_selected
#  para evitar null cuando toolbar carga antes que el player.
# ─────────────────────────────────────────────

@onready var buttons: Dictionary = {
	Enum.Tool.HOE:   $BtnHoe,
	Enum.Tool.WATER: $BtnWater,
	Enum.Tool.SEED:  $BtnSeed,
	Enum.Tool.AXE:   $BtnAxe,
	Enum.Tool.SWORD: $BtnSword,
	Enum.Tool.FISH:  $BtnFish,
}

func _ready() -> void:
	add_to_group("toolbar")
	$BtnHoe.pressed.connect(_on_tool_selected.bind(Enum.Tool.HOE))
	$BtnWater.pressed.connect(_on_tool_selected.bind(Enum.Tool.WATER))
	$BtnSeed.pressed.connect(_on_tool_selected.bind(Enum.Tool.SEED))
	$BtnAxe.pressed.connect(_on_tool_selected.bind(Enum.Tool.AXE))
	$BtnSword.pressed.connect(_on_tool_selected.bind(Enum.Tool.SWORD))
	$BtnFish.pressed.connect(_on_tool_selected.bind(Enum.Tool.FISH))
	highlight(Enum.Tool.HOE)

func _on_tool_selected(tool: int) -> void:
	# ← FIX: obtener player en el momento del clic, no en _ready
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.current_tool = tool
		player.tool_index = player.TOOLS.find(tool)
	highlight(tool)

func highlight(tool: int) -> void:
	for t in buttons:
		buttons[t].modulate = Color(1, 1, 1, 1)
	buttons[tool].modulate = Color(1, 1, 0, 1)
