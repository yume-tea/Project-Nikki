extends "res://scenes/Player/player_states/move/in_air/in_air.gd"


#Jump Variables
var jump_strength = 20

#Jump Flags
var has_jumped = false


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	if owner.get_node("AnimationTree").get("parameters/StateMachineLowerBody/playback").is_playing() == false:
		owner.get_node("AnimationTree").get("parameters/StateMachineLowerBody/playback").start("Jump")
	else:
		owner.get_node("AnimationTree").get("parameters/StateMachineLowerBody/playback").travel("Jump")
	.enter()
	snap_vector = Vector3(0,0,0)
	is_falling = false
	has_jumped = false
	connect_player_signals()


#Cleans up state, reinitializes values like timers
func exit():
	snap_vector = snap_vector_default
	disconnect_player_signals()


#Creates output based on the input event passed in
func handle_input(event):
	.handle_input(event)


#Acts as the _process method would
func update(delta):
	.update(delta)
	if owner.is_on_floor() and has_jumped:
		emit_signal("finished", "previous")
	elif !owner.is_on_floor() and velocity.y < 0:
		emit_signal("finished", "fall")


func on_animation_finished(_anim_name):
	return


func jump():
	print("called jump function")
	if owner.is_on_floor() and !is_falling:
		velocity.y = jump_strength
		has_jumped = true
