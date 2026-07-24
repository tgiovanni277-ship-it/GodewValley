# ☕ Granja Cafetera

Videojuego 2D de simulación agrícola desarrollado en **Godot Engine 4** con **GDScript**. El jugador administra una granja dedicada al cultivo y comercialización de café: plantar, cuidar, cosechar y vender.

![Godot Engine](https://img.shields.io/badge/Godot-4.x-478CBF?logo=godotengine&logoColor=white)
![GDScript](https://img.shields.io/badge/GDScript-lenguaje-355570)
![Estado](https://img.shields.io/badge/estado-en%20desarrollo-yellow)



## 📋 Descripción

La mecánica central gira en torno al ciclo de vida del café:

1. **Plantar** semillas de café con la herramienta **Hoe** (azadón) — ara, riega y siembra en un solo uso.
2. **Cuidar** los cultivos mientras crecen a través de varios ticks de tiempo.
3. **Cosechar** el café maduro con la herramienta **Axe** (hoz) antes de que muera.
4. **Vender** el café al NPC vendedor a cambio de monedas (`Item.WOOD`).
5. **Comprar** más semillas con las monedas acumuladas y repetir el ciclo.

## 🎮 Controles

| Acción                                 | Tecla                     |
| -------------------------------------- | ------------------------- |
| Moverse                                | `W` `A` `S` `D` / Flechas |
| Usar herramienta / Interactuar con NPC | `Espacio`                 |
| Siguiente herramienta                  | `E`                       |
| Herramienta anterior                   | `Q`                       |

## 🌱 Ciclo de la Planta

```
SEED → GROWING → READY → (cosechar) o DEAD si no se cosecha a tiempo
```

- **Crecimiento:** ~6 ticks (`grow_speed = 0.8`, ~12 segundos reales)
- **Ventana de cosecha:** 4 ticks tras madurar (~8 segundos) antes de morir
- **Recompensa por cosecha:** 1 café al inventario + 8 monedas

## 🗂️ Estructura del Proyecto

```
gv_start_project/
├── global/              # Scripts Autoload: Enum, Data, Inventory
├── scenes/
│   ├── levels/           # Escena y lógica del nivel de juego
│   └── characters/       # Scripts de personajes (jugador, NPC)
├── graphics/             # Sprites, tilesets, iconos
└── .godot/               # Caché interna del editor (no editar)
```

### Scripts globales (Autoload)

| Script         | Rol                                                              |
| -------------- | ---------------------------------------------------------------- |
| `enums.gd`     | Enumeraciones de herramientas, semillas, ítems, estilos, tiendas |
| `data.gd`      | Configuración estática: texturas, datos de cultivos, skins       |
| `inventory.gd` | Gestión de inventario: ítems, semillas y monedas                 |

> **Nota:** `Item.WOOD` funciona como la moneda del juego, aunque el nombre sugiera "madera".

## 🌳 Árbol de Escenas (`level.tscn`)

```
Level (Node2D) [level.gd]
├── Layers (Node2D)
│   ├── Ground (TileMapLayer)
│   └── Soil (TileMapLayer)
├── Objects (Node2D)
│   ├── Player (CharacterBody2D) [player.gd]
│   └── NPC_Vendedor (CharacterBody2D) [npc_vendedor.gd]
│       └── DetectionArea (Area2D)
└── UI (CanvasLayer)
    ├── HUDStatus [hud_status.gd]
    ├── ToolBar [tool_bar.gd]
    ├── ShopPanel [shop_panel.gd]
    └── InteractHint (Label)
```

## 🛒 Sistema de Tienda (NPC Vendedor)

| Acción           | Detalle                          |
| ---------------- | -------------------------------- |
| Vender café      | 6 monedas por unidad             |
| Comprar semillas | 5 semillas de café por 5 monedas |

El NPC detecta la proximidad del jugador mediante un `Area2D` circular y despliega un panel de UI con las secciones **COMPRAR** / **VENDER**.

## 🖥️ HUD

El panel superior informa el estado del tile bajo el jugador en tiempo real:

- 🟫 Arado — usa HOE para sembrar
- 💧 Regado — usa semilla para plantar
- 🟢 Creciendo... espera
- 🟡 LISTO — presiona AXE para cosechar (+8 monedas)

## 🚀 Cómo ejecutar el proyecto

1. Instalar [Godot Engine 4.x](https://godotengine.org/download)
2. Clonar este repositorio:
   ```bash
   git clone https://github.com/tu-usuario/granja-cafetera.git
   ```
3. Abrir Godot Engine → **Importar** → seleccionar la carpeta `gv_start_project/`
4. Ejecutar la escena principal (`level.tscn`)

## 🛠️ Tecnologías

- **Motor:** Godot Engine 4
- **Lenguaje:** GDScript
- **Tipo:** Simulación agrícola 2D (top-down)

## 📖 Documentación Técnica

Este repositorio incluye documentación técnica completa del proyecto (arquitectura de scripts, sistema de señales, lógica de movimiento y mecánicas) 

## 👤 Autor

**Giovanni Andrés Torres Pinzón**

---

⭐ Si te gustó este proyecto, no olvides darle una estrella al repo.
