extends "res://scenes/Player/player_states/action/action.gd"

"""
replace _on_Player_equipped_items_changed with dictionaries for left/right hand in inventory_resource
"""



onready var skeleton = owner.get_node("Rig/Skeleton")
onready var left_bicep = skeleton.find_bone("bicep_l")


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	connect_player_signals()
	.enter()

#Cleans up state, reinitializes values like timers
func exit():
	owner.get_node("AnimationTree").set("parameters/MovexLeftArm/blend_amount", 0.0)
	disconnect_player_signals()
	.exit()


#Creates output based on the input event passed in
func handle_input(event):
	#Check for inputs that enter new states first
	#Ground only actions
	if state_move in ground_states:
		if event.is_action_pressed("cast") and event.get_device() == 0:
			emit_signal("finished", "cast")
		if Input.is_action_pressed("draw_bow") and event.get_device() == 0:
			if equipped_bow != null:
				emit_signal("finished", "bow")
	
	if !(state_move in ["Ledge_Hang", "Ledge_Climb", "Swim", "Dive"]):
		if event.is_action_pressed("use_item") and event.get_device() == 0:
			if equipped_items["Item"] != null:
				emit_signal("finished", "throw_item")
	
	if event.is_action_pressed("bow_next") and event.get_device() == 0:
		owner.inventory.next_item("Bow")
		equipped_items = owner.inventory.equipped_items
		cycle_equipment()
	
	#Switching Arrows
	if event.is_action_pressed("arrow_next") and event.get_device() == 0:
		owner.inventory.next_item("Arrow")
		equipped_items = owner.inventory.equipped_items
	if event.is_action_pressed("arrow_previous") and event.get_device() == 0:
		owner.inventory.previous_item("Arrow")
		equipped_items = owner.inventory.equipped_items
	
	#Switching Items
	if event.is_action_pressed("item_next") and event.get_device() == 0:
		owner.inventory.next_item("Item")
		equipped_items = owner.inventory.equipped_items
	if event.is_action_pressed("item_previous") and event.get_device() == 0:
		owner.inventory.previous_item("Item")
		equipped_items = owner.inventory.equipped_items
	
	
	
	.handle_input(event)


#Acts as the _process method would
func update(delta):
	if state_move in ground_states:
		if Input.is_action_pressed("draw_bow"):
				if equipped_bow != null:
					emit_signal("finished", "bow")
	
	#Change left arm anim to match held item
	set_left_arm_anim()
	
	.update(delta)


func on_animation_started(_anim_name):
	return


func on_animation_finished(_anim_name):
	return


func set_left_arm_anim():
	if equipped_bow and ((state_move in ground_states) or (state_move in air_states) or (state_move in swim_states)):
		if !owner.get_node("AnimationTree").get("parameters/StateMachineLeftArm/playback").is_playing():
			owner.get_node("AnimationTree").get("parameters/StateMachineLeftArm/playback").start("Bow_Hold")
		owner.get_node("AnimationTree").set("parameters/MovexLeftArm/blend_amount", 1.0)
	else:
		owner.get_node("AnimationTree").set("parameters/MovexLeftArm/blend_amount", 0.0)






