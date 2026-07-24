extends Node
# ─────────────────────────────────────────────
#  DATA.GD — VERSIÓN CORREGIDA
#  FIX 2: Enum.Item.COFFEE añadido a TEXTURES e ICON_PATHS
#  NOTA FIX 1: asegúrate de tener res://graphics/plants/coffee.png
#              (3 frames: semilla, planta, maduro) antes de ejecutar.
# ─────────────────────────────────────────────

# ─── SKINS DEL JUGADOR ───────────────────────
const PLAYER_SKINS = {
	Enum.Style.BASIC:    preload("res://graphics/characters/main/main_basic.png"),
	Enum.Style.BASEBALL: preload("res://graphics/characters/main/main_blue.png"),
	Enum.Style.COWBOY:   preload("res://graphics/characters/main/main_cowboy.png"),
	Enum.Style.ENGLISH:  preload("res://graphics/characters/main/main_grey.png"),
	Enum.Style.STRAW:    preload("res://graphics/characters/main/main_straw.png"),
	Enum.Style.BEANIE:   preload("res://graphics/characters/main/main_red.png"),
}

const TILE_SIZE = 16

# ─── PLANTAS ─────────────────────────────────
const PLANT_DATA = {
	Enum.Seed.TOMATO: {
		"texture":      "res://graphics/plants/tomato.png",
		"icon_texture": "res://graphics/icons/tomato.png",
		"name":         "Tomato",
		"h_frames":     3,
		"grow_speed":   0.6,
		"death_max":    3,
		"reward":       Enum.Item.TOMATO,
	},
	Enum.Seed.CORN: {
		"texture":      "res://graphics/plants/corn.png",
		"icon_texture": "res://graphics/icons/corn.png",
		"name":         "Corn",
		"h_frames":     3,
		"grow_speed":   1.0,
		"death_max":    2,
		"reward":       Enum.Item.CORN,
	},
	Enum.Seed.PUMPKIN: {
		"texture":      "res://graphics/plants/pumpkin.png",
		"icon_texture": "res://graphics/icons/pumpkin.png",
		"name":         "Pumpkin",
		"h_frames":     3,
		"grow_speed":   0.3,
		"death_max":    3,
		"reward":       Enum.Item.PUMPKIN,
	},
	Enum.Seed.WHEAT: {
		"texture":      "res://graphics/plants/wheat.png",
		"icon_texture": "res://graphics/icons/wheat.png",
		"name":         "Wheat",
		"h_frames":     3,
		"grow_speed":   1.0,
		"death_max":    3,
		"reward":       Enum.Item.WHEAT,
	},
	# ── CAFÉ — cultivo principal del juego ──
	# FIX 1: crea res://graphics/plants/coffee.png (3 frames: semilla, planta, maduro)
	Enum.Seed.COFFEE: {
		"texture":      "res://graphics/plants/coffee.png",
		"icon_texture": "res://graphics/icons/SeedCafe.png",
		"name":         "Café",
		"h_frames":     4,  # igual que los demás cultivos (64px / 16px = 4 frames)
		"grow_speed":   0.8,
		"death_max":    4,
		"reward":       Enum.Item.COFFEE,
	},
}

# ─── TEXTURAS DE HERRAMIENTAS (para HUD) ─────
const TOOL_TEXTURES = {
	Enum.Tool.AXE:   preload("res://graphics/icons/axe.png"),
	Enum.Tool.HOE:   preload("res://graphics/icons/hoe.png"),
	Enum.Tool.WATER: preload("res://graphics/icons/water.png"),
	Enum.Tool.SWORD: preload("res://graphics/icons/sword.png"),
	Enum.Tool.FISH:  preload("res://graphics/icons/fish.png"),
	Enum.Tool.SEED:  preload("res://graphics/icons/wheat.png"),
}

# ─── TEXTURAS DE SEMILLAS ────────────────────
const SEED_TEXTURES = {
	Enum.Seed.CORN:    preload("res://graphics/icons/corn.png"),
	Enum.Seed.PUMPKIN: preload("res://graphics/icons/pumpkin.png"),
	Enum.Seed.TOMATO:  preload("res://graphics/icons/tomato.png"),
	Enum.Seed.WHEAT:   preload("res://graphics/icons/wheat.png"),
	Enum.Seed.COFFEE:  preload("res://graphics/icons/SeedCafe.png"),
}

# ─── TEXTURAS DE ITEMS (para UI de inventario) ──
const TEXTURES = {
	Enum.Item.WOOD:    preload("res://graphics/icons/wood.png"),
	Enum.Item.APPLE:   preload("res://graphics/icons/apple.png"),
	Enum.Item.FISH:    preload("res://graphics/icons/goldfish.png"),
	Enum.Item.CORN:    preload("res://graphics/icons/corn.png"),
	Enum.Item.TOMATO:  preload("res://graphics/icons/tomato.png"),
	Enum.Item.PUMPKIN: preload("res://graphics/icons/pumpkin.png"),
	Enum.Item.WHEAT:   preload("res://graphics/icons/wheat.png"),
	Enum.Item.COFFEE:  preload("res://graphics/icons/SeedCafe.png"),  # FIX 2: descomentado
}

# ─── ANIMACIONES DE HERRAMIENTAS ─────────────
const TOOL_STATE_ANIMATIONS = {
	Enum.Tool.HOE:   "Hoe",
	Enum.Tool.AXE:   "Axe",
	Enum.Tool.WATER: "Water",
	Enum.Tool.SWORD: "Sword",
	Enum.Tool.FISH:  "Fish",
	Enum.Tool.SEED:  "Seed",
}

# ─── MÁQUINAS ────────────────────────────────
const MACHINE_UPGRADE_COST = {
	Enum.Machine.SPRINKLER: {
		"name":  "Sprinkler",
		"cost":  {Enum.Item.TOMATO: 30, Enum.Item.WHEAT: 20},
		"icon":  preload("res://graphics/icons/sprinkler.png"),
		"color": Color.SEA_GREEN,
	},
	Enum.Machine.FISHER: {
		"name":  "Fisher",
		"cost":  {Enum.Item.WOOD: 25, Enum.Item.FISH: 15},
		"icon":  preload("res://graphics/icons/fisher.png"),
		"color": Color.SLATE_GRAY,
	},
	Enum.Machine.SCARECROW: {
		"name":  "Scarecrow",
		"cost":  {Enum.Item.PUMPKIN: 15, Enum.Item.CORN: 15},
		"icon":  preload("res://graphics/icons/scarecrow.png"),
		"color": Color.BURLYWOOD,
	},
}

# ─── COSTOS DE CASA ──────────────────────────
const HOUSE_COST = {
	1: {Enum.Item.WOOD: 30, Enum.Item.APPLE: 20},
	2: {Enum.Item.WOOD: 40, Enum.Item.APPLE: 30},
}

# ─── UPGRADES DE ESTILO ──────────────────────
const STYLE_UPGRADES = {
	Enum.Style.COWBOY:   {"name":"Cowboy",   "cost":{Enum.Item.WOOD:8, Enum.Item.CORN:6},    "icon":preload("res://graphics/icons/cowboy.png"),  "color":Color.SANDY_BROWN},
	Enum.Style.ENGLISH:  {"name":"Oldie",    "cost":{Enum.Item.CORN:8, Enum.Item.WHEAT:6},   "icon":preload("res://graphics/icons/english.png"), "color":Color.LIGHT_GRAY},
	Enum.Style.BASEBALL: {"name":"Baseball", "cost":{Enum.Item.TOMATO:8, Enum.Item.APPLE:6}, "icon":preload("res://graphics/icons/blue.png"),    "color":Color.SKY_BLUE},
	Enum.Style.BEANIE:   {"name":"Beanie",   "cost":{Enum.Item.PUMPKIN:8, Enum.Item.WHEAT:6},"icon":preload("res://graphics/icons/beanie.png"),  "color":Color.INDIAN_RED},
	Enum.Style.STRAW:    {"name":"Straw",    "cost":{Enum.Item.FISH:8, Enum.Item.WOOD:6},    "icon":preload("res://graphics/icons/straw.png"),   "color":Color.BURLYWOOD},
}

# ─── PREVIEW DE MÁQUINAS ─────────────────────
const MACHINE_PREVIEW_TEXTURES = {
	Enum.Machine.SPRINKLER: {"texture": preload("res://graphics/icons/sprinkler.png"), "offset": Vector2i(0, 0)},
	Enum.Machine.FISHER:    {"texture": preload("res://graphics/icons/fisher.png"),    "offset": Vector2i(0,-4)},
	Enum.Machine.SCARECROW: {"texture": preload("res://graphics/icons/scarecrow.png"), "offset": Vector2i(0,-4)},
	Enum.Machine.DELETE:    {"texture": preload("res://graphics/icons/delete.png"),    "offset": Vector2i(0, 0)},
}

# ─── ICONOS DE SHOP ──────────────────────────
const ICON_PATHS = {
	Enum.Item.WOOD:    "res://graphics/icons/wood.png",
	Enum.Item.FISH:    "res://graphics/icons/goldfish.png",
	Enum.Item.APPLE:   "res://graphics/icons/apple.png",
	Enum.Item.CORN:    "res://graphics/icons/corn.png",
	Enum.Item.WHEAT:   "res://graphics/icons/wheat.png",
	Enum.Item.PUMPKIN: "res://graphics/icons/pumpkin.png",
	Enum.Item.TOMATO:  "res://graphics/icons/tomato.png",
	Enum.Item.COFFEE:  "res://graphics/icons/SeedCafe.png",  # FIX 2: COFFEE añadido
}
