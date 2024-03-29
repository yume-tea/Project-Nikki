extends "res://scripts/State Machine/states/state.gd"


"	-Find a better method to connect to signals from current level"
"   -Jump inputs are still not handled"


#Interaction Signals
signal input_move_direction_changed(input_direction)
signal lock_target

###Node Storage
###Node Storage
onready var world = get_tree().current_scene
onready var Enemy = owner
onready var Camera_Rig = owner.get_node("Camera_Rig")
onready var head = owner.get_node("Camera_Rig/Pivot/Cam_Position") #should get camera position a different way
onready var Pivot = owner.get_node("Camera_Rig/Pivot")
onready var Rig = owner.get_node("Rig")
onready var Enemy_Collision = owner.get_node("CollisionShape")
onready var Raycast_Floor = owner.get_node("Rig/Raycast_Floor")
onready var animation_state_machine_move = owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback")

#AI Input Storage
var input = {}

#Enemy State Storage
onready var state_ai = owner.get_node("State_Machine_AI").START_STATE
onready var state_move = owner.get_node("State_Machine_Move").START_STATE
onready var state_action = owner.get_node("State_Machine_Action").START_STATE
var ground_states = [
	"Walk",
]
var air_states = [
	"Jump",
	"Fall"
]
var swim_states = [
	"Swim"
]
var strafe_locked_states = [
	"Bow",
	"Throw_Item",
]
var rig_locked_states = [
	"Ledge_Hang"
]

#Tween Objects Storage
var active_tweens = []

###Enemy Variables
onready var enemy_height = owner.get_node("CollisionShape").shape.height

#Equipment Storage
var equipped_items = null
var equipped_weapon = null
var equipped_bow = null
var equipped_magic = null
var equipped_item = null

#View Variables
var facing_direction = Vector3()
var facing_angle = Vector2() #Goes from -pi > 0 > pi
var focus_direction = Vector3()
var focus_angle_global = Vector2()
var camera_direction = Vector3()
var camera_angle_global = Vector2()

##Move Constants
const speed_default = 18
const speed_bow_walk = 7
const speed_aerial = 3
const speed_swim = 8

const surface_speed = 4
const surface_accel = 48

const ACCEL = 4
const DEACCEL = 10

const turn_radius = 5 #in degrees
const quick_turn_radius = 12 #in degrees
const uturn_radius = 2 	#in degrees

#Move variables
var speed = speed_default

#Targetting variables
var focus_object = null

#Enemy Flags
var targetting = false


#func handle_input(event):
#	if event.is_action_pressed("print_to_console") and event.get_device() == 0:
#		print(input["input_previous"])


func handle_ai_input():
	return


#Acts as the _process method would
func update(_delta):
	return


func _on_animation_finished(_anim_name):
	return

func bound_angle(angle):
	#Angle > 180
	if (angle > deg2rad(180)):
		angle = angle - deg2rad(360)
	#Angle < -180
	if (angle < deg2rad(-180)):
		angle = angle + deg2rad(360)
	
	return angle


func get_node_direction(node):
	var direction = Vector3(0,0,1)
	var rotate_by = node.get_global_transform().basis.get_euler()
	direction = direction.rotated(Vector3(1,0,0), rotate_by.x)
	direction = direction.rotated(Vector3(0,1,0), rotate_by.y)
	direction = direction.rotated(Vector3(0,0,1), rotate_by.z)
	
	return direction


func get_transform_direction(transform):
	var direction = Vector3(0,0,1)
	var rotate_by = transform.basis.get_euler()
	direction = direction.rotated(Vector3(1,0,0), rotate_by.x)
	direction = direction.rotated(Vector3(0,1,0), rotate_by.y)
	direction = direction.rotated(Vector3(0,0,1), rotate_by.z)
	
	return direction


func calculate_local_x_rotation(direction):
	var test_direction = Vector3(direction.x, 0, direction.z)
	var x_rotation
	
	if direction.y < 0:
		x_rotation = test_direction.angle_to(direction)
	else:
		x_rotation = -test_direction.angle_to(direction)
	
	return x_rotation


func calculate_global_y_rotation(direction):
	var test_direction = Vector2(0,1)
	var direction_to = Vector2(direction.x, direction.z)
	var y_rotation = -test_direction.angle_to(direction_to)
	return y_rotation #Output is PI > y > -PI


func align_up(node_basis, normal):
	var result = Basis()

	result.x = normal.cross(node_basis.z)
	result.y = normal
	result.z = node_basis.x.cross(normal)

	result = result.orthonormalized()

	return result


#Returns collision data if raycast touches something
func raycast_query(from, to, exclude):
	var space_state = owner.get_world().direct_space_state
	var result = space_state.intersect_ray(from, to, [self, exclude])
	return result


func add_active_tween(property_string):
	if !active_tweens.has(property_string):
		active_tweens.append(property_string)


func remove_active_tween(property_string):
	if active_tweens.has(property_string):
		active_tweens.remove(active_tweens.find(property_string))


func press_ai_input(input_name, value):
	input["input_current"][input_name] = value


func is_ai_action_pressed(action, input_dic):
	for input_name in input_dic["input_current"]:
		if typeof(input_dic["input_current"][input_name]) == typeof(action):
			if input_dic["input_current"][input_name] == action:
					return true
	
	return false


func is_ai_action_released(action, input_dic):
	for input_name in input_dic["input_previous"]:
		if typeof(input_dic["input_previous"][input_name]) == typeof(action):
			if input_dic["input_previous"][input_name] == action:
				if input["input_previous"][input_name] != input["input_current"][input_name]:
					return true
	
	return false


#Returns true if action is in input_current but not in input_previous
func is_ai_action_just_pressed(action, input_dic):
	for input_name in input_dic["input_current"]:
		if typeof(input_dic["input_current"][input_name]) == typeof(action):
			if input["input_current"][input_name] == action:
				if input["input_current"][input_name] != input["input_previous"][input_name]:
					return true
				else:
					return false
	
	return false

