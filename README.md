# RayCastMult3D — Advanced Multi-Hit Raycast Utility for Godot 4.x

**RayCastMult3D** is a powerful and customizable **multi-hit raycast node** for **Godot 4.x**, designed to perform multiple sequential ray intersection checks between two points in 3D space.  
It supports **body and area collisions**, custom exclude lists, visual debugging, and flexible offset/margin settings.

This plugin is especially useful for:
- Advanced shooting or projectile detection.
- Wall-penetrating sensors (multi-layer collision detection).
- Environmental scanning or line tracing.
- Physics debugging tools.

---

## 🚀 Features

- Multi-hit raycasting (detects multiple collision points along a single ray).
- Fully configurable collision parameters.
- Optional debug visualization (with editable material and mesh properties).
- Dynamic exclusion system (bodies, “from” node, “to” node).
- Editor warnings and safety checks.
- Lightweight and fully GDScript-based — no C++ extension needed.

---

## 📦 Installation

1. Copy the `RayCastMult3D.gd` script into your project’s `addons/` folder.
2. Enable the plugin in **Project Settings → Plugins → RayCastMult3D**.
3. Add the node `RayCastMult3D` to your 3D scene.

---

## 🧩 Usage Example

```gdscript
@onready var ray_mult := $RayCastMult3D

func _ready() -> void:
    ray_mult.from = $Player
    ray_mult.to = $Target
    ray_mult.connect("intersect_ray", Callable(self, "_on_ray_hits"))

func _on_ray_hits(results: Array[RaycastMultResult]) -> void:
    for hit in results:
        print("Hit object:", hit.collider, "at position:", hit.position)
