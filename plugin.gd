@tool
extends EditorPlugin

var icon: CompressedTexture2D = preload("res://addons/raycast_mult_3d/icon-16.png")
var main_script: Script = preload("res://addons/raycast_mult_3d/raycast_mult_3d.gd")
var raycast_mult_result: RefCounted = preload("res://addons/raycast_mult_3d/raycast_mult_result.gd")



func _enter_tree() -> void:
	add_custom_type("RayCastMult3D", "Node", main_script, icon)
	add_custom_type("RayCastMultResult", "RefCounted", raycast_mult_result, icon)


func _exit_tree() -> void:
	remove_custom_type("RayCastMult3D")
	remove_custom_type("RayCastMultResult")
