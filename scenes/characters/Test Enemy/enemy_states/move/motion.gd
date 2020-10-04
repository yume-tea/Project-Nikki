extends "res://scenes/characters/Test Enemy/enemy_states/interaction/interaction.gd"


"""
Input is currently full hold
"""


#Variable Signals
signal position_changed(current_position)
signal velocity_changed(current_velocity)
signal facing_angle_changed(facing_angle)
#Flag Signals
signal started_falling(fall_height)
signal landed(landing_height)
signal center_view(turn_angle)

###Node Storage
onready var world = get_tree().current_scene
onready var Enemy = owner
onready var head = owner.get_node("Camera_Rig/Pivot/Cam_Position") #should get camera position a different way
onready var Pivot = owner.get_node("Camera_Rig/Pivot")
onready var Rig = owner.get_node("Rig")
onready var Enemy_Collision = owner.get_node("CollisionShape")
onready var Raycast_Floor = owner.get_node("Rig/Raycast_Floor")
onready var animation_state_machine_move = owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback")

#Animation Blending Variables
var move_blend_position : float

#Initialized Values Storage
var initialized_values = {}

#World Interaction Variables
var fall_height : float
var land_height : float

#Environment Variables
var ledge_height : float
var ledge_hang_height : float
var surface_height : float
var surfaced_height : float

###Physics Variables
var position : Vector3
var height : float
var direction = Vector3(0,0,0)
var direction_angle = Vector2(0,0)
var velocity = Vector3(0,0,0)
var velocity_horizontal : float
var acceleration_horizontal : float
const gravity = -9.8
const weight = 5

#Input Variables
var left_joystick_axis = Vector2(0,0)
var right_joystick_axis = Vector2(0,0)
var joystick_inner_deadzone = 0.01
var joystick_outer_deadzone = 0.9
var left_joystick_sensitivity = 1.0 #####CONSIDER SETTING THIS A DIFFERENT, GLOBAL WAY
var right_joystick_sensitivity = 1.0

##Ground Snap Variables
const snap_vector_default = Vector3(0,-1,0)
var snap_vector = snap_vector_default #Used for Move_and_slide_with_snap

#Centering Variables
const centering_time = 12 #in frames
var centering_time_left = 0
var turn_angle = Vector2()
var focus_angle_lim = Vector2(deg2rad(57.5), deg2rad(82))

#Enemy Flags
var strafe_locked = false
var can_void = true
var is_moving = false
var is_falling = false
var in_water = false

var centering_view = false
var centered = false
var rotate_to_focus : bool

#Walking Flags
var quick_turn = true


func enter():
	.enter()


func exit():
	.exit()


#Creates output based on the input event passed in
func handle_input(event):
	.handle_input(event)


func handle_ai_input():
	get_move_direction(input)
	get_look_direction(input)
	
	if is_ai_action_pressed("center_view", input):
		centering_view = true
		if is_ai_action_pressed("center_view", input):
			reset_recenter()
	else: #checks all input to see if released, not just event
		centered = false
		centering_view = false
	
	.handle_input(input)


#Acts as the _process method would
func update(delta):
	###Gravity
	velocity.y += weight * gravity * delta
	velocity = owner.move_and_slide_with_snap(velocity, snap_vector, Vector3(0,1,0), true, 1, deg2rad(65), false) #Come back/check vars 3,4,5
	position = owner.get_global_transform().origin
	height = position.y
	emit_signal("position_changed", position)
	emit_signal("velocity_changed", velocity)
	.update(delta)


func _on_animation_finished(_anim_name):
	return


#Returns direction relative to camera view angle
func get_input_direction():
	direction = Vector3() #Resets direction of player to default
	
	###Camera Direction
	var aim = head.get_global_transform().basis.get_euler()
	
	###Directional Input
	direction.z += left_joystick_axis.y
	direction.x += left_joystick_axis.x
	
	direction = direction.rotated(Vector3(0,1,0), (aim.y + PI))
	
	direction.y = 0
	
	var direction_length = (direction.length())
	if direction_length > 1.0:
		direction_length = 1.0
	
	var direction_normalized = direction.normalized()
	direction = direction_normalized * direction_length
	
	emit_signal("input_move_direction_changed", direction)
	
	return direction


func get_move_direction(input):
	if input["input_current"]["left_stick"] != null:
		left_joystick_axis = input["input_current"]["left_stick"]


func get_look_direction(input):
	if input["input_current"]["right_stick"] != null:
		right_joystick_axis = input["input_current"]["right_stick"]


func calculate_movement_velocity(delta):
	###Velocity Calculation
	var temp_velocity = velocity
	temp_velocity.y = 0.0
	
	###Target Velocity
	var target_velocity = direction * speed
	#Speed Cap
	if abs(target_velocity.length()) > speed_default:
		target_velocity = target_velocity.normalized() * speed_default
	
	###Determine the type of acceleration
	var acceleration
	if direction.dot(temp_velocity) > 0 or temp_velocity == Vector3(0,0,0):
		acceleration = ACCEL
	else:
		acceleration = DEACCEL
	
	#Calculate a portion of the distance to go
	temp_velocity = temp_velocity.linear_interpolate(target_velocity, acceleration * delta)
	
	###Final Velocity
	if temp_velocity.length() > 0.01:
		velocity.x = temp_velocity.x
		velocity.z = temp_velocity.z
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	
	velocity.y += weight * gravity * delta


func calculate_aerial_velocity(delta):
	###Velocity Calculation
	var temp_velocity = velocity
	temp_velocity.y = 0.0
	
	###Target Velocity
	var target_velocity = temp_velocity + (direction * speed_aerial)
	#Speed Cap
	if abs(target_velocity.length()) > speed_default:
		target_velocity = target_velocity.normalized() * speed_default
	
	###Determine the type of acceleration
	var acceleration
	acceleration = ACCEL
	
	#Calculate a portion of the distance to go
	temp_velocity = temp_velocity.linear_interpolate(target_velocity, acceleration * delta)
	
	###Final Velocity
	if temp_velocity.length() > 0.01:
		velocity.x = temp_velocity.x
		velocity.z = temp_velocity.z
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	
	velocity.y += weight * gravity * delta


func calculate_ledge_velocity(delta):
	###Velocity Calculation
	var temp_velocity = velocity
	temp_velocity.y = 0

	###Target Velocity
	var target_velocity = direction * speed
	#Speed Cap
	if abs(target_velocity.length()) > speed_default:
		target_velocity = target_velocity.normalized() * speed_default

	###Determine the type of acceleration
	var acceleration
	if direction.dot(temp_velocity) > 0 or temp_velocity == Vector3(0,0,0):
		acceleration = ACCEL
	else:
		acceleration = DEACCEL

	#Calculate a portion of the distance to go
	temp_velocity = temp_velocity.linear_interpolate(target_velocity, acceleration * delta)

	###Final Velocity
	if temp_velocity.length() <= 0.01:
		temp_velocity.x = 0.0
		temp_velocity.z = 0.0
		
	return temp_velocity


func calculate_swim_velocity(delta):
	var temp_velocity = velocity
	temp_velocity.y = 0
	
	###Target Velocity
	var target_velocity = direction * speed_swim
	#Speed Cap
	if abs(target_velocity.length()) > speed_default:
		target_velocity = target_velocity.normalized() * speed_default
	
	###Determine the type of acceleration
	var acceleration
	if direction.dot(temp_velocity) > 0 or temp_velocity == Vector3(0,0,0):
		acceleration = ACCEL
	else:
		acceleration = DEACCEL
	
	#Calculate a portion of the distance to go
	temp_velocity = temp_velocity.linear_interpolate(target_velocity, acceleration * delta)
	
	###Final Velocity
	if temp_velocity.length() > 0.01:
		velocity.x = temp_velocity.x
		velocity.z = temp_velocity.z
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	
	if Enemy.global_transform.origin.y < surfaced_height:
		velocity.y += surface_accel * delta
		if velocity.y > surface_speed:
			velocity.y = surface_speed
	else:
		Enemy.global_transform.origin.y = surfaced_height


#Returns true if ground snap vector is touching something
func snap_vector_is_colliding():
	var from_point = Enemy_Collision.global_transform.origin
	from_point.y -= Enemy_Collision.transform.origin.y
	
	var to_point = from_point + snap_vector
	
	var obstruction = raycast_query(from_point, to_point, self)
	if obstruction.empty():
		return false
	else:
		return true


func reset_recenter():
	centered = false
	centering_time_left = centering_time


func set_initialized_values(init_values_dic):
	for value in init_values_dic:
		init_values_dic[value] = self[value]


#####EXTERNAL INPUT FUNCTIONS#####
func connect_enemy_signals():
	#Enemy Signals
	owner.connect("ai_input_changed", self, "_on_Enemy_ai_input_changed")
	owner.get_node("AnimationTree").connect("animation_started", self, "on_animation_started")
	owner.get_node("AnimationTree").connect("animation_finished", self, "on_animation_finished")
	owner.connect("focus_target", self, "_on_Enemy_focus_target_changed")
	owner.get_node("State_Machine_Move").connect("initialized_values_dic_set", self, "_on_State_Machine_Move_initialized_values_dic_set")
	owner.get_node("State_Machine_Move").connect("move_state_changed", self, "_on_State_Machine_Move_state_changed")
	owner.get_node("State_Machine_Action").connect("action_state_changed", self, "_on_State_Machine_Action_state_changed")
	owner.get_node("Camera_Rig").connect("focus_direction_changed", self, "_on_Camera_Rig_focus_direction_changed")
	owner.get_node("Camera_Rig").connect("view_locked", self, "_on_Camera_Rig_view_locked")
	owner.get_node("Attributes/Health").connect("health_depleted", self, "_on_Enemy_death")
	
#	#World Signals
#	owner.connect("entered_area", self, "_on_environment_area_entered")
#	owner.connect("exited_area", self, "_on_environment_area_exited")


func disconnect_enemy_signals():
	#Enemy Signals
	owner.disconnect("ai_input_changed", self, "_on_Enemy_ai_input_changed")
	owner.get_node("AnimationTree").disconnect("animation_started", self, "on_animation_started")
	owner.get_node("AnimationTree").disconnect("animation_finished", self, "on_animation_finished")
	owner.disconnect("focus_target", self, "_on_Enemy_focus_target_changed")
	owner.get_node("State_Machine_Move").disconnect("initialized_values_dic_set", self, "_on_State_Machine_Move_initialized_values_dic_set")
	owner.get_node("State_Machine_Move").disconnect("move_state_changed", self, "_on_State_Machine_Move_state_changed")
	owner.get_node("State_Machine_Action").disconnect("action_state_changed", self, "_on_State_Machine_Action_state_changed")
	owner.get_node("Camera_Rig").disconnect("focus_direction_changed", self, "_on_Camera_Rig_focus_direction_changed")
	owner.get_node("Camera_Rig").disconnect("view_locked", self, "_on_Camera_Rig_view_locked")
	owner.get_node("Attributes/Health").disconnect("health_depleted", self, "_on_Enemy_death")
	
#	#World Signals
#	owner.disconnect("entered_area", self, "_on_environment_area_entered")
#	owner.disconnect("exited_area", self, "_on_environment_area_exited")


###Enemy SIGNAL FUNCTIONS###


func _on_Enemy_ai_input_changed(input_dict):
	input = input_dict


func _on_Enemy_focus_target_changed(target_pos_node):
	focus_object = target_pos_node


func _on_State_Machine_Move_initialized_values_dic_set(init_values_dic):
	initialized_values = init_values_dic


func _on_State_Machine_Move_state_changed(move_state):
	state_move = move_state


func _on_State_Machine_Action_state_changed(action_state):
	#Before changing state
	if state_action in strafe_locked_states:
		strafe_locked = false
		is_moving = false
		quick_turn = true
	
	#Store new action state
	state_action = action_state
	
	#After changing state
	if action_state == "None":
		#Removes walk blend tween as active so tween is only started once in walk.gd
		remove_active_tween("parameters/StateMachineMove/Walk/BlendSpace1D/blend_position")
	
	if action_state in strafe_locked_states:
		strafe_locked = true
		#Change walk speed if in certain action states
		if action_state in ["Bow"]:
			speed = speed_bow_walk
		
		#Remove Lower Body active tween so it starts once on entering bow state
		remove_active_tween("parameters/StateMachineMove/Walk/BlendSpace1D/blend_position")


func _on_Camera_Rig_focus_direction_changed(dir):
	camera_direction = dir


func _on_Camera_Rig_view_locked(is_view_locked, _time_left):
	if !strafe_locked:
		centering_view = is_view_locked
		strafe_locked = is_view_locked
		centered = false
	elif !(state_action in strafe_locked_states): #only turn off strafe locked if outside a strafe locked state
		centering_view = is_view_locked
		strafe_locked = is_view_locked


func _on_death(death):
	if death:
		emit_signal("finished", "death")


###WORLD SIGNAL FUNCTIONS###

func _on_environment_area_entered(area_type, surface_h):
	if area_type == "Water":
		in_water = true
		surface_height = surface_h
		surfaced_height = surface_height - enemy_height


func _on_environment_area_exited(area_type):
	if area_type == "Water":
		in_water = false



