@tool
class_name RayCastMult3D extends Node

var _params: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
var _mesh_instance_debug: MeshInstance3D = MeshInstance3D.new()
var _cylinder_mesh_debug: CylinderMesh = CylinderMesh.new()
var _material_debug: StandardMaterial3D = StandardMaterial3D.new()


@export_subgroup("From")
## Source of the raycast. Example: a Marker3D or a Node3D. 
@export var from: Node3D:
	set(value):
		from = value
		update_configuration_warnings()
## Deviation from the raycast origin.
@export var from_offset: Vector3 = Vector3.ZERO
## Excludes the source node so it won't be detected.
@export var exclude_from: bool = true:
	set(value):
		exclude_from = value
		var new_excludes: Array[RID] = []
		for b in _excludes:
			if b:
				new_excludes.append(b.get_rid())
		if exclude_from and not from == null and from.has_method("get_rid"):
			new_excludes.append(from.get_rid())
		if exclude_to and not to == null and to.has_method("get_rid"):
			new_excludes.append(to.get_rid())
		_params.exclude = new_excludes

@export_subgroup("To")
## Raycast destination. Example: a Marker3D or a Node3D.
@export var to: Node3D:
	set(value):
		to = value
		update_configuration_warnings()
## Deviation from the raycast destination.
@export var to_offset: Vector3 = Vector3.ZERO
## Excludes the destination node so it cannot be detected.
@export var exclude_to: bool = true:
	set(value):
		exclude_to = value
		var new_excludes: Array[RID] = []
		for b in _excludes:
			if b:
				new_excludes.append(b.get_rid())
		if exclude_from and not from == null and from.has_method("get_rid"):
			new_excludes.append(from.get_rid())
		if exclude_to and not to == null and to.has_method("get_rid"):
			new_excludes.append(to.get_rid())
		_params.exclude = new_excludes

@export_subgroup("Params")
## Select this option if you want the raycast to detect 3D areas.
@export var collide_with_areas: bool = false:
	set(value):
		collide_with_areas = value
		if is_instance_valid(_params): _params.collide_with_areas = value
## Select this option if you want the raycast to detect 3D bodies.
@export var collide_with_bodies: bool = true:
	set(value):
		collide_with_bodies = value
		if is_instance_valid(_params): _params.collide_with_bodies = value
## Exibe no editor o raycast 3d.
@export var show_debug: bool = true
## The amount of raycast penetration, that is, how many detections you want to receive.
@export var max_result: int = 10
## Increase the Raycast tips.
@export_range(0.0, 10.0, 0.01) var offset: float = 0.0
## This is the margin that raycast considers when detecting 3D bodies and areas in space. For example, if one object is very close to another object, a smaller margin will detect both objects better.
@export_range(0.0001, 0.1, 0.0001) var margin: float = 0.001
## If true, the query will hit back faces with concave polygon shapes with back face enabled or heightmap shapes.
@export var hit_back_faces: bool = true:
	set(value):
		hit_back_faces = value
		if is_instance_valid(_params):
			_params.hit_back_faces = value
## If true, the query will detect a hit when starting inside shapes. In this case the collision normal will be Vector3(0, 0, 0). Does not affect concave polygon shapes or heightmap shapes.
@export var hit_from_inside: bool = false:
	set(value):
		hit_from_inside = value
		if is_instance_valid(_params):
			_params.hit_from_inside = value

@export_subgroup("Collision Mask")
## The physics layers the query will detect (as a bitmask). By default, all collision layers are detected. See Collision layers and masks   in the documentation for more information.
@export_flags_3d_physics var collision_mask = (1 << 0):
	set(value):
		collision_mask = value
		if is_instance_valid(_params): _params.collision_mask = value
	
@export_subgroup("Excludes")
## The list of object RIDs that will be excluded from collisions. Use CollisionObject3D.get_rid() to get the RID associated with a CollisionObject3D-derived node. Note: The returned array is copied and any changes to it will not update the original property value. To update the value you need to modify the returned array, and then assign it to the property again.
@export var _excludes: Array[PhysicsBody3D] = []:
	set(value):
		_excludes = value
		if is_instance_valid(_params):
			var new_excludes: Array[RID] = []
			for b in _excludes:
				if b:
					new_excludes.append(b.get_rid())
			if exclude_from and not from == null and from.has_method("get_rid"):
				new_excludes.append(from.get_rid())
			if exclude_to and not to == null and to.has_method("get_rid"):
				new_excludes.append(to.get_rid())
			_params.exclude = new_excludes


## Signal emitted by detected 3D bodies and areas.
signal intersect_ray(results: Array[RaycastMultResult])


func _get_configuration_warnings() -> PackedStringArray:
	var warnings = []
	if from == null:
		warnings.append("Please select a Node3D for the from parameter.")
	if to == null:
		warnings.append("Please select a Node3D for the parameter to.")
	if not to == null and to == from:
		warnings.append("The properties from and to cannot have the same node.")
	return warnings


func _ready() -> void:
	if not get_parent() is Node3D:
		push_warning("RayCastMult3D tem que ser inserido em um nó 3D somente")
	_init_var()
	_create_debug()
	
	
func _physics_process(_delta: float) -> void:
	_update_from()
	_update_to()
	_update_raycast()
	_update_mesh_visible()
	_update_debug()
	

func _update_raycast() -> void:
	if Engine.is_editor_hint():
		return
	if from == null or to == null:
		return
	if not get_parent() is Node3D:
		return
	if from == to:
		return
		
	var space_state = get_parent().get_world_3d().direct_space_state
	var results: Array[RaycastMultResult] = []
	var start = _params.from + from_offset
	var end = _params.to + to_offset
	var exclude_list: Array = _params.exclude.duplicate()
	var max_hits = max_result

	var dir = start.direction_to(end)
	var extended_start = start - dir * offset
	var extended_end = end + dir * offset

	for i in range(max_hits):
		var query := PhysicsRayQueryParameters3D.new()
		query.from = extended_start
		query.to = extended_end
		query.collision_mask = collision_mask
		query.collide_with_areas = collide_with_areas
		query.collide_with_bodies = collide_with_bodies
		query.exclude = exclude_list
		
		var result = space_state.intersect_ray(query)
		if result.is_empty():
			break
			
		var hit_pos: Vector3 = result.position
		var hit_normal: Vector3 = result.normal
		var collider = result.collider
		
		var raycast_result: RaycastMultResult = RaycastMultResult.new(
			result.collider,
			result.collider_id,
			hit_normal,
			hit_pos,
			result.face_index,
			result.rid,
			result.shape
		)
		results.append(raycast_result)
		
		if collider:
			exclude_list.append(collider.get_rid())
		
		start = hit_pos + dir * margin
	
	if results.size() > 0:
		intersect_ray.emit(results)


func _update_debug() -> void:
	if from == null or to == null:
		return
	if from == to:
		return

	var start = _params.from + from_offset
	var end = _params.to + to_offset

	var dir = start.direction_to(end)
	var expanded_start = start - dir * offset
	var expanded_end = end + dir * offset

	var middle = (expanded_start + expanded_end) / 2.0
	var dist = expanded_start.distance_to(expanded_end)

	_mesh_instance_debug.global_position = middle
	_mesh_instance_debug.look_at(expanded_end, Vector3.UP)
	_mesh_instance_debug.rotation_degrees.x += 90
	_mesh_instance_debug.scale = Vector3(0.1, dist / 2.0, 0.1)


func _create_debug() -> void:
	_material_debug.albedo_color.r = 1
	_material_debug.albedo_color.g = 0
	_material_debug.albedo_color.b = 0
	_material_debug.albedo_color.a = 0.5
	_material_debug.transparency = StandardMaterial3D.TRANSPARENCY_DISABLED

	_cylinder_mesh_debug.bottom_radius = 0.1
	_cylinder_mesh_debug.top_radius = 0.1
	_cylinder_mesh_debug.height = 2.0
	_cylinder_mesh_debug.surface_set_material(0, _material_debug)
	_cylinder_mesh_debug.radial_segments = 64
	_cylinder_mesh_debug.rings = 4

	_mesh_instance_debug.mesh = _cylinder_mesh_debug
	_mesh_instance_debug.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	add_child(_mesh_instance_debug)
	

func _init_var() -> void:
	var new_excludes: Array[RID] = []
	for b in _excludes:
		if b:
			new_excludes.append(b.get_rid())
	if exclude_from and not from == null and from.has_method("get_rid"):
		new_excludes.append(from.get_rid())
	if exclude_to and not to == null and to.has_method("get_rid"):
		new_excludes.append(to.get_rid())
	_params.exclude = new_excludes
	
	_params.collision_mask = collision_mask
	_params.collide_with_areas = collide_with_areas
	_params.collide_with_bodies = collide_with_bodies
	_params.hit_back_faces = hit_back_faces
	_params.hit_from_inside = hit_from_inside
	
	if not from or not to:
		return
		
	_params.from = from.global_position + from_offset
	_params.to = to.global_position + to_offset


func _update_from() -> void:
	if is_instance_valid(_params) and from and from.is_inside_tree():
		_params.from = from.global_position
	
			
func _update_to() -> void:
	if is_instance_valid(_params) and to and to.is_inside_tree():
		_params.to = to.global_position


func _update_mesh_visible() -> void:
	if from == null or to == null or from == to or show_debug == false:
		_mesh_instance_debug.visible = false
	else:
		_mesh_instance_debug.visible = true
		
## Add an area or a 3D body to be excluded from raycast detections.			
func add_exclude(_exclude: PhysicsBody3D) -> void:
	if _exclude == null:
		return
	
	if _excludes.has(_exclude):
		return
	
	_excludes.append(_exclude)

	if is_instance_valid(_params):
		var new_excludes: Array[RID] = []
		for b in _excludes:
			if b:
				new_excludes.append(b.get_rid())
		if exclude_from and not from == null and from.has_method("get_rid"):
			new_excludes.append(from.get_rid())
		if exclude_to and not to == null and to.has_method("get_rid"):
			new_excludes.append(to.get_rid())
		_params.exclude = new_excludes

## Removes an area or a 3D body so that it is not excluded from raycast detections.	
func remove_exclude(_exclude: PhysicsBody3D) -> void:
	if _excludes.has(_exclude):
		_excludes.erase(_exclude)
	
	if is_instance_valid(_params):
		var new_excludes: Array[RID] = []
		for b in _excludes:
			if b:
				new_excludes.append(b.get_rid())
		if exclude_from and not from == null and from.has_method("get_rid"):
			new_excludes.append(from.get_rid())
		if exclude_to and not to == null and to.has_method("get_rid"):
			new_excludes.append(to.get_rid())
		_params.exclude = new_excludes
