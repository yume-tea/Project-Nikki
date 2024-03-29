extends "res://scenes/Player/player_states/move/motion.gd"


func enter():
	.enter()


func exit():
	.exit()


#Creates output based on the input event passed in
func handle_input(event):
	if event.is_action_pressed("jump")  and event.get_device() == 0:
		if owner.is_on_floor():
			if state_action != "Bow":
				emit_signal("finished", "jump")
	
	.handle_input(event)


func update(delta):
	if in_water:
		if Player.global_transform.origin.y < (surface_height - player_height):
			emit_signal("finished", "swim")
	
	if !owner.is_on_floor() and !snap_vector_is_colliding() and !Raycast_Floor.is_colliding():
		emit_signal("finished", "fall")
	
	.update(delta)

