extends "res://scenes/Player/player_states/move/in_air/in_air.gd"


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	connect_player_signals()
	
	if owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback").is_playing() == false:
		owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback").start("Fall")
	else:
		owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback").travel("Fall")
	.enter()


#Cleans up state, reinitializes values like timers
func exit():
	disconnect_player_signals()


#Creates output based on the input event passed in
func handle_input(event):
	.handle_input(event)


#Acts as the _process method would
func update(delta):
	calculate_aerial_velocity(delta)
	.update(delta)
	
	if owner.is_on_floor():
		emit_signal("finished", "previous")


func on_animation_finished(_anim_name):
	return

