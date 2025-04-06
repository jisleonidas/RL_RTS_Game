extends Node2D

var box_size: Vector2 = Vector2(32, 40)  # Adjust to your sprite's size
var is_visible: bool = false

func _draw():
	if is_visible:
		draw_rect(Rect2(Vector2(-box_size.x/2-2, -box_size.y), box_size), Color(0, 1, 0), false, 2)

func show_box(size: Vector2):
	box_size = size
	is_visible = true
	queue_redraw()

func hide_box():
	is_visible = false
	queue_redraw()
