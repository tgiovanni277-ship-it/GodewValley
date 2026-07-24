extends CharacterBody2D

signal tool_used

const SPEED  = 80
var farm_min : Vector2 = Vector2(0, 0)
var farm_max : Vector2 = Vector2(800, 800)

@onready var anim      = $Animation/AnimationPlayer
@onready var anim_tree = $Animation/AnimationTree

var last_dir     : String = "down"
var current_tool : int    = Enum.Tool.HOE
var is_using_tool: bool   = false

const TOOLS = [
	Enum.Tool.HOE, Enum.Tool.WATER, Enum.Tool.SEED,
	Enum.Tool.AXE, Enum.Tool.SWORD, Enum.Tool.FISH,
]
var tool_index : int = 0

func _ready() -> void:
	add_to_group("player")
	anim_tree.active = false
	anim.play("idle_down")

func set_farm_bounds(p_min: Vector2, p_max: Vector2) -> void:
	farm_min = p_min
	farm_max = p_max

func _physics_process(_delta: float) -> void:
	var direction := Vector2.ZERO
	if Input.is_action_pressed("right"): direction.x += 1; last_dir = "right"
	if Input.is_action_pressed("left"):  direction.x -= 1; last_dir = "left"
	if Input.is_action_pressed("down"):  direction.y += 1; last_dir = "down"
	if Input.is_action_pressed("up"):    direction.y -= 1; last_dir = "up"

	if not is_using_tool:
		if direction.length() > 0:
			direction = direction.normalized()
			_play("walk")
		else:
			_play("idle")

	if Input.is_action_just_pressed("tool_forward"):
		_next_tool(1)
	if Input.is_action_just_pressed("tool_backward"):
		_next_tool(-1)
	if Input.is_action_just_pressed("action"):
		_use_current_tool()

	velocity = direction * SPEED
	move_and_slide()
	position.x = clamp(position.x, farm_min.x, farm_max.x)
	position.y = clamp(position.y, farm_min.y, farm_max.y)

func _play(action: String) -> void:
	if is_using_tool:
		return
	var nombre := action + "_" + last_dir
	if anim.current_animation == nombre:
		return
	anim.play(nombre)

func _use_current_tool() -> void:
	if is_using_tool:
		return
	var tool_name : String = str(Data.TOOL_STATE_ANIMATIONS[current_tool]).to_lower()
	var anim_name := tool_name + "_" + last_dir
	if anim.has_animation(anim_name):
		is_using_tool = true
		anim.play(anim_name)
		await anim.animation_finished
		emit_signal("tool_used")
		is_using_tool = false
		anim.play("idle_" + last_dir)
	else:
		push_warning("Player: animación no encontrada: " + anim_name)
		emit_signal("tool_used")

func _next_tool(dir: int) -> void:
	# FIX: wrapping seguro — % en GDScript devuelve negativo con dividendo negativo
	tool_index = ((tool_index + dir) % TOOLS.size() + TOOLS.size()) % TOOLS.size()
	current_tool = TOOLS[tool_index]
	var toolbar = get_tree().get_first_node_in_group("toolbar")
	if toolbar:
		toolbar.highlight(current_tool)
	# FIX: notificar al HUD para actualizar el label de herramienta
	var hud = get_tree().get_first_node_in_group("hud_status")
	if hud and hud.has_method("set_tool"):
		hud.set_tool(current_tool)
	print("Herramienta: ", Data.TOOL_STATE_ANIMATIONS[current_tool])
