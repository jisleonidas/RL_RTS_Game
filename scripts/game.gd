extends Node2D

@onready var swordsman_scene = preload("res://scenes/swordsman.tscn")

var selected_unit: Node = null
var show_all_movement: bool = false

var unit_spawn_count: int = 0

func _draw():
	if selected_unit and not selected_unit.state == "attack":
		draw_movement(selected_unit)
		#draw_dashed_line(selected_unit.global_position, selected_unit.target_position, Color.GOLD, 0.5, 4, true, true)
		#if selected_unit.friendly:
			#draw_circle(selected_unit.target_position, 4, Color.GREEN, false, 1)
		#else:
			#draw_circle(selected_unit.target_position, 4, Color.RED)
	if show_all_movement:
		for i in get_children():
			if i.is_in_group("units") and i.friendly:
				draw_movement(i)

func draw_movement(unit: CharacterBody2D) -> void:
	draw_dashed_line(unit.global_position, unit.target_position, Color.GOLD, 0.5, 4, true, true)
	if unit.state == "chase":
		draw_circle(unit.target_position, 4, Color.RED, false, 1)
	else:
		draw_circle(unit.target_position, 4, Color.GREEN, false, 1)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("click"):
		var click_pos = get_global_mouse_position()
		
		var params = PhysicsPointQueryParameters2D.new()
		params.position = click_pos
		params.collide_with_areas = true
		params.collide_with_bodies = false
		params.collision_mask = 1

		var space_state = get_world_2d().direct_space_state
		var result = space_state.intersect_point(params, 32)
		
		var clicked_unit = null
		for item in result:
			var collider = item.collider.get_parent()
			if collider.is_in_group("units"):
				clicked_unit = collider
				break
		
		if clicked_unit:
			if clicked_unit.friendly:
				if selected_unit:
					selected_unit.deselect_unit()
				clicked_unit.select_unit()
				selected_unit = clicked_unit
			else:
				if selected_unit and selected_unit.friendly:
					selected_unit.attack(clicked_unit)
		elif selected_unit and selected_unit.friendly:
			selected_unit.move_to(click_pos)
		
		print("selected unit: ", selected_unit)
	elif event.is_action_pressed("unfocus"):
		if selected_unit:
			selected_unit.deselect_unit()
			selected_unit = null
	elif event.is_action_pressed("space"):
		show_all_movement = not show_all_movement
		

# Called when the node enters the scene tree for the first time.
func _ready() -> void:


	selected_unit = null
	for i in range(5):
		var unit = swordsman_scene.instantiate()
		unit.friendly = true
		unit.ai = true
		unit.position = Vector2(250, 175+i*50)
		unit.id = unit_spawn_count
		add_child(unit)
		unit_spawn_count += 1
	for i in range(5):
		var unit = swordsman_scene.instantiate()
		unit.friendly = false
		unit.ai = true
		unit.get_node("AnimatedSprite2D").flip_h = true
		unit.get_node("MoraleBar").position.x = -unit.get_node("MoraleBar").position.x
		unit.position = Vector2(750, 175+i*50)
		unit.id = unit_spawn_count
		add_child(unit)
		unit_spawn_count += 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#socket.poll()
#
	#var socket_state = socket.get_ready_state()
#
	#if socket_state == WebSocketPeer.STATE_OPEN:
		#while socket.get_available_packet_count():
			#var data_string = socket.get_packet().get_string_from_utf8()
			#print("Got data from server: ", data_string)
			#var json = JSON.new()
			#var error = json.parse(data_string)
			#if error == OK:
				#var data = json.data


	#elif socket_state == WebSocketPeer.STATE_CLOSING:
		#pass
#
	## WebSocketPeer.STATE_CLOSED means the connection has fully closed.
	## It is now safe to stop polling.
	#elif socket_state == WebSocketPeer.STATE_CLOSED:
		## The code will be -1 if the disconnection was not properly notified by the remote peer.
		#var code = socket.get_close_code()
		#print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
		#set_process(false) # Stop processing.
	#var list = []
	#for i in get_children():
		#if i.is_in_group("units"):
			#list.append[i]
	#for i in get_children():
		#i.call_ai(list)
	queue_redraw()
