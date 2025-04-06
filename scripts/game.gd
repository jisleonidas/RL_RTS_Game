extends Node2D

@onready var swordsman_scene = preload("res://scenes/swordsman.tscn")

var selected_unit: Node = null
var show_all_movement: bool = false


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
		unit.position = Vector2(250, 150+i*50)
		add_child(unit)
	for i in range(5):
		var unit = swordsman_scene.instantiate()
		unit.friendly = false
		unit.get_node("AnimatedSprite2D").flip_h = true
		unit.get_node("MoraleBar").position.x = -unit.get_node("MoraleBar").position.x
		unit.position = Vector2(750, 150+i*50)
		add_child(unit)

class Agent:
	var type: String
	var health: int
	var position: Vector2
	
	func _init(_type: String, _health: int, _position: Vector2):
		type = _type
		health = _health
		position = _position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var state = []
	for i in get_children():
		if i.is_in_group("units"):
			var agent = Agent.new(i.type, i.health, i.global_position)
			state.append(agent)
	#var list = []
	#for i in get_children():
		#if i.is_in_group("units"):
			#list.append[i]
	#for i in get_children():
		#i.call_ai(list)
	queue_redraw()
